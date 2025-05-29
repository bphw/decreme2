import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState.initial()) {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      // Get current user using currentUser
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        state = AuthState(
          user: user,
          status: AuthStatus.authenticated,
        );
        print('Auth initialized with user: ${user.email}');
      }

      // Listen to auth state changes
      Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
        final AuthChangeEvent event = data.event;
        final Session? session = data.session;
        print('Auth State Change - Event: $event, Session: ${session != null}');

        switch (event) {
          case AuthChangeEvent.signedIn:
            final user = Supabase.instance.client.auth.currentUser;
            if (user != null) {
              state = AuthState(
                user: user,
                status: AuthStatus.authenticated,
              );
              print('User signed in: ${user.email}');
            }
            break;
          case AuthChangeEvent.signedOut:
            state = AuthState.initial();
            print('User signed out');
            break;
          case AuthChangeEvent.tokenRefreshed:
            final user = Supabase.instance.client.auth.currentUser;
            if (user != null) {
              state = AuthState(
                user: user,
                status: AuthStatus.authenticated,
              );
              print('Token refreshed for user: ${user.email}');
            }
            break;
          default:
            break;
        }
      });
    } catch (e) {
      print('Error initializing auth: $e');
      state = state.copyWith(
        status: AuthStatus.error,
        error: e.toString(),
      );
    }
  }

  Future<void> signIn(String email, String password) async {
    try {
      state = state.copyWith(status: AuthStatus.loading);
      print('Signing in user: $email');
      
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      if (response.session != null) {
        state = AuthState(
          user: response.user,
          status: AuthStatus.authenticated,
        );
        print('Sign in successful: ${response.user?.email}');
      } else {
        state = state.copyWith(
          status: AuthStatus.error,
          error: 'Authentication failed',
        );
        print('Sign in failed: No session returned');
      }
    } catch (e) {
      print('Sign in error: $e');
      state = state.copyWith(
        status: AuthStatus.error,
        error: e.toString(),
      );
    }
  }

  Future<void> signUp(String email, String password) async {
    try {
      state = state.copyWith(status: AuthStatus.loading);
      print('Signing up user: $email');
      
      final response = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
        data: {
          'role': 'customer',
          'created_at': DateTime.now().toIso8601String(),
        },
        emailRedirectTo: 'io.supabase.flutterquickstart://login-callback/',
      );
      
      if (response.user != null) {
        print('Sign up successful: ${response.user?.email}');
        print('Verification email sent. User ID: ${response.user?.id}');
        
        state = state.copyWith(
          status: AuthStatus.initial,
          error: null,
        );
      } else {
        state = state.copyWith(
          status: AuthStatus.error,
          error: 'Registration failed',
        );
        print('Sign up failed: No user returned');
      }
    } catch (e) {
      print('Sign up error: $e');
      state = state.copyWith(
        status: AuthStatus.error,
        error: e.toString(),
      );
    }
  }

  Future<void> signOut() async {
    try {
      print('Signing out user');
      await Supabase.instance.client.auth.signOut();
      state = AuthState.initial();
      print('Sign out successful');
    } catch (e) {
      print('Sign out error: $e');
      state = state.copyWith(
        status: AuthStatus.error,
        error: e.toString(),
      );
    }
  }
}

enum AuthStatus { initial, loading, authenticated, error }

class AuthState {
  final User? user;
  final AuthStatus status;
  final String? error;

  AuthState({
    this.user,
    required this.status,
    this.error,
  });

  factory AuthState.initial() {
    return AuthState(status: AuthStatus.initial);
  }

  AuthState copyWith({
    User? user,
    AuthStatus? status,
    String? error,
  }) {
    return AuthState(
      user: user ?? this.user,
      status: status ?? this.status,
      error: error ?? this.error,
    );
  }
} 