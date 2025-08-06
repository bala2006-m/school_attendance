import 'package:flutter/cupertino.dart';

class DiagonalPainter extends CustomPainter {
  final Color fnColor;
  final Color anColor;

  DiagonalPainter(this.fnColor, this.anColor);

  @override
  void paint(Canvas canvas, Size size) {
    final paintFN = Paint()..color = fnColor;
    final paintAN = Paint()..color = anColor;

    final pathFN =
        Path()
          ..moveTo(0, 0)
          ..lineTo(size.width, 0)
          ..lineTo(0, size.height)
          ..close();

    final pathAN =
        Path()
          ..moveTo(size.width, size.height)
          ..lineTo(size.width, 0)
          ..lineTo(0, size.height)
          ..close();

    canvas.drawPath(pathFN, paintFN);
    canvas.drawPath(pathAN, paintAN);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
