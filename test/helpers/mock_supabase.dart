import 'package:mockito/mockito.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Mock for Supabase Client
class MockSupabaseClient extends Mock implements SupabaseClient {}

/// Mock for PostgrestClient
class MockPostgrestClient extends Mock implements PostgrestClient {}

/// Mock for GoTrueClient
class MockGoTrueClient extends Mock implements GoTrueClient {}

/// Mock for StorageClient
class MockStorageClient extends Mock implements StorageClient {}

/// Mock for PostgrestFilterBuilder
class MockPostgrestFilterBuilder extends Mock implements PostgrestFilterBuilder {
  // Helper method to create a successful response
  factory MockPostgrestFilterBuilder.withSuccess(List<dynamic> data) {
    final builder = MockPostgrestFilterBuilder();
    when(builder.select('*')).thenReturn(builder);
    when(builder.select(any)).thenReturn(builder);
    when(builder.eq(any, any)).thenReturn(builder);
    when(builder.execute()).thenAnswer((_) async {
      return PostgrestResponse(data: data);
    });
    return builder;
  }

  // Helper method to create an error response
  factory MockPostgrestFilterBuilder.withError(String error) {
    final builder = MockPostgrestFilterBuilder();
    when(builder.select('*')).thenReturn(builder);
    when(builder.select(any)).thenReturn(builder);
    when(builder.eq(any, any)).thenReturn(builder);
    when(builder.execute()).thenThrow(Exception(error));
    return builder;
  }
}

/// Mock for PostgrestResponseBuilder
class MockPostgrestResponseBuilder extends Mock implements PostgrestResponseBuilder {}

/// Mock for Supabase initialization helper
class MockSupabaseConfig {
  static MockSupabaseClient createMockClient() {
    return MockSupabaseClient();
  }

  static void setupMockAuth(MockGoTrueClient authClient, {bool isAuthenticated = true}) {
    if (isAuthenticated) {
      when(authClient.currentSession).thenReturn(
        Session(
          accessToken: 'test_access_token',
          tokenType: 'bearer',
          user: User(
            id: 'test_user_id',
            email: 'test@example.com',
          ),
        ),
      );
      when(authClient.currentUser).thenReturn(
        User(
          id: 'test_user_id',
          email: 'test@example.com',
        ),
      );
    } else {
      when(authClient.currentSession).thenReturn(null);
      when(authClient.currentUser).thenReturn(null);
    }
  }
}

/// Helper class for creating mock responses
class MockResponseHelper {
  /// Create a successful database response
  static PostgrestResponse createSuccessResponse(List<dynamic> data) {
    return PostgrestResponse(data: data);
  }

  /// Create an error response
  static Exception createErrorResponse(String message) {
    return Exception(message);
  }
}
