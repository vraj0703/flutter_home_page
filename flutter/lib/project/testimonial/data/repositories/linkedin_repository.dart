import '../../domain/data_sources/linkedin_data_source.dart';
import '../../domain/entities/linkedin_profile.dart';
import '../../domain/exception/failures.dart';
import '../../domain/repositories/linkedin_repository.dart';
import '../data_sources/linkedin_data_source.dart';

/// Production LinkedIn repository backed by [ILinkedInDataSource].
///
/// Manages OAuth state (token, CSRF state) and delegates all network
/// calls to the injected data source.
class ReleaseLinkedInRepository implements ILinkedInRepository {
  final ILinkedInDataSource _dataSource;

  String? _accessToken;

  /// The CSRF state string for the current OAuth flow (if any).
  String? _pendingState;

  ReleaseLinkedInRepository({
    required ILinkedInDataSource dataSource,
  }) : _dataSource = dataSource;

  @override
  String getAuthorizationUrl() {
    _pendingState = LinkedInDataSource.generateState();
    return _dataSource.getAuthorizationUrl(state: _pendingState!);
  }

  @override
  Future<Result<String>> exchangeCodeForToken(
    String authorizationCode,
  ) async {
    final result = await _dataSource.exchangeCodeForToken(authorizationCode);
    result.fold(
      onSuccess: (token) => _accessToken = token,
      onFailure: (_, __) {},
    );
    return result;
  }

  @override
  Future<Result<LinkedInProfile>> getUserProfile(String accessToken) async {
    return _dataSource.getUserProfile(accessToken);
  }

  @override
  String getRecommendationUrl() => _dataSource.getRecommendationUrl();

  @override
  bool get isAuthenticated => _accessToken != null;

  @override
  String? get currentToken => _accessToken;

  /// The CSRF state value sent with the last authorization URL.
  ///
  /// Callers should verify the `state` query parameter from the OAuth
  /// callback matches this value before exchanging the code.
  String? get pendingState => _pendingState;

  @override
  void logout() {
    _accessToken = null;
    _pendingState = null;
  }
}
