import 'dart:math' as math;
import 'dart:async'; // Add this import for StreamSubscription
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// Full-screen Qibla compass.
/// The red needle always points to the physical Kaaba in Makkah.
class QiblaPage extends StatefulWidget {
  const QiblaPage({super.key});

  @override
  State<QiblaPage> createState() => _QiblaPageState();
}

class _QiblaPageState extends State<QiblaPage>
    with SingleTickerProviderStateMixin {
  /* ------------------------------------------------------------------ */
  /* ------------------------- location --------------------------------*/
  /* ------------------------------------------------------------------ */
  Position? _position;
  bool _locationError = false;
  bool _isLoadingLocation = true;

  /* ------------------------------------------------------------------ */
  /* ------------------------- sensors ---------------------------------*/
  /* ------------------------------------------------------------------ */
  double _azimuth = 0; // device heading (0 = North, 90 = East …)
  double _previousAzimuth = 0; // Track previous azimuth to detect changes
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  StreamSubscription<MagnetometerEvent>? _magnetometerSubscription;

  // Sensor values
  double? _accelX;
  double? _accelY;
  double? _accelZ;
  double? _magX;
  double? _magY;
  double? _magZ;

  /* ------------------------------------------------------------------ */
  /* ------------------------- ui --------------------------------------*/
  /* ------------------------------------------------------------------ */
  late AnimationController _needleController;
  late Animation<double> _needleAnimation;

  @override
  void initState() {
    super.initState();
    _initializeCompass();
  }

  Future<void> _initializeCompass() async {
    // Setup the animation controller for smooth needle movement
    _needleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _needleAnimation =
        Tween<double>(begin: 0, end: 1).animate(
            CurvedAnimation(parent: _needleController, curve: Curves.easeOutCubic)
        );

    await _requestLocationAndListen();
    _setupSensors();
  }

  /* =====================  LOCATION  ===================== */
  Future<void> _requestLocationAndListen() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) setState(() {
        _locationError = true;
        _isLoadingLocation = false;
      });
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) setState(() {
          _locationError = true;
          _isLoadingLocation = false;
        });
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      if (mounted) setState(() {
        _locationError = true;
        _isLoadingLocation = false;
      });
      return;
    }

    // Obtain the initial location fix
    try {
      final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      if (mounted) setState(() {
        _position = pos;
        _isLoadingLocation = false;
      });
    } on PlatformException {
      if (mounted) setState(() {
        _locationError = true;
        _isLoadingLocation = false;
      });
    }
  }

  /* =====================  SENSORS  ===================== */
  void _setupSensors() {
    // Listen to accelerometer
    _accelerometerSubscription = accelerometerEventStream(
        samplingPeriod: const Duration(milliseconds: 100)
    ).listen((AccelerometerEvent event) {
      _accelX = event.x;
      _accelY = event.y;
      _accelZ = event.z;
      _calculateAzimuth();
    });

    // Listen to magnetometer
    _magnetometerSubscription = magnetometerEventStream(
        samplingPeriod: const Duration(milliseconds: 100)
    ).listen((MagnetometerEvent event) {
      _magX = event.x;
      _magY = event.y;
      _magZ = event.z;
      _calculateAzimuth();
    });
  }

  void _calculateAzimuth() {
    // Only calculate if we have both accelerometer and magnetometer data
    if (_accelX == null || _accelY == null || _accelZ == null ||
        _magX == null || _magY == null || _magZ == null) {
      return;
    }

    // Calculate the device orientation using sensor fusion
    final double ax = _accelX!;
    final double ay = _accelY!;
    final double az = _accelZ!;
    final double mx = _magX!;
    final double my = _magY!;
    final double mz = _magZ!;

    // Calculate the normalized vectors
    final double accelMagnitude = math.sqrt(ax * ax + ay * ay + az * az);
    final double magMagnitude = math.sqrt(mx * mx + my * my + mz * mz);

    if (accelMagnitude == 0 || magMagnitude == 0) return;

    final double aX = ax / accelMagnitude;
    final double aY = ay / accelMagnitude;
    final double aZ = az / accelMagnitude;

    final double mX = mx / magMagnitude;
    final double mY = my / magMagnitude;
    final double mZ = mz / magMagnitude;

    // Calculate the cross product of magnetic vector and gravity vector
    final double hX = mY * aZ - mZ * aY;
    final double hY = mZ * aX - mX * aZ;
    final double hZ = mX * aY - mY * aX;

    // Normalize the horizontal component
    final double hMagnitude = math.sqrt(hX * hX + hY * hY);
    if (hMagnitude == 0) return;

    final double hXNorm = hX / hMagnitude;
    final double hYNorm = hY / hMagnitude;

    // Calculate the azimuth
    double azimuth = math.atan2(hYNorm, hXNorm) * (180 / math.pi);
    azimuth = (azimuth + 360) % 360;

    // Apply low-pass filter to smooth out jitter
    final double alpha = 0.15; // Filter coefficient
    azimuth = alpha * azimuth + (1 - alpha) * _azimuth;

    // Only update if there's a significant change (more than 1 degree)
    if (mounted && (azimuth - _previousAzimuth).abs() > 1.0) {
      setState(() {
        _previousAzimuth = _azimuth;
        _azimuth = azimuth;
      });

      // Only animate if the change is significant (more than 5 degrees)
      if ((azimuth - _previousAzimuth).abs() > 5.0) {
        _needleController.reset();
        _needleController.forward();
      }
    }
  }

  /* =====================  QIBLA BEARING  ===================== */
  /// Calculates the Qibla bearing (direction to Mecca) from the device's current location.
  double _qiblaBearing() {
    if (_position == null) return 0;

    const double kaabaLat = 21.422477; // Kaaba latitude
    const double kaabaLng = 39.825183; // Kaaba longitude

    final double myLat = _position!.latitude;
    final double myLng = _position!.longitude;

    // Convert coordinates to radians
    final double phiK = kaabaLat * (math.pi / 180);
    final double lambdaK = kaabaLng * (math.pi / 180);
    final double phiM = myLat * (math.pi / 180);
    final double lambdaM = myLng * (math.pi / 180);

    // Calculate the bearing using the spherical law of cosines
    final double psi = 180 /
        math.pi *
        math.atan2(
          math.sin(lambdaK - lambdaM),
          math.cos(phiM) * math.tan(phiK) -
              math.sin(phiM) * math.cos(lambdaK - lambdaM),
        );

    // Normalize the result to 0-360 degrees
    return (psi + 360) % 360;
  }

  /* =====================  UI  ===================== */
  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final double qibla = _qiblaBearing();
    // Angle the needle should rotate relative to the current device orientation
    final double needleAngle = (qibla - _azimuth + 360) % 360;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Qibla Direction'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
          ),
        ),
        child: Column(
          children: [
            const Spacer(flex: 2),

            /* --------------- Compass Rose --------------- */
            SizedBox(
              width: 280,
              height: 280,
              child: Stack(alignment: Alignment.center, children: [
                // Compass background
                Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                    border: Border.all(color: Colors.white70, width: 2),
                  ),
                ),

                // Compass directions
                _buildCompassDirections(),

                // Kaaba symbol (fixed on the rose, rotates with the compass)
                Transform.rotate(
                  // Rotates the icon so it points towards the Kaaba bearing,
                  // relative to the device's North (_azimuth)
                  angle: (qibla - _azimuth) * (math.pi / 180),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 120),
                    child: _kaabaSymbol(), // Custom Kaaba icon
                  ),
                ),

                // Needle
                AnimatedBuilder(
                  animation: _needleAnimation,
                  builder: (_, __) {
                    // The needle rotates to the calculated needleAngle with animation smoothing
                    return Transform.rotate(
                      angle: (needleAngle * _needleAnimation.value) *
                          (math.pi / 180),
                      child: _needle(),
                    );
                  },
                ),

                // Center pin
                Container(
                  width: 14,
                  height: 14,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ]),
            ),

            const Spacer(),

            /* --------------- Info Card --------------- */
            if (_locationError) ...[
              _infoCard(
                icon: Icons.location_off,
                text: 'Location permission required',
                color: Colors.orangeAccent,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: theme.primaryColor,
                ),
                onPressed: () async {
                  setState(() {
                    _locationError = false;
                    _isLoadingLocation = true;
                  });
                  await _requestLocationAndListen();
                },
                child: const Text('Grant Permission'),
              ),
            ] else if (_isLoadingLocation) ...[
              _infoCard(
                icon: Icons.location_searching,
                text: 'Acquiring location …',
                color: Colors.white70,
              ),
            ] else ...[
              // Note: String interpolation makes this widget non-const
              _infoCard(
                icon: Icons.explore,
                text:
                'Align the red needle with the Kaaba icon\n${_azimuth.toStringAsFixed(0)}°  –  Qibla ${_qiblaBearing().toStringAsFixed(0)}°',
                color: Colors.white,
              ),
            ],

            const Spacer(flex: 2),
          ],
        ),
      ),
    );
  }

  Widget _buildCompassDirections() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // N
        const Positioned(top: 10, child: Text('N', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold))),
        // E
        const Positioned(right: 10, child: Text('E', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold))),
        // S
        const Positioned(bottom: 10, child: Text('S', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold))),
        // W
        const Positioned(left: 10, child: Text('W', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold))),

        // NE
        const Positioned(top: 50, right: 50, child: Text('NE', style: TextStyle(color: Colors.white70, fontSize: 16))),
        // SE
        const Positioned(bottom: 50, right: 50, child: Text('SE', style: TextStyle(color: Colors.white70, fontSize: 16))),
        // SW
        const Positioned(bottom: 50, left: 50, child: Text('SW', style: TextStyle(color: Colors.white70, fontSize: 16))),
        // NW
        const Positioned(top: 50, left: 50, child: Text('NW', style: TextStyle(color: Colors.white70, fontSize: 16))),
      ],
    );
  }

  // Uses CustomPaint for a stylized Kaaba icon
  Widget _kaabaSymbol() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.amber,
        borderRadius: BorderRadius.circular(6),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: CustomPaint(
        painter: _KaabaSymbolPainter(),
      ),
    );
  }

  // Marked const as the content is entirely static
  Widget _needle() {
    return SizedBox(
      width: 280,
      height: 280,
      child: CustomPaint(
        painter: _NeedlePainter(),
      ),
    );
  }

  Widget _infoCard({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white30),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(color: color, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _needleController.dispose();
    _accelerometerSubscription?.cancel();
    _magnetometerSubscription?.cancel();
    super.dispose();
  }
}

/* =====================  PAINTERS  ===================== */

/// Painter for the Qibla needle - NOW USES SHARP TRIANGLES
class _NeedlePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint red = Paint()
      ..color = Colors.redAccent // Front side (Qibla pointer)
      ..style = PaintingStyle.fill;

    final Paint white = Paint()
      ..color = Colors.white // Back side (North pointer)
      ..style = PaintingStyle.fill;

    final double r = size.width / 2;
    final Offset center = Offset(r, r);

    // --- Front-side (red) - Sharp triangle pointing Up (North on the canvas) ---
    final Path frontPath = Path()
      ..moveTo(center.dx, center.dy - 10) // Start point (just above center)
    // Triangle point at the very top
      ..lineTo(center.dx, center.dy - r + 4)
      ..lineTo(center.dx + 10, center.dy - 10)
      ..lineTo(center.dx - 10, center.dy - 10) // Small width at base
      ..close();
    canvas.drawPath(frontPath, red);

    // --- Back-side (white) - Simple pointer pointing Down (South on the canvas) ---
    final Path backPath = Path()
      ..moveTo(center.dx - 10, center.dy + 10) // Small width at base
      ..lineTo(center.dx + 10, center.dy + 10)
    // Triangle point at the very bottom
      ..lineTo(center.dx, center.dy + r - 4)
      ..lineTo(center.dx - 10, center.dy + 10)
      ..close();
    canvas.drawPath(backPath, white);

    // Center circle to cover the base of the pointers
    canvas.drawCircle(center, 12, Paint()..color = Colors.white);
    canvas.drawCircle(center, 10, Paint()..color = Colors.red.shade900);
  }

  @override
  bool shouldRepaint(_) => false;
}

/// Custom painter for the Kaaba symbol
class _KaabaSymbolPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint black = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.fill;

    final double w = size.width;
    final double h = size.height;

    // Draw a small roof triangle at the top
    final Path roof = Path()
      ..moveTo(w * 0.2, h * 0.4)
      ..lineTo(w * 0.8, h * 0.4)
      ..lineTo(w * 0.5, h * 0.2)
      ..close();
    canvas.drawPath(roof, black);

    // Draw the main body rectangle
    canvas.drawRect(
      Rect.fromLTRB(w * 0.2, h * 0.4, w * 0.8, h * 0.8),
      black,
    );

    // Draw a simplified door
    final Paint door = Paint()
      ..color = Colors.amber.shade200
      ..style = PaintingStyle.fill;

    canvas.drawRect(
      Rect.fromLTRB(w * 0.4, h * 0.6, w * 0.6, h * 0.75),
      door,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}