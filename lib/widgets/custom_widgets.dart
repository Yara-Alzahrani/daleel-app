import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final String hint;
  final TextEditingController controller;
  final bool obscureText;
  final TextInputType keyboardType;
  final Widget? prefixIcon;
  final String? Function(String?)? validator;

  const CustomTextField({
    Key? key,
    required this.hint,
    required this.controller,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.prefixIcon,
    this.validator,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400]),
        prefixIcon: prefixIcon,
      ),
    );
  }
}

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;

  const CustomButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF006E51), Color(0xFFA384DA)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(25),
        ),
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
            textStyle: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          child: isLoading
              ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Text(text),
        ),
      ),
    );
  }
}

class DaleelLogo extends StatelessWidget {
  final double size;

  const DaleelLogo({Key? key, this.size = 120}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Center(
        child: CustomPaint(
          size: Size(size * 0.8, size * 0.8),
          painter: DaleelLogoPainter(),
        ),
      ),
    );
  }
}

class DaleelLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    paint.color = const Color(0xFFA384DA);
    Path purplePath = Path();
    purplePath.moveTo(0, size.height * 0.7);
    purplePath.quadraticBezierTo(size.width * 0.25, size.height * 0.65,
        size.width * 0.5, size.height * 0.7);
    purplePath.quadraticBezierTo(
        size.width * 0.75, size.height * 0.75, size.width, size.height * 0.7);
    purplePath.lineTo(size.width, size.height);
    purplePath.lineTo(0, size.height);
    purplePath.close();
    canvas.drawPath(purplePath, paint);

    paint.color = const Color(0xFFFFE381);
    Path sandPath = Path();
    sandPath.moveTo(0, size.height * 0.5);
    sandPath.quadraticBezierTo(size.width * 0.3, size.height * 0.45,
        size.width * 0.6, size.height * 0.5);
    sandPath.quadraticBezierTo(
        size.width * 0.8, size.height * 0.53, size.width, size.height * 0.5);
    sandPath.lineTo(size.width, size.height * 0.7);
    sandPath.quadraticBezierTo(size.width * 0.75, size.height * 0.75,
        size.width * 0.5, size.height * 0.7);
    sandPath.quadraticBezierTo(
        size.width * 0.25, size.height * 0.65, 0, size.height * 0.7);
    sandPath.close();
    canvas.drawPath(sandPath, paint);

    paint.color = const Color(0xFF006E51);
    Path mountainPath = Path();
    mountainPath.moveTo(size.width * 0.5, size.height * 0.15);
    mountainPath.lineTo(size.width * 0.85, size.height * 0.5);
    mountainPath.quadraticBezierTo(size.width * 0.8, size.height * 0.53,
        size.width * 0.6, size.height * 0.5);
    mountainPath.quadraticBezierTo(size.width * 0.55, size.height * 0.35,
        size.width * 0.5, size.height * 0.15);
    mountainPath.close();
    canvas.drawPath(mountainPath, paint);

    paint.color = Colors.white;
    final pinCenter = Offset(size.width * 0.65, size.height * 0.3);
    canvas.drawCircle(pinCenter, size.width * 0.08, paint);
    paint.color = const Color(0xFF006E51);
    canvas.drawCircle(pinCenter, size.width * 0.05, paint);

    paint.color = const Color(0xFF006E51);
    final trunkRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.25, size.height * 0.4, size.width * 0.03,
          size.height * 0.15),
      const Radius.circular(2),
    );
    canvas.drawRRect(trunkRect, paint);

    paint.color = const Color(0xFFFFE381);
    canvas.drawCircle(
        Offset(size.width * 0.3, size.height * 0.2), size.width * 0.08, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
