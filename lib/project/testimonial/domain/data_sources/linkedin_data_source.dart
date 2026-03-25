import '../entities/linkedin_profile.dart';
import '../exception/failures.dart';

/// Contract for LinkedIn OAuth data source.
///
/// Handles the raw HTTP interactions with LinkedIn's OAuth 2.0 and
/// OpenID Connect APIs. The repository orchestrates these calls and
/// manages token state.
abstract class ILinkedInDataSource {
  /// Build the OAuth 2.0 authorization URL for user redirect.
  ///
  /// [state] is a CSRF token that should be verified on callback.
  String getAuthorizationUrl({required String state});

  /// Exchange an authorization code for an access token.
  ///
  /// This MUST go through a backend proxy (Cloud Function) because
  /// LinkedIn's token endpoint blocks browser CORS and we must not
  /// expose the client secret client-side.
  Future<Result<String>> exchangeCodeForToken(String authorizationCode);

  /// Fetch the authenticated user's profile from LinkedIn userinfo.
  Future<Result<LinkedInProfile>> getUserProfile(String accessToken);

  /// Get the deep link URL to write a recommendation.
  String getRecommendationUrl();
}
