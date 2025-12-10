import 'dart:async';
import 'dart:collection';
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
  // Constants
  static const double _kaabaLatitude = 21.422487;
  static const double _kaabaLongitude = 39.826206;
  static const double _gravity = 9.81;

  // Kalman Filter Parameters
  double _filteredAzimuth = 0.0;
  static const double _processNoise = 0.05; // Tuned for smoothness
  static const double _measurementNoise = 3.0;
  double _errorCovariance = 1.0;

  // Sensor Fusion
  BehaviorSubject<AccelerometerEvent>? _accelSubject;
  BehaviorSubject<MagnetometerEvent>? _magSubject;
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  StreamSubscription<MagnetometerEvent>? _magnetometerSubscription;
  StreamSubscription<double>? _internalHeadingSubscription;
  StreamSubscription<double>? _headingSubscription;

  // State
  Position? _currentPosition;
  double _qiblaBearing = 0.0;
  final Queue<double> _recentHeadings = Queue();
  static const int _windowSize = 20;
  static const double _stdThreshold = 2.5; // Degrees for 'High' accuracy

  // Streams
  final _azimuthStreamController = StreamController<double>.broadcast();
  StreamSubscription<Position>? _positionSubscription;

  QiblaBloc() : super(const QiblaInitial()) {
    on<QiblaDirectionRequested>(_onQiblaDirectionRequested);
  }

  Future<void> _onQiblaDirectionRequested(
      QiblaDirectionRequested event,
      Emitter<QiblaState> emit,
      ) async {
    emit(const QiblaLoading());

    try {
      // Check sensors
      final accelStream = accelerometerEvents;
      final magStream = magnetometerEvents;
      if (accelStream == null || magStream == null) {
        emit(const QiblaSensorError('Device lacks required sensors (accelerometer or magnetometer).'));
        return;
      }

      // Handle permissions
      final hasPermission = await _requestLocationPermission();
      if (!hasPermission) {
        emit(const QiblaLocationPermissionDenied('Location permission required for Qibla direction.'));
        return;
      }

      // Get initial location
      final position = await _getCurrentPosition();
      if (position == null) {
        emit(const QiblaLocationServiceDisabled('Enable location services to proceed.'));
        return;
      }
      _currentPosition = position;
      _qiblaBearing = _calculateBearing(
        position.latitude,
        position.longitude,
        _kaabaLatitude,
        _kaabaLongitude,
      );

      // Start live position updates for dynamic bearing
      _startPositionStream();

      // Initialize sensor fusion for live heading
      await _initializeSensorFusion(accelStream, magStream);

      // Listen to filtered azimuth and emit updates
      _headingSubscription = _azimuthStreamController.stream
          .debounceTime(const Duration(milliseconds: 50)) // Responsive ~20 FPS
          .listen(
            (azimuth) {
          if (isClosed) return;
          final relative = _calculateRelative(azimuth);
          _updateRecentHeadings(azimuth);
          emit(QiblaLoadSuccess(
            relativeQiblaDirection: relative,
            currentHeading: azimuth,
            distanceToKaaba: Geolocator.distanceBetween(
              _currentPosition!.latitude,
              _currentPosition!.longitude,
              _kaabaLatitude,
              _kaabaLongitude,
            ),
            accuracyStatus: _getAccuracyStatus(),
          ));
        },
        onError: (error) => emit(QiblaSensorError('Sensor error: $error')),
      );
    } catch (e) {
      emit(QiblaSensorError('Failed to initialize Qibla: ${e.toString()}'));
    }
  }

  Future<bool> _requestLocationPermission() async {
    var status = await Permission.location.status;
    if (!status.isGranted) {
      status = await Permission.location.request();
    }
    return status.isGranted;
  }

  Future<Position?> _getCurrentPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
        timeLimit: const Duration(seconds: 8),
      );
    } catch (e) {
      return null;
    }
  }

  void _startPositionStream() {
    _positionSubscription?.cancel();
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 5, // Update if moved >5m
      ),
    ).listen(
          (position) {
        _currentPosition = position;
        _qiblaBearing = _calculateBearing(
          position.latitude,
          position.longitude,
          _kaabaLatitude,
          _kaabaLongitude,
        );
      },
      onError: (e) {
        // Silent fail, fallback to last known
      },
    );
  }

  Future<void> _initializeSensorFusion(
      Stream<AccelerometerEvent> accelStream,
      Stream<MagnetometerEvent> magStream,
      ) async {
    await _disposeSensors();

    _accelSubject = BehaviorSubject<AccelerometerEvent>();
    _magSubject = BehaviorSubject<MagnetometerEvent>();

    _accelerometerSubscription = accelStream.listen(
      _accelSubject!.add,
      onError: addError,
    );

    _magnetometerSubscription = magStream.listen(
      _magSubject!.add,
      onError: addError,
    );

    // Combine for tilt-compensated heading
    final headingStream = Rx.combineLatest2(
      _accelSubject!,
      _magSubject!,
      _computeTiltCompensatedHeading,
    );

    _internalHeadingSubscription = headingStream
        .where((heading) => !heading.isNaN && heading.isFinite && heading >= 0 && heading <= 360)
        .listen(
          (rawHeading) {
        _updateKalmanFilter(rawHeading);
        _azimuthStreamController.add(_filteredAzimuth);
      },
      onError: addError,
    );
  }

  static double _computeTiltCompensatedHeading(
      AccelerometerEvent accel,
      MagnetometerEvent mag,
      ) {
    // Normalize accel to unit gravity vector
    final ax = accel.x / _gravity;
    final ay = accel.y / _gravity;
    final az = accel.z / _gravity;
    final norm = math.sqrt(ax * ax + ay * ay + az * az);
    if (norm == 0) return 0.0;

    final nx = ax / norm;
    final ny = ay / norm;
    final nz = az / norm;

    // Pitch and roll
    final pitch = math.asin(-nx);
    final roll = math.atan2(ny, nz);

    // Rotate mag into horizontal plane
    final hx = mag.x * math.cos(pitch) + mag.z * math.sin(pitch);
    final hy = mag.x * math.sin(roll) * math.sin(pitch) +
        mag.y * math.cos(roll) -
        mag.z * math.cos(pitch) * math.sin(roll);

    // Heading
    var heading = math.atan2(hy, hx);
    heading = (heading * 180 / math.pi + 360) % 360;
    return heading;
  }

  void _updateKalmanFilter(double measurement) {
    _errorCovariance += _processNoise;
    final kalmanGain = _errorCovariance / (_errorCovariance + _measurementNoise);
    _filteredAzimuth += kalmanGain * (measurement - _filteredAzimuth);
    _errorCovariance *= (1 - kalmanGain);
    _filteredAzimuth = (_filteredAzimuth + 360) % 360;
  }

  void _updateRecentHeadings(double heading) {
    _recentHeadings.addLast(heading);
    if (_recentHeadings.length > _windowSize) {
      _recentHeadings.removeFirst();
    }
  }

  double _calculateRelative(double heading) {
    var relative = _qiblaBearing - heading;
    return (relative + 360) % 360;
  }

  String _getAccuracyStatus() {
    if (_recentHeadings.length < 10) return 'Calibrating...';
    final std = _stdDev(_recentHeadings);
    return std < _stdThreshold ? 'High' : 'Calibrating...';
  }

  static double _stdDev(Iterable<double> values) {
    if (values.length < 2) return double.infinity;
    final mean = values.fold(0.0, (a, b) => a + b) / values.length;
    final variance = values
        .map((v) => (v - mean) * (v - mean))
        .fold(0.0, (a, b) => a + b) /
        (values.length - 1);
    return math.sqrt(variance);
  }

  double _calculateBearing(double lat1, double lon1, double lat2, double lon2) {
    final dLon = _toRadians(lon2 - lon1);
    final y = math.sin(dLon) * math.cos(_toRadians(lat2));
    final x = math.cos(_toRadians(lat1)) * math.sin(_toRadians(lat2)) -
        math.sin(_toRadians(lat1)) * math.cos(_toRadians(lat2)) * math.cos(dLon);
    var bearing = math.atan2(y, x);
    bearing = (bearing * 180 / math.pi + 360) % 360;
    return bearing;
  }

  static double _toRadians(double degrees) => degrees * math.pi / 180;

  Future<void> _disposeSensors() async {
    await _accelerometerSubscription?.cancel();
    await _magnetometerSubscription?.cancel();
    await _internalHeadingSubscription?.cancel();
    await _headingSubscription?.cancel();
    await _positionSubscription?.cancel();
    await _accelSubject?.close();
    await _magSubject?.close();
    _accelerometerSubscription = null;
    _magnetometerSubscription = null;
    _internalHeadingSubscription = null;
    _headingSubscription = null;
    _positionSubscription = null;
    _accelSubject = null;
    _magSubject = null;
    _recentHeadings.clear();
  }

  @override
  Future<void> close() async {
    await _disposeSensors();
    await _azimuthStreamController.close();
    return super.close();
  }
}