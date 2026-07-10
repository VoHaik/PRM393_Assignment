import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  // 1. API base URL
  static String get apiBaseUrl => dotenv.get('API_BASE_URL', fallback: '');

  // 2. Google OAuth client IDs
  static String get googleWebClientId => dotenv.get('GOOGLE_WEB_CLIENT_ID', fallback: '');

  static String get googleAndroidClientId => dotenv.get('GOOGLE_ANDROID_CLIENT_ID', fallback: '');

  static String get googleIosClientId => dotenv.get('GOOGLE_IOS_CLIENT_ID', fallback: '');

  // 3. Azure Cognitive Speech key, region, and default voice
  static String get azureSpeechKey => dotenv.get('AZURE_SPEECH_KEY', fallback: '');

  static String get azureSpeechRegion => dotenv.get('AZURE_SPEECH_REGION', fallback: '');

  static String get azureSpeechVoice => dotenv.get('AZURE_SPEECH_VOICE', fallback: 'vi-VN-NamMinhNeural');

  // Fallback default for local development
  static String get defaultApiUrl {
    final baseUrl = apiBaseUrl;
    if (baseUrl.isNotEmpty) {
      return baseUrl;
    }
    if (!kIsWeb && Platform.isAndroid) {
      return 'http://10.0.2.2:5000/api/v1';
    }
    return 'http://localhost:5000/api/v1';
  }
}
