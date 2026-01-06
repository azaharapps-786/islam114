import 'dart:async';
import 'dart:math';
import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:vector_math/vector_math_64.dart' show Vector3;

class QiblaPage extends StatefulWidget {
  const QiblaPage({super.key});

  @override
  State<QiblaPage> createState() => _QiblaPageState();
}

class _QiblaPageState extends State<QiblaPage> {
  // --- State Variables ---
  bool _isFetchingLocation = true;
  Position? _userPosition;
  double _qiblaDirection = 0.0; // True Qibla bearing from North (0-360°)
  double _deviceAzimuth = 0.0; // Current device heading (0-360°)
  String _statusMessage = "Initializing...";

  // --- Sensor subscriptions ---
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  StreamSubscription<MagnetometerEvent>? _magnetometerSubscription;

  // --- Kaaba Coordinates ---
  static const double _kaabaLatitude = 21.422487;
  static const double _kaabaLongitude = 39.826206;

  // --- Variables to hold sensor data for fusion ---
  Vector3? _gravity;
  Vector3? _magnetic;

  @override
  void initState() {
    super.initState();
    _permissionsFuture = _requestAndCheckPermissions();
  }

  @override
  void dispose() {
    _accelerometerSubscription?.cancel();
    _magnetometerSubscription?.cancel();
    super.dispose();
  }

  late Future<bool> _permissionsFuture;

  Future<bool> _requestAndCheckPermissions() async {
    var locationStatus = await Permission.location.status;
    var sensorStatus = await Permission.sensors.status;

    if (locationStatus.isGranted && sensorStatus.isGranted) {
      return true;
    }

    Map<Permission, PermissionStatus> statuses = await [
      Permission.location,
      Permission.sensors,
    ].request();

    return statuses[Permission.location]?.isGranted ?? false &&
        statuses[Permission.sensors]!.isGranted ?? false;
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() {
            _statusMessage = "Location services are disabled.";
            _isFetchingLocation = false;
          });
        }
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 20),
      );

      if (mounted) {
        setState(() {
          _userPosition = position;
          _isFetchingLocation = false;
          _qiblaDirection =
              _calculateQiblaBearing(position.latitude, position.longitude);
          _statusMessage = "Getting device direction...";
        });
        _startSensorFusion();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = "Failed to get location: $e";
          _isFetchingLocation = false;
        });
      }
    }
  }

  double _calculateQiblaBearing(double lat, double lon) {
    const double kaabaLat = _kaabaLatitude * pi / 180;
    const double kaabaLon = _kaabaLongitude * pi / 180;
    final double userLat = lat * pi / 180;
    final double userLon = lon * pi / 180;

    final double dLon = kaabaLon - userLon;

    final double y = sin(dLon) * cos(kaabaLat);
    final double x = cos(userLat) * sin(kaabaLat) -
        sin(userLat) * cos(kaabaLat) * cos(dLon);

    double bearing = atan2(y, x) * 180 / pi;
    bearing = (bearing + 360) % 360;
    return bearing;
  }

  void _startSensorFusion() {
    const samplingPeriod = Duration(milliseconds: 100);

    _accelerometerSubscription =
        accelerometerEventStream(samplingPeriod: samplingPeriod).listen((event) {
          // Low-pass filter to isolate gravity
          _gravity = Vector3(
            (_gravity?.x ?? 0) * 0.8 + event.x * 0.2,
            (_gravity?.y ?? 0) * 0.8 + event.y * 0.2,
            (_gravity?.z ?? 0) * 0.8 + event.z * 0.2,
          );
          _calculateAzimuth();
        });

    _magnetometerSubscription =
        magnetometerEventStream(samplingPeriod: samplingPeriod).listen((event) {
          // Low-pass filter for magnetic field
          _magnetic = Vector3(
            (_magnetic?.x ?? 0) * 0.8 + event.x * 0.2,
            (_magnetic?.y ?? 0) * 0.8 + event.y * 0.2,
            (_magnetic?.z ?? 0) * 0.8 + event.z * 0.2,
          );
          _calculateAzimuth();
        });
  }

  void _calculateAzimuth() {
    if (_gravity == null || _magnetic == null) return;

    // Normalize the acceleration vector
    Vector3 g = Vector3.copy(_gravity!);
    g.normalize();

    // Normalize the magnetic field vector
    Vector3 m = Vector3.copy(_magnetic!);
    m.normalize();

    // Compute the inclination matrix
    // This is the standard Android SensorManager implementation

    // East vector E = G x M (cross product)
    double ex = g.y * m.z - g.z * m.y;
    double ey = g.z * m.x - g.x * m.z;
    double ez = g.x * m.y - g.y * m.x;

    // Normalize east vector
    double normE = sqrt(ex * ex + ey * ey + ez * ez);
    if (normE < 0.1) {
      // Too unreliable, probably near magnetic pole
      return;
    }

    ex /= normE;
    ey /= normE;
    ez /= normE;

    // North vector N = E x G
    double nx = ey * g.z - ez * g.y;
    double ny = ez * g.x - ex * g.z;
    double nz = ex * g.y - ey * g.x;

    // Normalize north vector
    double normN = sqrt(nx * nx + ny * ny + nz * nz);
    nx /= normN;
    ny /= normN;
    nz /= normN;

    // Calculate heading based on device orientation
    // For portrait mode (phone held upright):
    double heading;

    // IMPORTANT: Try different formulas based on your device
    // Formula 1: Most common for portrait mode
    heading = atan2(ey, ny);

    // Formula 2: Alternative (try if Formula 1 doesn't work)
    // heading = atan2(ex, nx);

    // Formula 3: Another alternative
    // heading = atan2(-ny, ey);

    // Convert to degrees
    double azimuthInDegrees = heading * 180 / pi;

    // Normalize to 0-360 range
    if (azimuthInDegrees < 0) {
      azimuthInDegrees += 360;
    }

    // Apply device-specific calibration offset
    // You might need to experiment with these values:
    // 0, 90, 180, or 270
    // azimuthInDegrees = (azimuthInDegrees + 90) % 360; // Try this

    if (mounted) {
      setState(() {
        // Apply smoothing to reduce jitter
        _deviceAzimuth = _deviceAzimuth * 0.7 + azimuthInDegrees * 0.3;
        _statusMessage = "Pointing to Qibla";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calculate the needle angle
    // The needle should point to the Qibla direction relative to device heading
    final double needleAngle = (_qiblaDirection - _deviceAzimuth + 180) % 360;
    final double normalizedAngle = (needleAngle + 360) % 360;

    return Scaffold(
      backgroundColor: Colors.teal[900],
      appBar: AppBar(
        title: const Text("Qibla Compass"),
        backgroundColor: Colors.teal[800],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: FutureBuilder<bool>(
        future: _permissionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 24),
                  Text("Checking permissions...",
                      style: TextStyle(color: Colors.white70, fontSize: 16)),
                ],
              ),
            );
          }

          if (snapshot.hasData && snapshot.data == true) {
            if (_isFetchingLocation) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _getCurrentLocation();
              });
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 24),
                    Text("Fetching your location...",
                        style: TextStyle(color: Colors.white70, fontSize: 16)),
                  ],
                ),
              );
            }
            return _buildCompassBody(normalizedAngle);
          }

          return _buildPermissionDeniedBody();
        },
      ),
    );
  }

  Widget _buildPermissionDeniedBody() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.location_disabled, size: 80, color: Colors.white54),
          const SizedBox(height: 24),
          const Text("Permissions Required", style: TextStyle(
              color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          const Text(
              "Location and sensor access is required for accurate Qibla direction.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () async {
              await AppSettings.openAppSettings(type: AppSettingsType.settings);
            },
            icon: const Icon(Icons.settings),
            label: const Text("Open Settings"),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white,
                foregroundColor: Colors.teal[900]),
          ),
        ],
      ),
    );
  }

  Widget _buildCompassBody(double angle) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _statusMessage,
          style: const TextStyle(color: Colors.white70, fontSize: 16),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        SizedBox(
          height: 320,
          width: 320,
          child: RepaintBoundary(
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: angle),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutQuart,
              builder: (context, value, child) {
                return CustomPaint(
                  painter: QiblaCompassPainter(qiblaAngle: value, qiblaDirection: _qiblaDirection, deviceAzimuth: _deviceAzimuth),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 32),
        if (_userPosition != null) ...[
          Card(
            color: Colors.teal[800],
            margin: const EdgeInsets.symmetric(horizontal: 32),
            child: ListTile(
              leading: const Icon(Icons.my_location, color: Colors.white70),
              title: Text(
                "Qibla: ${_qiblaDirection.toStringAsFixed(
                    1)}° | Device: ${_deviceAzimuth.toStringAsFixed(1)}°",
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
              subtitle: Text(
                "Lat: ${_userPosition!.latitude.toStringAsFixed(
                    4)}, Lon: ${_userPosition!.longitude.toStringAsFixed(4)}",
                style: const TextStyle(color: Colors.white70),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              "Hold phone flat and rotate slowly. Keep away from metal objects.",
              style: TextStyle(color: Colors.white60, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ],
    );
  }
}

// CORRECT QiblaCompassPainter class definition
class QiblaCompassPainter extends CustomPainter {
  final double qiblaAngle;
  final double qiblaDirection;
  final double deviceAzimuth;

  QiblaCompassPainter({required this.qiblaAngle, required this.qiblaDirection, required this.deviceAzimuth});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 * 0.95;

    // --- GLOW EFFECT ---
    final double difference = (qiblaDirection - deviceAzimuth + 360) % 360;
    final bool isAligned = difference <= 1.0 || difference >= 359.0;

    final Paint circlePaint = Paint()
      ..color = isAligned ? Colors.green.withOpacity(0.5) : Colors.white.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = isAligned ? 8.0 : 4.0; // Thicker stroke for glow

    final Paint innerCirclePaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Outer circle
    canvas.drawCircle(center, radius, circlePaint);
    canvas.drawCircle(center, radius * 0.9, innerCirclePaint);

    // Degree marks
    for (int i = 0; i < 360; i += 15) {
      final double angle = i * pi / 180;
      final Offset start = center + Offset(sin(angle), -cos(angle)) * radius * 0.9;
      final Offset end = center + Offset(sin(angle), -cos(angle)) * radius;
      canvas.drawLine(
        start,
        end,
        Paint()
          ..color = Colors.white.withOpacity(i % 90 == 0 ? 0.8 : 0.4)
          ..strokeWidth = i % 90 == 0 ? 4 : 2,
      );
    }

    // Cardinal labels
    _drawText(canvas, center, "N", 0, radius * 1.1, Colors.white, 20);
    _drawText(canvas, center, "E", 90, radius * 1.1, Colors.white70, 16);
    _drawText(canvas, center, "S", 180, radius * 1.1, Colors.white70, 16);
    _drawText(canvas, center, "W", 270, radius * 1.1, Colors.white70, 16);

    // --- KAABA SYMBOL ---
    final double qiblaAngleRadians = qiblaDirection * pi / 180;
    final Offset kaabaOffset = center + Offset(sin(qiblaAngleRadians), -cos(qiblaAngleRadians)) * radius * 0.7;

    // Qibla Needle
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(qiblaAngle * pi / 180);

    // Red Qibla direction (top half)
    final Path qiblaPath = Path()
      ..moveTo(0, -radius * 0.85)
      ..lineTo(-radius * 0.12, radius * 0.15)
      ..lineTo(radius * 0.12, radius * 0.15)
      ..close();

    canvas.drawPath(qiblaPath, Paint()..color = Colors.redAccent);

    // White opposite direction
    final Path oppositePath = Path()
      ..moveTo(0, radius * 0.5)
      ..lineTo(-radius * 0.08, radius * 0.1)
      ..lineTo(radius * 0.08, radius * 0.1)
      ..close();

    canvas.drawPath(oppositePath, Paint()..color = Colors.white.withOpacity(0.7));

    // Center circle
    canvas.drawCircle(Offset.zero, radius * 0.12, Paint()..color = Colors.black54);
    canvas.drawCircle(Offset.zero, radius * 0.08, Paint()..color = Colors.redAccent);

    canvas.restore();
  }

  void _drawText(Canvas canvas, Offset center, String text, double angleDegrees, double radius, Color color, double fontSize) {
    final double angle = angleDegrees * pi / 180;
    final Offset position = center + Offset(sin(angle), -cos(angle)) * radius;

    final TextPainter tp = TextPainter(textDirection: TextDirection.ltr);
    tp.text = TextSpan(
      text: text,
      style: TextStyle(color: color, fontSize: fontSize, fontWeight: FontWeight.bold),
    );
    tp.layout();
    tp.paint(canvas, position - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant QiblaCompassPainter oldDelegate) {
    return oldDelegate.qiblaAngle != qiblaAngle ||
        oldDelegate.qiblaDirection != qiblaDirection ||
        oldDelegate.deviceAzimuth != deviceAzimuth;
  }
}