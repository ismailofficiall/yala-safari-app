import 'package:flutter/material.dart';
import '../constants/app_theme.dart';

class CustomLoader extends StatelessWidget {
  final double size;
  final Color? color;
  final String? message;

  const CustomLoader({
    super.key,
    this.size = 40.0,
    this.color,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(
                color ?? AppTheme.primaryGreen,
              ),
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: TextStyle(
                color: AppTheme.greyText,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
