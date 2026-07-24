import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../data/datasources/local/secure_storage_service.dart';

// --- EVENTS ---
abstract class AuthEvent {
  const AuthEvent();
}

class AppStarted extends AuthEvent {}

class LoginSubmitted extends AuthEvent {
  final String email;
  final String password;
  LoginSubmitted({required this.email, required this.password});
}

class RegisterSubmitted extends AuthEvent {
  final String username;
  final String email;
  final String password;
  RegisterSubmitted({
    required this.username,
    required this.email,
    required this.password,
  });
}

class LogoutRequested extends AuthEvent {}

class GoogleAuthRequested extends AuthEvent {
  final String token;
  GoogleAuthRequested({required this.token});
}

// --- STATES ---
abstract class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class Authenticated extends AuthState {
  final UserProfile user;
  const Authenticated(this.user);
}

class Unauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
}

// --- BLOC ---
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;
  final SecureStorageService _secureStorageService;

  AuthBloc({
    required AuthRepository authRepository,
    required SecureStorageService secureStorageService,
  })  : _authRepository = authRepository,
        _secureStorageService = secureStorageService,
        super(AuthInitial()) {
    on<AppStarted>(_onAppStarted);
    on<LoginSubmitted>(_onLoginSubmitted);
    on<RegisterSubmitted>(_onRegisterSubmitted);
    on<LogoutRequested>(_onLogoutRequested);
    on<GoogleAuthRequested>(_onGoogleAuthRequested);
  }

  Future<void> _onAppStarted(AppStarted event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final token = await _secureStorageService.getAccessToken();
      final refreshToken = await _secureStorageService.getRefreshToken();

      if (token != null && refreshToken != null) {
        // Fetch fresh profile to validate session
        final profile = await _authRepository.getProfile();
        emit(Authenticated(profile));
      } else {
        emit(Unauthenticated());
      }
    } catch (_) {
      await _secureStorageService.clearAll();
      emit(Unauthenticated());
    }
  }

  Future<void> _onLoginSubmitted(LoginSubmitted event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await _authRepository.login(
        email: event.email,
        password: event.password,
      );
      final profile = await _authRepository.getProfile();
      emit(Authenticated(profile));
    } catch (e) {
      emit(AuthError(e.toString().replaceAll('Exception:', '').trim()));
    }
  }

  Future<void> _onRegisterSubmitted(RegisterSubmitted event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await _authRepository.register(
        username: event.username,
        email: event.email,
        password: event.password,
      );
      // Automatically log in after registration
      await _authRepository.login(
        email: event.email,
        password: event.password,
      );
      final profile = await _authRepository.getProfile();
      emit(Authenticated(profile));
    } catch (e) {
      emit(AuthError(e.toString().replaceAll('Exception:', '').trim()));
    }
  }

  Future<void> _onLogoutRequested(LogoutRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    await _authRepository.logout();
    emit(Unauthenticated());
  }

  Future<void> _onGoogleAuthRequested(GoogleAuthRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await _authRepository.googleAuth(token: event.token);
      final profile = await _authRepository.getProfile();
      emit(Authenticated(profile));
    } catch (e) {
      emit(AuthError(e.toString().replaceAll('Exception:', '').trim()));
    }
  }
}
