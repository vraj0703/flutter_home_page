import '../entities/linkedin_profile.dart';
import '../exception/failures.dart';

/// Contract for LinkedIn OAuth and profile access.
abstract class ILinkedInRepository {
  /// Get the OAuth authorization URL to redirect user.
  String getAuthorizationUrl();

  /// Exchange authorization code for access token.
  Future<Result<String>> exchangeCodeForToken(String authorizationCode);

  /// Fetch user profile using access token.
  Future<Result<LinkedInProfile>> getUserProfile(String accessToken);

  /// Get the URL to write a recommendation for the portfolio owner.
  String getRecommendationUrl();

  /// Check if user is currently authenticated.
  bool get isAuthenticated;

  /// Current access token (if authenticated).
  String? get currentToken;

  /// Clear stored authentication.
  void logout();
}
