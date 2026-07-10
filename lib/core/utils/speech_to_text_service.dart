import 'package:speech_to_text/speech_to_text.dart' as stt;

class SpeechToTextService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;
  bool get isListening => _speech.isListening;

  /// Initializes the speech-to-text system.
  Future<bool> initialize({
    Function(String)? onError,
    Function(String)? onStatus,
  }) async {
    if (_isInitialized) return true;
    try {
      _isInitialized = await _speech.initialize(
        onError: (val) => onError?.call(val.errorMsg),
        onStatus: (val) => onStatus?.call(val),
      );
    } catch (e) {
      _isInitialized = false;
    }
    return _isInitialized;
  }

  /// Starts listening to microphone input.
  /// Reports results (both partial and final) via [onResult].
  Future<void> startListening({
    required Function(String words, bool isFinal) onResult,
    String localeId = 'vi_VN',
  }) async {
    if (!_isInitialized) {
      final initialized = await this.initialize();
      if (!initialized) {
        throw Exception('Không thể khởi tạo dịch vụ nhận diện giọng nói');
      }
    }

    await _speech.listen(
      onResult: (val) => onResult(val.recognizedWords, val.finalResult),
      localeId: localeId,
      cancelOnError: false,
      partialResults: true,
      listenMode: stt.ListenMode.dictation,
    );
  }

  /// Stops listening to microphone input.
  Future<void> stopListening() async {
    if (_speech.isListening) {
      await _speech.stop();
    }
  }

  /// Cancels the current speech recognition session.
  Future<void> cancelListening() async {
    if (_speech.isListening) {
      await _speech.cancel();
    }
  }
}
