import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:math' as math;
import 'dart:async';
import 'package:vector_math/vector_math_64.dart' as vector;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const QiblaApp());
}

class QiblaApp extends StatelessWidget {
  const QiblaApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      home: const QiblaPage(),
    );
  }
}

class QiblaPage extends StatefulWidget {
  const QiblaPage({super.key});
  @override
  State<QiblaPage> createState() => _QiblaPageState();
}

class _QiblaPageState extends State<QiblaPage> with TickerProviderStateMixin {
  // ---------------------------------------------------------------------------
  // 1. ENGINE CONSTANTS & COLORS
  // ---------------------------------------------------------------------------
  static const double _kInternalBias = -75.0;
  static const double _kaabaLat = 21.422510;
  static const double _kaabaLon = 39.826168;

  final Color emeraldAccent = const Color(0xFF00FF88);
  late AnimationController _pulseController;

  bool _isLocating = true;
  bool _isAligned = false;
  double _userFineTune = 0.0;

  double? _qiblaBearing;
  double? _currentHeading;
  double? _distanceToKaaba;

  final List<double> _accel = [0, 0, 0];
  final List<double> _mag = [0, 0, 0];

  // ULTRA-SENSITIVE SETTINGS
  final List<double> _headingHistory = [];
  final int _smoothingWindow = 3; // Minimal window for raw speed

  StreamSubscription? _magSub;
  StreamSubscription? _accelSub;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 2)
    )..repeat(reverse: true);
    _hydrateAndStart();
  }

  // ---------------------------------------------------------------------------
  // 2. INSTANT-ON LOGIC (CACHING)
  // ---------------------------------------------------------------------------
  Future<void> _hydrateAndStart() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userFineTune = prefs.getDouble('fine_tune') ?? 0.0;
      _qiblaBearing = prefs.getDouble('cached_bearing');
      _distanceToKaaba = prefs.getDouble('cached_distance');
      if (_qiblaBearing != null) _isLocating = false;
    });
    _startEngine();
  }

  Future<void> _startEngine() async {
    var status = await Permission.locationWhenInUse.request();
    if (status.isGranted) {
      _startSensors();
      Position pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.bestForNavigation
      );
      _calculateAndStore(pos);
    }
  }

  void _calculateAndStore(Position pos) async {
    final prefs = await SharedPreferences.getInstance();
    double lat1 = pos.latitude * (math.pi / 180);
    double lon1 = pos.longitude * (math.pi / 180);
    double lat2 = _kaabaLat * (math.pi / 180);
    double lon2 = _kaabaLon * (math.pi / 180);

    double dLon = lon2 - lon1;
    double y = math.sin(dLon) * math.cos(lat2);
    double x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);

    double bearing = (math.atan2(y, x) * 180 / math.pi + 360) % 360;
    double dist = Geolocator.distanceBetween(pos.latitude, pos.longitude, _kaabaLat, _kaabaLon) / 1000;

    prefs.setDouble('cached_bearing', bearing);
    prefs.setDouble('cached_distance', dist);

    setState(() {
      _qiblaBearing = bearing;
      _distanceToKaaba = dist;
      _isLocating = false;
    });
  }

  // ---------------------------------------------------------------------------
  // 3. RAW SENSOR FUSION (ZERO LAG)
  // ---------------------------------------------------------------------------
  void _startSensors() {
    _accelSub = accelerometerEvents.listen((e) {
      _accel[0] = e.x; _accel[1] = e.y; _accel[2] = e.z;
    });
    _magSub = magnetometerEvents.listen((e) {
      _mag[0] = e.x; _mag[1] = e.y; _mag[2] = e.z;
      _processOrientation();
    });
  }

  void _processOrientation() {
    vector.Vector3 g = vector.Vector3(_accel[0], _accel[1], _accel[2]);
    vector.Vector3 m = vector.Vector3(_mag[0], _mag[1], _mag[2]);

    vector.Vector3 e = m.cross(g)..normalize();
    vector.Vector3 n = g.cross(e)..normalize();

    double raw = math.atan2(-e.x, n.x) * (180 / math.pi);
    double corrected = (raw + _kInternalBias + _userFineTune + 360) % 360;

    // Use a tiny history only to prevent hardware "glitching"
    _headingHistory.add(corrected);
    if (_headingHistory.length > _smoothingWindow) _headingHistory.removeAt(0);

    double s = 0, c = 0;
    for (var h in _headingHistory) {
      s += math.sin(h * math.pi / 180);
      c += math.cos(h * math.pi / 180);
    }
    double targetHeading = (math.atan2(s, c) * 180 / math.pi + 360) % 360;

    if (mounted) {
      setState(() {
        // REMOVED LERP: Update is now 1.0 (Direct/Instant)
        _currentHeading = targetHeading;

        if (_qiblaBearing != null) {
          double diff = (_qiblaBearing! - _currentHeading! + 360) % 360;
          bool aligned = (diff < 5 || diff > 355);
          if (aligned && !_isAligned) {
            HapticFeedback.selectionClick();
            _isAligned = true;
          } else if (!aligned) {
            _isAligned = false;
          }
        }
      });
    }
  }

  // ---------------------------------------------------------------------------
  // 4. UI BUILDER (DESIGN PRESERVED)
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF010409),
      body: Stack(
        children: [
          _buildAtmosphere(),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 20),
                _buildMinimalHeader(),
                const Spacer(),
                _buildPremiumCompass(),
                const Spacer(),
                _buildGlassCards(),
                const SizedBox(height: 30),
              ],
            ),
          ),
          _buildSecretTrigger(),
        ],
      ),
    );
  }

  Widget _buildAtmosphere() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, _) => Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -0.2),
            radius: 1.4,
            colors: [
              _isAligned
                  ? emeraldAccent.withOpacity(0.08 * _pulseController.value)
                  : Colors.amber.withOpacity(0.03),
              const Color(0xFF010409),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMinimalHeader() {
    return Column(
      children: [
        const Text("PRECISION QIBLA",
            style: TextStyle(letterSpacing: 6, fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white24)),
        const SizedBox(height: 10),
        if (_isLocating)
          const SizedBox(width: 40, child: LinearProgressIndicator(backgroundColor: Colors.transparent, color: Colors.amber)),
      ],
    );
  }

  Widget _buildPremiumCompass() {
    if (_qiblaBearing == null) return const CircularProgressIndicator(color: Colors.amber);

    final double rotation = (_qiblaBearing! - (_currentHeading ?? 0) + 360) % 360;

    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 320, height: 320,
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _isAligned ? emeraldAccent.withOpacity(0.1) : Colors.black,
                  blurRadius: 60, spreadRadius: 5,
                )
              ]
          ),
        ),
        Transform.rotate(
          angle: -(_currentHeading ?? 0) * (math.pi / 180),
          child: CustomPaint(
            size: const Size(320, 320),
            painter: HighDefCompassPainter(isAligned: _isAligned, emerald: emeraldAccent),
          ),
        ),
        Transform.rotate(
          angle: rotation * (math.pi / 180),
          child: Column(
            children: [
              _buildMosqueIndicator(),
              const SizedBox(height: 220),
            ],
          ),
        ),
        _buildCentralHUD(),
      ],
    );
  }

  Widget _buildMosqueIndicator() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _isAligned ? emeraldAccent : const Color(0xFF161B22),
          border: Border.all(
              color: _isAligned ? Colors.white : Colors.amber.withOpacity(0.3),
              width: 2
          ),
          boxShadow: [
            if (_isAligned) BoxShadow(color: emeraldAccent, blurRadius: 20, spreadRadius: 2)
          ]
      ),
      child: Icon(Icons.mosque, color: _isAligned ? Colors.black : Colors.amber, size: 26),
    );
  }

  Widget _buildCentralHUD() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          "${_currentHeading?.toStringAsFixed(0)}°",
          style: TextStyle(
              fontSize: 62,
              fontWeight: FontWeight.w100,
              color: _isAligned ? emeraldAccent : Colors.white
          ),
        ),
        Text(
          _isAligned ? "LOCKED" : "SCANNING",
          style: TextStyle(
              letterSpacing: 4,
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: _isAligned ? emeraldAccent : Colors.white24
          ),
        ),
      ],
    );
  }

  Widget _buildGlassCards() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          _glassTile("DISTANCE", "${_distanceToKaaba?.toStringAsFixed(0) ?? '...'} KM", Icons.near_me_outlined),
          const SizedBox(width: 15),
          _glassTile("QIBLA", "${_qiblaBearing?.toStringAsFixed(1) ?? '...'}°", Icons.explore_outlined),
        ],
      ),
    );
  }

  Widget _glassTile(String label, String val, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: Colors.amber.withOpacity(0.6)),
            const SizedBox(height: 12),
            Text(label, style: const TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
            Text(val, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _buildSecretTrigger() {
    return Positioned(
      top: 0, right: 0,
      child: GestureDetector(
        onDoubleTap: _showSecretCalibration,
        child: Container(width: 80, height: 80, color: Colors.transparent),
      ),
    );
  }

  void _showSecretCalibration() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0D1117),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) => StatefulBuilder(
        builder: (context, setST) => Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("HARDWARE TUNING", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2)),
              Slider(
                value: _userFineTune, min: -15, max: 15,
                activeColor: Colors.amber,
                onChanged: (v) async {
                  setState(() => _userFineTune = v); setST(() {});
                  (await SharedPreferences.getInstance()).setDouble('fine_tune', v);
                },
              ),
              Text("${_userFineTune.toStringAsFixed(1)}° Manual Offset"),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _magSub?.cancel(); _accelSub?.cancel();
    _pulseController.dispose();
    super.dispose();
  }
}

class HighDefCompassPainter extends CustomPainter {
  final bool isAligned;
  final Color emerald;
  HighDefCompassPainter({required this.isAligned, required this.emerald});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    for (int i = 0; i < 360; i += 2) {
      final double angle = (i - 90) * (math.pi / 180);
      final bool isMajor = i % 30 == 0;
      final bool isCardinal = i % 90 == 0;

      double tickLen = isCardinal ? 18 : (isMajor ? 12 : 5);
      final paint = Paint()
        ..color = isCardinal
            ? (i == 0 ? Colors.redAccent : (isAligned ? emerald : Colors.white))
            : (isMajor ? Colors.white54 : Colors.white.withOpacity(0.1))
        ..strokeWidth = isCardinal ? 2.5 : (isMajor ? 1.5 : 0.5)
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(
        Offset(center.dx + (radius - tickLen) * math.cos(angle), center.dy + (radius - tickLen) * math.sin(angle)),
        Offset(center.dx + radius * math.cos(angle), center.dy + radius * math.sin(angle)),
        paint,
      );

      if (isMajor) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: i == 0 ? "N" : (i == 90 ? "E" : (i == 180 ? "S" : (i == 270 ? "W" : "$i"))),
            style: TextStyle(
                color: i == 0 ? Colors.redAccent : Colors.white38,
                fontSize: isCardinal ? 14 : 10,
                fontWeight: FontWeight.bold
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();

        canvas.save();
        canvas.translate(
          center.dx + (radius - 40) * math.cos(angle),
          center.dy + (radius - 40) * math.sin(angle),
        );
        canvas.rotate(i * (math.pi / 180));
        textPainter.paint(canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));
        canvas.restore();
      }
    }
  }
  @override bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}