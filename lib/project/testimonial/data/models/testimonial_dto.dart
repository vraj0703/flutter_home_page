import '../../domain/entities/testimonial.dart';

/// Data transfer object for testimonials.
///
/// Handles serialization to/from JSON and Firestore documents,
/// plus conversion to/from the domain [Testimonial] entity.
class TestimonialDto {
  final String id;
  final String name;
  final String role;
  final String company;
  final String message;
  final String? avatarUrl;
  final String? linkedinUrl;
  final String status;
  final DateTime createdAt;
  final String? linkedinRecommendationId;

  const TestimonialDto({
    required this.id,
    required this.name,
    required this.role,
    required this.company,
    required this.message,
    this.avatarUrl,
    this.linkedinUrl,
    required this.status,
    required this.createdAt,
    this.linkedinRecommendationId,
  });

  // -- JSON / Firestore --

  factory TestimonialDto.fromJson(Map<String, dynamic> json, [String? docId]) {
    return TestimonialDto(
      id: docId ?? json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      role: json['role'] as String? ?? '',
      company: json['company'] as String? ?? '',
      message: json['message'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String?,
      linkedinUrl: json['linkedinUrl'] as String?,
      status: json['status'] as String? ?? 'pending',
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] is DateTime
              ? json['createdAt'] as DateTime
              : DateTime.tryParse(json['createdAt'].toString()) ??
                  DateTime.now())
          : DateTime.now(),
      linkedinRecommendationId:
          json['linkedinRecommendationId'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'role': role,
        'company': company,
        'message': message,
        'avatarUrl': avatarUrl,
        'linkedinUrl': linkedinUrl,
        'status': status,
        'createdAt': createdAt.toIso8601String(),
        'linkedinRecommendationId': linkedinRecommendationId,
      };

  // -- Domain mapping --

  Testimonial toDomain() => Testimonial(
        id: id,
        name: name,
        role: role,
        company: company,
        message: message,
        avatarUrl: avatarUrl,
        linkedinUrl: linkedinUrl,
        status: TestimonialStatus.values.firstWhere(
          (s) => s.name == status,
          orElse: () => TestimonialStatus.pending,
        ),
        createdAt: createdAt,
        linkedinRecommendationId: linkedinRecommendationId,
      );

  factory TestimonialDto.fromDomain(Testimonial entity) => TestimonialDto(
        id: entity.id,
        name: entity.name,
        role: entity.role,
        company: entity.company,
        message: entity.message,
        avatarUrl: entity.avatarUrl,
        linkedinUrl: entity.linkedinUrl,
        status: entity.status.name,
        createdAt: entity.createdAt,
        linkedinRecommendationId: entity.linkedinRecommendationId,
      );
}
