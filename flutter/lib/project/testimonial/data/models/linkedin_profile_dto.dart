import '../../domain/entities/linkedin_profile.dart';

/// Data transfer object for LinkedIn profiles.
///
/// Maps from the LinkedIn OpenID Connect userinfo response
/// to the domain [LinkedInProfile] entity.
class LinkedInProfileDto {
  final String sub;
  final String givenName;
  final String familyName;
  final String? headline;
  final String? picture;
  final String? email;

  const LinkedInProfileDto({
    required this.sub,
    required this.givenName,
    required this.familyName,
    this.headline,
    this.picture,
    this.email,
  });

  factory LinkedInProfileDto.fromJson(Map<String, dynamic> json) {
    return LinkedInProfileDto(
      sub: json['sub'] as String? ?? '',
      givenName: json['given_name'] as String? ??
          json['name']?.toString().split(' ').first ??
          '',
      familyName: json['family_name'] as String? ??
          json['name']?.toString().split(' ').last ??
          '',
      headline: json['headline'] as String?,
      picture: json['picture'] as String?,
      email: json['email'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'sub': sub,
        'given_name': givenName,
        'family_name': familyName,
        'headline': headline,
        'picture': picture,
        'email': email,
      };

  LinkedInProfile toDomain() => LinkedInProfile(
        id: sub,
        firstName: givenName,
        lastName: familyName,
        headline: headline,
        profilePictureUrl: picture,
        email: email,
        profileUrl: 'https://www.linkedin.com/in/$sub',
      );
}
