import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:indogrip/core/service/logger.dart';

class EnvConfig {
  static String get indoGripBaseUrl => dotenv.env['IndoGrip_BASE_URL'] ?? '';

  static String get indoGripMobileBaseUrl =>
      dotenv.env['INDOGRIP_MOBILE_BASE_URL'] ?? '';

  static Future<void> init() async {
    try {
      await dotenv.load(fileName: ".env");
      logger.i('EnvConfig => Environment loaded successfully');
      _validateConfig();
    } catch (e) {
      logger.e('Error loading .env file, using default values $e');
      // Don't rethrow - use default values instead
    }
  }

  static void _validateConfig() {
    if (indoGripBaseUrl.isEmpty) {
      logger.w('Warning: IndoGrip_BASE_URL is empty');
    }
    if (indoGripMobileBaseUrl.isEmpty) {
      logger.w('Warning: INDOGRIP_MOBILE_BASE_URL is empty');
    }
  }
}
