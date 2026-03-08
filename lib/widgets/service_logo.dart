import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../theme/app_theme.dart';

class ServiceLogo extends StatelessWidget {
  final String? service;
  final double size;

  const ServiceLogo({super.key, required this.service, this.size = 40});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: _bgColor,
        border: Border.all(color: AppTheme.border, width: 1),
      ),
      child: Center(
        child: _buildLogo(),
      ),
    );
  }

  Color get _bgColor {
    switch (service) {
      case 'aws':
        return const Color(0xFF1A1200);
      case 'chase':
        return const Color(0xFF001A3A);
      case 'coinbase':
        return const Color(0xFF001A3A);
      case 'figma':
        return const Color(0xFF1A0A1A);
      case 'github':
        return const Color(0xFF0D0D0D);
      case 'linkedin':
        return const Color(0xFF001A2E);
      case 'netflix':
        return const Color(0xFF1A0000);
      case 'twitter':
        return const Color(0xFF0A0A0A);
      default:
        return AppTheme.surfaceElevated;
    }
  }

  Widget _buildLogo() {
    if (service == null) return Icon(Icons.lock, color: AppTheme.textSecondary, size: size * 0.55);
    final normalized = service!.toLowerCase().replaceAll(' ', '');
    String? token;
    try {
      token = dotenv.env['LOGO_DEV_TOKEN'];
    } catch (e) {
      // dotenv not initialized
    }
    if (token == null || token.isEmpty) return Icon(Icons.lock, color: AppTheme.textSecondary, size: size * 0.55);
    final url = "https://img.logo.dev/$normalized?token=$token&format=png&theme=dark";

    return Image.network(
      url,
      width: size * 0.55,
      height: size * 0.55,
      fit: BoxFit.contain,

      // While loading
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return SizedBox(
          width: size * 0.55,
          height: size * 0.55,
          child: Center(
            child: SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );
      },

      // If image fails completely
      errorBuilder: (_, _, _) {
        return Icon(
          Icons.lock,
          color: AppTheme.textSecondary,
          size: size * 0.5,
        );
      },
    );
  }
}
