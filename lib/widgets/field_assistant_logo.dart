import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class FieldAssistantLogo extends StatelessWidget {
  const FieldAssistantLogo({super.key, this.size = 40});

  final double size;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.paperFrost,
            borderRadius: BorderRadius.circular(size * 0.3),
          ),
          child: CustomPaint(painter: _FieldAssistantLogoPainter()),
        ),
      ),
    );
  }
}

class _FieldAssistantLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 48, size.height / 48);

    final outline = Paint()
      ..color = AppColors.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final page = Path()
      ..moveTo(15, 7)
      ..lineTo(26, 7)
      ..lineTo(34, 15)
      ..lineTo(34, 35)
      ..quadraticBezierTo(34, 39, 30, 39)
      ..lineTo(16, 39)
      ..quadraticBezierTo(12, 39, 12, 35)
      ..lineTo(12, 11)
      ..quadraticBezierTo(12, 7, 15, 7)
      ..close();
    canvas.drawPath(
      page,
      Paint()
        ..color = AppColors.galleryWhite
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(page, outline);
    canvas.drawLine(const Offset(26, 7), const Offset(26, 15), outline);
    canvas.drawLine(const Offset(26, 15), const Offset(34, 15), outline);
    canvas.drawLine(const Offset(18, 22), const Offset(28, 22), outline);
    canvas.drawLine(const Offset(18, 27), const Offset(27, 27), outline);

    canvas.drawCircle(
      const Offset(34, 34),
      9,
      Paint()..color = AppColors.appleBlue,
    );
    final check = Paint()
      ..color = AppColors.galleryWhite
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(
      Path()
        ..moveTo(30.5, 34)
        ..lineTo(33, 36.5)
        ..lineTo(37.5, 31.5),
      check,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _FieldAssistantLogoPainter oldDelegate) => false;
}
