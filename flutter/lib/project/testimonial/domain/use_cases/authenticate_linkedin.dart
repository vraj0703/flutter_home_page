import '../entities/linkedin_profile.dart';
import '../exception/failures.dart';
import '../repositories/linkedin_repository.dart';

/// Parameters for LinkedIn authentication.
class AuthenticateLinkedInParams {
  final String authorizationCode;
  const AuthenticateLinkedInParams(this.authorizationCode);
}

/// Use case: authenticate via LinkedIn OAuth and fetch profile.
class AuthenticateLinkedIn {
  final ILinkedInRepository repository;

  const AuthenticateLinkedIn(this.repository);

  /// Get the URL to open for OAuth.
  String getAuthUrl() => repository.getAuthorizationUrl();

  /// Get the LinkedIn recommendation page URL.
  String get recommendationUrl => repository.getRecommendationUrl();

  /// Whether user is currently authenticated.
  bool get isAuthenticated => repository.isAuthenticated;

  /// Clear stored authentication.
  void logout() => repository.logout();

  /// Complete the OAuth flow with the callback code.
  Future<Result<LinkedInProfile>> invoke(
    AuthenticateLinkedInParams params,
  ) async {
    final tokenResult =
        await repository.exchangeCodeForToken(params.authorizationCode);

    if (tokenResult is Failure<String>) {
      return Failure(
        TestimonialFailure.authFailed,
        tokenResult.details,
      );
    }

    final token = (tokenResult as Success<String>).data;
    return repository.getUserProfile(token);
  }
}
