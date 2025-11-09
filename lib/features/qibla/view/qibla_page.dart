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
      appBar: AppBar(
        title: const Text('Qibla Direction'),
        centerTitle: true,
      ),
      body: BlocProvider(
        create: (context) => QiblaBloc()..add(const QiblaDirectionRequested()),
        child: const QiblaView(),
      ),
    );
  }
}

class QiblaView extends StatelessWidget {
  const QiblaView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<QiblaBloc, QiblaState>(
      builder: (context, state) {
        return Center(
          child: _buildBody(context, state),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, QiblaState state) {
    if (state is QiblaLoading) {
      return const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 20),
          Text('Finding your location...'),
        ],
      );
    }
    if (state is QiblaLocationPermissionDenied) {
      return ErrorDisplay(
        message: state.message,
        actionText: 'Grant Permission',
        onAction: () => context.read<QiblaBloc>().add(const QiblaDirectionRequested()),
      );
    }
    if (state is QiblaLocationServiceDisabled) {
      return ErrorDisplay(
        message: state.message,
        actionText: 'Open Settings',
        onAction: () => Geolocator.openLocationSettings(),
      );
    }
    if (state is QiblaSensorError) {
      return ErrorDisplay(message: state.message);
    }
    if (state is QiblaLoadSuccess) {
      return QiblaCompass(
        qiblaDirection: state.qiblaDirection,
        distance: state.distanceToKaaba,
        accuracyStatus: state.accuracyStatus,
      );
    }
    return const SizedBox.shrink();
  }
}

class ErrorDisplay extends StatelessWidget {
  final String message;
  final String? actionText;
  final VoidCallback? onAction;

  const ErrorDisplay({
    super.key,
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
          Text(message, textAlign: TextAlign.center),
          if (actionText != null && onAction != null) ...[
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onAction, child: Text(actionText!)),
          ],
        ],
      ),
    );
  }
}

class QiblaCompass extends StatelessWidget {
  final double qiblaDirection;
  final double distance;
  final String accuracyStatus;

  const QiblaCompass({
    super.key,
    required this.qiblaDirection,
    required this.distance,
    required this.accuracyStatus,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Distance to Kaaba',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Text(
          '${(distance / 1000).toStringAsFixed(2)} km',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 40),
        SizedBox(
          width: 280,
          height: 280,
          child: CustomPaint(
            painter: QiblaCompassPainter(qiblaDirection: qiblaDirection),
            child: const Center(),
          ),
        ),
        const SizedBox(height: 40),
        Text(
          'Point your phone towards this direction',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 10),
        Text(
          accuracyStatus,
          style: TextStyle(
            color: accuracyStatus == 'High' ? Colors.green : Colors.orange,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class QiblaCompassPainter extends CustomPainter {
  final double qiblaDirection;

  const QiblaCompassPainter({required this.qiblaDirection});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final backgroundPaint = Paint()
      ..color = Colors.grey[200]!
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = Colors.grey[400]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final centerDotPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;
    final kaabaMarkerPaint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.fill;
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    // 1. Draw Background Circle
    canvas.drawCircle(center, radius, backgroundPaint);
    canvas.drawCircle(center, radius, borderPaint);

    // 2. Draw Cardinal Directions (N, E, S, W)
    final textStyle = const TextStyle(
      color: Colors.black87,
      fontSize: 24,
      fontWeight: FontWeight.bold,
    );
    const directions = ['N', 'E', 'S', 'W'];
    for (int i = 0; i < 4; i++) {
      final angle = (i * 90) * (math.pi / 180);
      final textOffset = Offset(
        center.dx + (radius - 30) * math.sin(angle),
        center.dy - (radius - 30) * math.cos(angle),
      );
      textPainter.text = TextSpan(text: directions[i], style: textStyle);
      textPainter.layout();
      textPainter.paint(
        canvas,
        textOffset - Offset(textPainter.width / 2, textPainter.height / 2),
      );
    }

    // 3. Rotate Canvas for Needle
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(qiblaDirection * (math.pi / 180));

    // 4. DRAW THE NEW, CORRECTLY SIZED NEEDLE
    final needlePath = Path();
    // Define the full needle shape from top to bottom
    needlePath.moveTo(0, -radius + 20); // North Tip
    needlePath.lineTo(-25, 0);          // West Edge of center
    needlePath.lineTo(0, radius - 20);  // South Tip
    needlePath.lineTo(25, 0);           // East Edge of center
    needlePath.close();

    // Create a gradient to fill the top half red and bottom half white
    final needleGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Colors.red, Colors.red, Colors.white, Colors.white],
      stops: const [0.0, 0.49, 0.51, 1.0], // A sharp line in the middle
    );
    final needlePaint = Paint()
      ..shader = needleGradient.createShader(
        Rect.fromCircle(center: Offset.zero, radius: radius),
      );
    canvas.drawPath(needlePath, needlePaint);

    // Add a border to the whole needle
    final needleBorderPaint = Paint()
      ..color = Colors.grey
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawPath(needlePath, needleBorderPaint);

    canvas.restore();

    // 5. Draw the Fixed Kaaba Marker at the top
    final kaabaMarkerPath = Path();
    const markerSize = 20.0;
    kaabaMarkerPath.addRRect(RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy - radius + 35),
        width: markerSize,
        height: markerSize,
      ),
      const Radius.circular(4),
    ));
    canvas.drawPath(kaabaMarkerPath, kaabaMarkerPaint);

    textPainter.text = const TextSpan(
      text: 'Kaaba',
      style: TextStyle(
        color: Colors.white,
        fontSize: 10,
        fontWeight: FontWeight.bold,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - radius + 35 - textPainter.height / 2,
      ),
    );

    // 6. Draw Center Pivot Dot
    canvas.drawCircle(center, 8, centerDotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is QiblaCompassPainter &&
        oldDelegate.qiblaDirection != qiblaDirection;
  }
}