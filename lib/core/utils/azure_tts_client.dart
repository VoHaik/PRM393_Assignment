import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

class AzureTtsClient {
  final Dio _dio;
  final AudioPlayer _audioPlayer;
  
  final String _key;
  final String _region;
  final String _voice;

  AzureTtsClient({
    Dio? dio,
    AudioPlayer? audioPlayer,
    required String apiKey,
    required String region,
    String? voice,
  })  : _dio = dio ?? Dio(),
        _audioPlayer = audioPlayer ?? AudioPlayer(),
        _key = apiKey,
        _region = region,
        _voice = voice ?? 'vi-VN-NamMinhNeural';

  String _escapeSsml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }

  Future<Uint8List> _synthesizeSpeech(String text) async {
    if (_key.isEmpty || _region.isEmpty) {
      throw Exception('Azure Speech is not configured. Key or Region is missing.');
    }

    final ssml = '<speak version="1.0" xml:lang="vi-VN"><voice name="$_voice">${_escapeSsml(text)}</voice></speak>';

    final response = await _dio.post<List<int>>(
      'https://$_region.tts.speech.microsoft.com/cognitiveservices/v1',
      data: ssml,
      options: Options(
        method: 'POST',
        headers: {
          'Ocp-Apim-Subscription-Key': _key,
          'Content-Type': 'application/ssml+xml',
          'X-Microsoft-OutputFormat': 'audio-16khz-128kbitrate-mono-mp3',
          'User-Agent': 'HistoryTalkMobile',
        },
        responseType: ResponseType.bytes,
      ),
    );

    if (response.statusCode != 200) {
      throw Exception('Azure Speech error ${response.statusCode}: ${response.statusMessage}');
    }

    if (response.data == null) {
      throw Exception('Azure Speech returned empty data');
    }

    return Uint8List.fromList(response.data!);
  }

  /// Synthesizes text and plays the audio.
  /// Returns the AudioPlayer instance to monitor playback state.
  Future<AudioPlayer> speak(String text) async {
    await stop();

    final bytes = await _synthesizeSpeech(text);
    
    // Save to temp directory
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/tts_${DateTime.now().millisecondsSinceEpoch}.mp3');
    await file.writeAsBytes(bytes);

    // Play the local file
    await _audioPlayer.play(DeviceFileSource(file.path));
    return _audioPlayer;
  }

  Future<void> pause() async {
    await _audioPlayer.pause();
  }

  Future<void> stop() async {
    await _audioPlayer.stop();
  }

  Future<void> dispose() async {
    await _audioPlayer.dispose();
  }
}
