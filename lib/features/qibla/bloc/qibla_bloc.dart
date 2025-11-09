import 'dart:async';
import 'dart:math' as math;
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rxdart/rxdart.dart';

import 'qibla_event.dart';
import 'qibla_state.dart';

class QiblaBloc extends Bloc<QiblaEvent, QiblaState> {
  // --- Constants ---
  static const double _kaabaLatitude = 21.422487;
  static const double _kaabaLongitude = 39.826206;

  // --- Sensor Fusion Variables (Kalman-inspired Filter) ---
  double _filteredAzimuth = 0.0;
  double _processNoise = 0.3;
  double _measurementNoise = 10.0;
  double _kalmanGain = 0.0;
  double _errorCovariance = 1.0;

  // --- Sensor Data ---
  double _currentAzimuth = 0.0;
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  StreamSubscription<MagnetometerEvent>? _magnetometerSubscription;

  // --- Location Variables ---
  Position? _currentPosition;
  double _qiblaBearing = 0.0;

  // --- Stream Controller & Subscription ---
  final _azimuthStreamController = StreamController<double>.broadcast();
  late StreamSubscription<double> _azimuthSubscription;

  QiblaBloc() : super(const QiblaInitial()) {
    on<QiblaDirectionRequested>(_onQiblaDirectionRequested);
  }

  Future<void> _onQiblaDirectionRequested(
      QiblaDirectionRequested event,
      Emitter<QiblaState> emit,
      ) async {
    emit(const QiblaLoading());
    try {
      // 1. Check for required sensors
      if (accelerometerEvents == null || magnetometerEvents == null) {
        emit(const QiblaSensorError('Your device does not have the required sensors.'));
        return;
      }

      // 2. Handle Permissions
      final permissionStatus = await _handlePermissions();
      if (!permissionStatus) {
        emit(const QiblaLocationPermissionDenied(
          'Location permission is required.',
        ));
        return;
      }

      // 3. Get Location
      _currentPosition = await _getCurrentLocation();
      if (_currentPosition == null) {
        emit(const QiblaLocationServiceDisabled(
          'Please enable location services.',
        ));
        return;
      }

      // 4. Calculate Qibla Bearing (static calculation)
      _qiblaBearing = _calculateBearing(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        _kaabaLatitude,
        _kaabaLongitude,
      );

      // 5. Start Sensor Fusion
      _startSensorFusion();

      // 6. Listen to debounced azimuth stream and emit success state
      _azimuthSubscription = _azimuthStreamController.stream
          .debounceTime(const Duration(milliseconds: 100))
          .listen((azimuth) {
        _currentAzimuth = azimuth;
        if (isClosed) return;
        emit(QiblaLoadSuccess(
          qiblaDirection: _calculateRelativeQiblaDirection(),
          distanceToKaaba: Geolocator.distanceBetween(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
            _kaabaLatitude,
            _kaabaLongitude,
          ),
          accuracyStatus: _getAccuracyStatus(),
        ));
      });
    } catch (e) {
      emit(QiblaSensorError('An unexpected error occurred: ${e.toString()}'));
    }
  }

  Future<bool> _handlePermissions() async {
    var status = await Permission.location.status;
    if (status.isDenied) {
      status = await Permission.location.request();
    }
    return status.isGranted;
  }

  Future<Position?> _getCurrentLocation() async {
    final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  void _startSensorFusion() {
    // --- Accelerometer ---
    _accelerometerSubscription = accelerometerEvents?.listen(
          (event) {},
      onError: (error) => addError(error),
    );

    // --- Magnetometer ---
    _magnetometerSubscription = magnetometerEvents?.listen(
          (MagnetometerEvent event) {
        // Get the raw azimuth from the magnetometer
        final azimuth = math.atan2(event.y, event.x);
        final degrees = (azimuth * 180 / math.pi + 360) % 360;

        // Apply the Kalman filter to smooth the data
        _updateKalmanFilter(degrees);
        _azimuthStreamController.add(_filteredAzimuth);
      },
      onError: (error) => addError(error),
    );
  }

  /// A simple Kalman-inspired filter for smoothing the azimuth.
  void _updateKalmanFilter(double measurement) {
    // Prediction
    _errorCovariance += _processNoise;

    // Update
    _kalmanGain = _errorCovariance / (_errorCovariance + _measurementNoise);
    _filteredAzimuth += _kalmanGain * (measurement - _filteredAzimuth);
    _errorCovariance *= (1 - _kalmanGain);

    // Normalize to 0-360
    _filteredAzimuth = (_filteredAzimuth + 360) % 360;
  }

  double _calculateRelativeQiblaDirection() {
    double relativeDirection = _qiblaBearing - _currentAzimuth;
    relativeDirection = (relativeDirection + 360) % 360;
    return relativeDirection;
  }

  String _getAccuracyStatus() {
    // Since we can't get direct accuracy, we infer it from sensor stability.
    // If the change is small, we assume high accuracy.
    if ((_currentAzimuth - _filteredAzimuth).abs() > 5) {
      return 'Calibrating...';
    }
    return 'High';
  }

  double _calculateBearing(double startLat, double startLon, double endLat, double endLon) {
    final double lat1 = startLat * math.pi / 180;
    final double lon1 = startLon * math.pi / 180;
    final double lat2 = endLat * math.pi / 180;
    final double lon2 = endLon * math.pi / 180;
    final double dLon = lon2 - lon1;

    final double y = math.sin(dLon) * math.cos(lat2);
    final double x = math.cos(lat1) * math.sin(lat2) - math.sin(lat1) * math.cos(lat2) * math.cos(dLon);

    double bearing = math.atan2(y, x);
    bearing = (bearing * 180 / math.pi + 360) % 360;
    return bearing;
  }

  @override
  Future<void> close() {
    _accelerometerSubscription?.cancel();
    _magnetometerSubscription?.cancel();
    _azimuthSubscription.cancel();
    _azimuthStreamController.close();
    return super.close();
  }
}