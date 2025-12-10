import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:islam114/features/qibla/bloc/qibla_bloc.dart';
import 'package:islam114/features/qibla/bloc/qibla_event.dart';
import 'package:islam114/features/qibla/bloc/qibla_state.dart';

class QiblaPage extends StatelessWidget {
  const QiblaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Qibla Compass'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<QiblaBloc>().add(const QiblaDirectionRequested()),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFE8F5E8), // Light green
              Color(0xFFF1F8E9), // Lighter green
            ],
          ),
        ),
        child: BlocProvider(
          create: (context) => QiblaBloc()..add(const QiblaDirectionRequested()),
          child: const QiblaView(),
        ),
      ),
    );
  }
}

class QiblaView extends StatelessWidget {
  const QiblaView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<QiblaBloc, QiblaState>(
      builder: (context, state) => Center(child: _buildBody(context, state)),
    );
  }

  Widget _buildBody(BuildContext context, QiblaState state) {
    if (state is QiblaLoading) {
      return const _LoadingWidget();
    }
    if (state is QiblaLocationPermissionDenied) {
      return _ErrorWidget(
        message: state.message,
        actionText: 'Request Permission',
        onAction: () => context.read<QiblaBloc>().add(const QiblaDirectionRequested()),
      );
    }
    if (state is QiblaLocationServiceDisabled) {
      return _ErrorWidget(
        message: state.message,
        actionText: 'Open Location Settings',
        onAction: () => Geolocator.openLocationSettings(),
      );
    }
    if (state is QiblaSensorError) {
      return _ErrorWidget(message: state.message);
    }
    if (state is QiblaLoadSuccess) {
      return _SuccessWidget(state: state);
    }
    return const SizedBox.shrink();
  }
}

class _LoadingWidget extends StatelessWidget {
  const _LoadingWidget();

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(color: Colors.green),
        SizedBox(height: 16),
        Text('Locating and calibrating compass...', style: TextStyle(color: Colors.green)),
      ],
    );
  }
}

class _ErrorWidget extends StatelessWidget {
  final String message;
  final String? actionText;
  final VoidCallback? onAction;

  const _ErrorWidget({
    required this.message,
    this.actionText,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 64),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.green),
          ),
          if (actionText != null && onAction != null) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: onAction,
              child: Text(actionText!, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ],
      ),
    );
  }
}

class _SuccessWidget extends StatelessWidget {
  final QiblaLoadSuccess state;

  const _SuccessWidget({required this.state});

  @override
  Widget build(BuildContext context) {
    final distanceKm = (state.distanceToKaaba / 1000).toStringAsFixed(1);
    final isHighAccuracy = state.accuracyStatus == 'High';

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Distance to Kaaba',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.green),
          ),
          Text(
            '$distanceKm km',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.green.shade700,
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: 300,
            height: 300,
            child: CustomPaint(
              painter: QiblaCompassPainter(
                heading: state.currentHeading,
                relativeQiblaDirection: state.relativeQiblaDirection,
              ),
              child: const Center(),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Point device top towards Kaaba marker',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.green),
          ),
          const SizedBox(height: 8),
          Text(
            state.accuracyStatus,
            style: TextStyle(
              color: isHighAccuracy ? Colors.green : Colors.orange,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class QiblaCompassPainter extends CustomPainter {
  final double heading;
  final double relativeQiblaDirection;

  const QiblaCompassPainter({
    required this.heading,
    required this.relativeQiblaDirection,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 20;

    // Fixed facing direction arrow (at top)
    _drawFixedFacingArrow(canvas, center, radius);

    // Rotatable rose (directions + Kaaba marker)
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-heading * (math.pi / 180));

    // Rose background and border
    final roseBgPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final roseBorderPaint = Paint()
      ..color = Colors.green.shade300
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(Offset.zero, radius, roseBgPaint);
    canvas.drawCircle(Offset.zero, radius, roseBorderPaint);

    // Degree markings (every 30 degrees)
    _drawDegreeMarkings(canvas, radius);

    // Cardinal directions
    _drawDirectionLabels(canvas, radius);

    // Kaaba marker on border
    final qiblaAbsolute = (relativeQiblaDirection + heading) % 360;
    _drawKaabaMarker(canvas, radius, qiblaAbsolute);

    canvas.restore();

    // Center pivot
    final pivotPaint = Paint()..color = Colors.green.shade700;
    canvas.drawCircle(center, 8, pivotPaint);
  }

  void _drawFixedFacingArrow(Canvas canvas, Offset center, double radius) {
    final arrowPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    const double arrowHeight = 25.0;
    const double arrowWidth = 15.0;
    final arrowPath = Path()
      ..moveTo(center.dx, center.dy - radius + 8) // Tip
      ..lineTo(center.dx - arrowWidth, center.dy - radius + 8 + arrowHeight)
      ..lineTo(center.dx + arrowWidth, center.dy - radius + 8 + arrowHeight)
      ..close();

    canvas.drawPath(arrowPath, arrowPaint);
  }

  void _drawDegreeMarkings(Canvas canvas, double radius) {
    final markPaint = Paint()
      ..color = Colors.green.shade400
      ..strokeWidth = 2;
    final innerRadius = 0.85 * radius; // Changed from const to final
    final outerRadius = 0.95 * radius; // Changed from const to final
    for (int i = 0; i < 12; i++) {
      final angleDeg = i * 30.0;
      final angle = _compassAngleToRadians(angleDeg);
      final innerX = innerRadius * math.sin(angle);
      final innerY = -innerRadius * math.cos(angle);
      final outerX = outerRadius * math.sin(angle);
      final outerY = -outerRadius * math.cos(angle);
      canvas.drawLine(
        Offset(innerX, innerY),
        Offset(outerX, outerY),
        markPaint,
      );
    }
  }

  void _drawDirectionLabels(Canvas canvas, double radius) {
    final textStyle = const TextStyle(
      color: Colors.black87,
      fontSize: 20,
      fontWeight: FontWeight.bold,
    );
    const directions = <String>['N', 'E', 'S', 'W'];
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (int i = 0; i < 4; i++) {
      final angleDeg = i * 90.0;
      final angle = _compassAngleToRadians(angleDeg);
      final labelRadius = radius * 0.75;
      final x = labelRadius * math.sin(angle);
      final y = -labelRadius * math.cos(angle);
      textPainter.text = TextSpan(text: directions[i], style: textStyle);
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, y - textPainter.height / 2),
      );
    }
  }

  void _drawKaabaMarker(Canvas canvas, double radius, double qiblaAbsolute) {
    final angle = _compassAngleToRadians(qiblaAbsolute);
    final markerRadius = radius * 0.95;
    final x = markerRadius * math.sin(angle);
    final y = -markerRadius * math.cos(angle);

    // Green rounded rect symbol
    const markerSize = 16.0;
    final markerRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(x, y),
        width: markerSize,
        height: markerSize,
      ),
      const Radius.circular(3),
    );
    final markerPaint = Paint()..color = Colors.green.shade600;
    canvas.drawRRect(markerRect, markerPaint);

    // Kaaba label (small, below marker)
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'Kaaba',
        style: TextStyle(
          color: Colors.green,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    final labelY = y + markerSize / 2 + 2;
    textPainter.paint(
      canvas,
      Offset(x - textPainter.width / 2, labelY),
    );
  }

  static double _compassAngleToRadians(double degrees) {
    return degrees * (math.pi / 180);
  }

  @override
  bool shouldRepaint(QiblaCompassPainter oldDelegate) =>
      oldDelegate.heading != heading || oldDelegate.relativeQiblaDirection != relativeQiblaDirection;
}