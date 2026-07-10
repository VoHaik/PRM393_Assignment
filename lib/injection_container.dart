import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'core/constants/env_config.dart';
import 'core/network/dio_client.dart';
import 'core/utils/azure_tts_client.dart';
import 'core/utils/speech_to_text_service.dart';
import 'data/datasources/local/secure_storage_service.dart';
import 'domain/repositories/auth_repository.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'domain/repositories/historical_context_repository.dart';
import 'data/repositories/historical_context_repository_impl.dart';
import 'domain/repositories/character_repository.dart';
import 'data/repositories/character_repository_impl.dart';
import 'domain/repositories/chat_repository.dart';
import 'data/repositories/chat_repository_impl.dart';
import 'domain/repositories/quiz_repository.dart';
import 'data/repositories/quiz_repository_impl.dart';
import 'domain/repositories/payment_repository.dart';
import 'data/repositories/payment_repository_impl.dart';
import 'presentation/auth/auth_bloc.dart';
import 'presentation/chat/chat_bloc.dart';
import 'presentation/quiz/quiz_bloc.dart';
import 'presentation/payment/payment_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // 1. External dependencies
  sl.registerLazySingleton<FlutterSecureStorage>(() => const FlutterSecureStorage());

  // 2. Core local storage
  sl.registerLazySingleton<SecureStorageService>(
    () => SecureStorageService(storage: sl<FlutterSecureStorage>()),
  );

  // 3. Core network clients
  sl.registerLazySingleton<DioClient>(
    () => DioClient(secureStorageService: sl<SecureStorageService>()),
  );
  
  // Register raw Dio instance for repositories
  sl.registerLazySingleton<Dio>(() => sl<DioClient>().dio);

  // 4. Core utilities & services
  sl.registerLazySingleton<SpeechToTextService>(() => SpeechToTextService());

  // Register Azure TTS Client
  sl.registerLazySingleton<AzureTtsClient>(
    () => AzureTtsClient(
      dio: sl(),
      apiKey: EnvConfig.azureSpeechKey,
      region: EnvConfig.azureSpeechRegion,
      voice: EnvConfig.azureSpeechVoice,
    ),
  );

  // 5. Repositories
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(dio: sl(), secureStorageService: sl()),
  );
  sl.registerLazySingleton<HistoricalContextRepository>(
    () => HistoricalContextRepositoryImpl(dio: sl()),
  );
  sl.registerLazySingleton<CharacterRepository>(
    () => CharacterRepositoryImpl(dio: sl()),
  );
  sl.registerLazySingleton<ChatRepository>(
    () => ChatRepositoryImpl(dio: sl()),
  );
  sl.registerLazySingleton<QuizRepository>(
    () => QuizRepositoryImpl(dio: sl()),
  );
  sl.registerLazySingleton<PaymentRepository>(
    () => PaymentRepositoryImpl(dio: sl()),
  );

  // 6. Presentation BLoCs
  sl.registerFactory(() => AuthBloc(authRepository: sl(), secureStorageService: sl()));
  sl.registerFactory(() => ChatBloc(chatRepository: sl(), azureTtsClient: sl(), speechToTextService: sl()));
  sl.registerFactory(() => QuizBloc(quizRepository: sl()));
  sl.registerFactory(() => PaymentBloc(paymentRepository: sl()));
}
