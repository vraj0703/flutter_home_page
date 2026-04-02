/// LinkedIn user profile obtained via OAuth.
class LinkedInProfile {
  final String id;
  final String firstName;
  final String lastName;
  final String? headline;
  final String? profilePictureUrl;
  final String? email;
  final String profileUrl;

  const LinkedInProfile({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.headline,
    this.profilePictureUrl,
    this.email,
    required this.profileUrl,
  });

  String get fullName => '$firstName $lastName';

  /// Extract role from headline (e.g. "CTO at TechNova" -> "CTO").
  String get role => headline?.split(' at ').first ?? '';

  /// Extract company from headline (e.g. "CTO at TechNova" -> "TechNova").
  String get company =>
      headline?.contains(' at ') == true ? headline!.split(' at ').last : '';

  LinkedInProfile copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? headline,
    String? profilePictureUrl,
    String? email,
    String? profileUrl,
  }) =>
      LinkedInProfile(
        id: id ?? this.id,
        firstName: firstName ?? this.firstName,
        lastName: lastName ?? this.lastName,
        headline: headline ?? this.headline,
        profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
        email: email ?? this.email,
        profileUrl: profileUrl ?? this.profileUrl,
      );
}
