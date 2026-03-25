import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

import '../../domain/data_sources/linkedin_data_source.dart';
import '../../domain/entities/linkedin_profile.dart';
import '../../domain/exception/failures.dart';
import '../models/linkedin_profile_dto.dart';

/// Concrete LinkedIn OAuth data source.
///
/// - [getAuthorizationUrl] builds the client-side redirect URL.
/// - [exchangeCodeForToken] delegates to a Cloud Function proxy (CORS + secret).
/// - [getUserProfile] calls the LinkedIn userinfo endpoint directly.
/// - [getRecommendationUrl] returns the recommendation deep link.
class LinkedInDataSource implements ILinkedInDataSource {
  /// LinkedIn OAuth client ID.
  final String clientId;

  /// OAuth redirect URI (must match LinkedIn app config exactly).
  final String redirectUri;

  /// OAuth scopes requested.
  final List<String> scopes;

  /// Cloud Function proxy URL for token exchange.
  ///
  /// The proxy receives `{ code, redirect_uri }` and returns `{ access_token }`.
  final String tokenProxyUrl;

  /// LinkedIn vanity slug of the profile owner (for recommendation URL).
  final String profileOwnerVanity;

  /// HTTP client — injectable for testing.
  final http.Client _httpClient;

  LinkedInDataSource({
    required this.clientId,
    required this.redirectUri,
    this.scopes = const ['openid', 'profile', 'email', 'w_member_social'],
    required this.tokenProxyUrl,
    this.profileOwnerVanity = 'vraj0703',
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  // ---------------------------------------------------------------------------
  // Authorization URL (client-side — no CORS issues)
  // ---------------------------------------------------------------------------

  @override
  String getAuthorizationUrl({required String state}) {
    final queryParams = {
      'response_type': 'code',
      'client_id': clientId,
      'redirect_uri': redirectUri,
      'scope': scopes.join(' '),
      'state': state,
    };
    final uri = Uri.https(
      'www.linkedin.com',
      '/oauth/v2/authorization',
      queryParams,
    );
    return uri.toString();
  }

  // ---------------------------------------------------------------------------
  // Token exchange (via Cloud Function proxy)
  // ---------------------------------------------------------------------------

  @override
  Future<Result<String>> exchangeCodeForToken(
    String authorizationCode,
  ) async {
    if (tokenProxyUrl.isEmpty) {
      return const Failure(
        TestimonialFailure.authFailed,
        'Token proxy URL not configured. '
            'Deploy the Cloud Function at '
            'https://us-central1-vishal-raj-space-firebase-home.cloudfunctions.net/linkedinAuth '
            'and provide the URL to LinkedInDataSource.',
      );
    }

    try {
      final response = await _httpClient.post(
        Uri.parse(tokenProxyUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'code': authorizationCode,
          'redirect_uri': redirectUri,
        }),
      );

      if (response.statusCode != 200) {
        return Failure(
          TestimonialFailure.authFailed,
          'Token exchange failed (${response.statusCode}): ${response.body}',
        );
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final accessToken = body['access_token'] as String?;

      if (accessToken == null || accessToken.isEmpty) {
        return const Failure(
          TestimonialFailure.authFailed,
          'Token exchange response missing access_token',
        );
      }

      return Success(accessToken);
    } on Exception catch (e) {
      return Failure(
        TestimonialFailure.networkError,
        'Token exchange network error: $e',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // User profile (direct API call — works client-side with valid token)
  // ---------------------------------------------------------------------------

  @override
  Future<Result<LinkedInProfile>> getUserProfile(String accessToken) async {
    try {
      final response = await _httpClient.get(
        Uri.parse('https://api.linkedin.com/v2/userinfo'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 401) {
        return const Failure(
          TestimonialFailure.authFailed,
          'LinkedIn access token expired or invalid',
        );
      }

      if (response.statusCode != 200) {
        return Failure(
          TestimonialFailure.networkError,
          'LinkedIn userinfo failed (${response.statusCode}): ${response.body}',
        );
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final dto = LinkedInProfileDto.fromJson(json);
      return Success(dto.toDomain());
    } on Exception catch (e) {
      return Failure(
        TestimonialFailure.networkError,
        'LinkedIn userinfo network error: $e',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Recommendation deep link
  // ---------------------------------------------------------------------------

  @override
  String getRecommendationUrl() =>
      'https://www.linkedin.com/in/$profileOwnerVanity/details/recommendations/write/';

  // ---------------------------------------------------------------------------
  // Utility
  // ---------------------------------------------------------------------------

  /// Generate a cryptographically random state string for CSRF protection.
  static String generateState({int length = 32}) {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random.secure();
    return List.generate(length, (_) => chars[random.nextInt(chars.length)])
        .join();
  }
}
