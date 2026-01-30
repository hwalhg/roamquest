import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile.dart';
import '../../core/config/supabase_config.dart';
import '../../core/utils/app_logger.dart';
import 'local_storage_service.dart';

/// Authentication service using Supabase Auth
class AuthService {
  final SupabaseClient _client = SupabaseConfig.client;
  final LocalStorageService _localStorage = LocalStorageService();
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  /// Stream of auth state changes
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  /// Get current user
  User? get currentUser => _client.auth.currentSession?.user;

  /// Get current session
  Session? get currentSession => _client.auth.currentSession;

  /// Check if user is logged in
  bool get isLoggedIn => currentUser != null;

  /// Get current user ID
  String? get currentUserId => currentUser?.id;

  /// Get user's email
  String? get currentUserEmail => currentUser?.email;

  /// ============================================
  /// Email Magic Link Authentication
  /// ============================================

  /// Sign up / Login with magic link (passwordless)
  /// This works for both new and existing users
  Future<bool> signInWithMagicLink(String email) async {
    try {
      AppLogger.info('Sending magic link to: $email');

      // For email magic link, we use OTP
      await _client.auth.signInWithOtp(
        email: email,
        emailRedirectTo: kIsWeb
            ? 'http://localhost:8080/auth/callback'
            : 'roamquest://auth/callback',
      );

      AppLogger.info('Magic link sent successfully');
      return true;
    } catch (e) {
      AppLogger.error('Failed to send magic link', error: e);
      rethrow;
    }
  }

  /// Sign up with email and password (traditional)
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      AppLogger.info('Signing up with email: $email');

      final response = await _client.auth.signUp(
        email: email,
        password: password,
      );

      // Set user ID for data isolation
      if (response.user != null) {
        await _localStorage.setUserId(response.user!.id);
        AppLogger.info('User ID set for data isolation: ${response.user!.id}');
      }

      AppLogger.info('Sign up successful');
      return response;
    } catch (e) {
      AppLogger.error('Sign up failed', error: e);
      rethrow;
    }
  }

  /// Sign in with email and password (traditional)
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      AppLogger.info('Signing in with email: $email');

      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      // Set user ID for data isolation
      if (response.user != null) {
        await _localStorage.setUserId(response.user!.id);
        AppLogger.info('User ID set for data isolation: ${response.user!.id}');
      }

      AppLogger.info('Sign in successful');
      return response;
    } catch (e) {
      AppLogger.error('Sign in failed', error: e);
      rethrow;
    }
  }

  /// ============================================
  /// OAuth Authentication (Apple, Google, etc.)
  /// ============================================

  /// Sign in with Apple
  Future<bool> signInWithApple() async {
    try {
      AppLogger.info('Signing in with Apple');

      await _client.auth.signInWithOAuth(
        OAuthProvider.apple,
        redirectTo: kIsWeb
            ? 'http://localhost:8080/auth/callback'
            : 'roamquest://auth/callback',
      );

      AppLogger.info('Apple sign-in initiated');
      return true;
    } catch (e) {
      AppLogger.error('Apple sign-in failed', error: e);
      rethrow;
    }
  }

  /// Sign in with Google
  Future<bool> signInWithGoogle() async {
    try {
      AppLogger.info('Signing in with Google');

      await _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb
            ? 'http://localhost:8080/auth/callback'
            : 'roamquest://auth/callback',
      );

      AppLogger.info('Google sign-in initiated');
      return true;
    } catch (e) {
      AppLogger.error('Google sign-in failed', error: e);
      rethrow;
    }
  }

  /// ============================================
  /// Profile Management
  /// ============================================

  /// Get current user's profile
  Future<Profile?> getCurrentProfile() async {
    try {
      if (currentUserId == null) return null;

      final response = await _client
          .from('profiles')
          .select()
          .eq('id', currentUserId!)
          .single();

      if (response == null) return null;

      return Profile.fromJson(response);
    } catch (e) {
      AppLogger.error('Failed to get profile', error: e);
      return null;
    }
  }

  /// Get profile by user ID
  Future<Profile?> getProfile(String userId) async {
    try {
      final response = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();

      if (response == null) return null;

      return Profile.fromJson(response);
    } catch (e) {
      AppLogger.error('Failed to get profile', error: e);
      return null;
    }
  }

  /// Update current user's profile
  Future<bool> updateProfile(Map<String, dynamic> data) async {
    try {
      if (currentUserId == null) {
        throw Exception('No user logged in');
      }

      await _client
          .from('profiles')
          .update(data)
          .eq('id', currentUserId!);

      AppLogger.info('Profile updated successfully');
      return true;
    } catch (e) {
      AppLogger.error('Failed to update profile', error: e);
      return false;
    }
  }

  /// Set username for current user
  Future<bool> setUsername(String username) async {
    try {
      // First check if username is available
      final isAvailable = await isUsernameAvailable(username);
      if (!isAvailable) {
        throw Exception('Username already taken');
      }

      return await updateProfile({'username': username});
    } catch (e) {
      AppLogger.error('Failed to set username', error: e);
      return false;
    }
  }

  /// Check if username is available
  Future<bool> isUsernameAvailable(String username) async {
    try {
      final response = await _client.rpc('is_username_available', params: {
        'username': username,
      });

      return response as bool? ?? false;
    } catch (e) {
      AppLogger.error('Failed to check username availability', error: e);
      return false;
    }
  }

  /// Search profiles by username
  Future<List<Profile>> searchProfiles(String query) async {
    try {
      final response = await _client
          .from('profiles')
          .select()
          .ilike('username', '%$query%')
          .limit(10);

      return (response as List)
          .map((json) => Profile.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      AppLogger.error('Failed to search profiles', error: e);
      return [];
    }
  }

  /// ============================================
  /// Session Management
  /// ============================================

  /// Refresh current session
  Future<bool> refreshSession() async {
    try {
      await _client.auth.refreshSession();
      return true;
    } catch (e) {
      AppLogger.error('Failed to refresh session', error: e);
      return false;
    }
  }

  /// Sign out
  Future<bool> signOut() async {
    try {
      // Clear user ID first to stop data access
      await _localStorage.clearUserId();
      AppLogger.info('Cleared user ID for data isolation');

      // Then sign out from Supabase
      await _client.auth.signOut();
      AppLogger.info('Signed out successfully');
      return true;
    } catch (e) {
      AppLogger.error('Sign out failed', error: e);
      return false;
    }
  }

  /// ============================================
  /// Password Management
  /// ============================================

  /// Send password reset email
  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(
        email,
        redirectTo: kIsWeb
            ? 'http://localhost:8080/auth/reset-password'
            : 'roamquest://auth/reset-password',
      );
      return true;
    } catch (e) {
      AppLogger.error('Failed to send reset email', error: e);
      return false;
    }
  }

  /// Update user password
  Future<bool> updatePassword(String newPassword) async {
    try {
      await _client.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      return true;
    } catch (e) {
      AppLogger.error('Failed to update password', error: e);
      return false;
    }
  }
}
