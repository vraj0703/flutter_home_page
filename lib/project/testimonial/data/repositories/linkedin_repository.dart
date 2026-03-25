import '../../domain/entities/linkedin_profile.dart';
import '../../domain/exception/failures.dart';
import '../../domain/repositories/linkedin_repository.dart';

/// Production LinkedIn repository.
///
/// TODO: Wire to actual LinkedIn OAuth API when credentials are configured.
class ReleaseLinkedInRepository implements ILinkedInRepository {
  final String profileOwnerVanity;

  String? _accessToken;

  ReleaseLinkedInRepository({
    this.profileOwnerVanity = 'vraj0703',
  });

  @override
  String getAuthorizationUrl() {
    // Stub: returns recommendation page directly.
    return getRecommendationUrl();
  }

  @override
  Future<Result<String>> exchangeCodeForToken(
    String authorizationCode,
  ) async {
    // Stub: LinkedIn OAuth not yet configured.
    return const Failure(
      TestimonialFailure.authFailed,
      'LinkedIn OAuth not configured yet',
    );
  }

  @override
  Future<Result<LinkedInProfile>> getUserProfile(String accessToken) async {
    return const Failure(
      TestimonialFailure.authFailed,
      'LinkedIn OAuth not configured yet',
    );
  }

  @override
  String getRecommendationUrl() =>
      'https://www.linkedin.com/in/$profileOwnerVanity/details/recommendations/write/';

  @override
  bool get isAuthenticated => _accessToken != null;

  @override
  String? get currentToken => _accessToken;

  @override
  void logout() => _accessToken = null;
}
