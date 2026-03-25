import '../../../app/models/testimonial_node.dart';

/// Clean domain entity for a testimonial.
class Testimonial {
  final String id;
  final String name;
  final String role;
  final String company;
  final String message;
  final String? avatarUrl;
  final String? linkedinUrl;
  final TestimonialStatus status;
  final DateTime createdAt;
  final String? linkedinRecommendationId;

  const Testimonial({
    required this.id,
    required this.name,
    required this.role,
    required this.company,
    required this.message,
    this.avatarUrl,
    this.linkedinUrl,
    this.status = TestimonialStatus.pending,
    required this.createdAt,
    this.linkedinRecommendationId,
  });

  /// Convert to the existing [TestimonialNode] for UI compatibility.
  TestimonialNode toNode() => TestimonialNode(
        name: name,
        role: '$role, $company',
        company: company,
        quote: message,
        avatarUrl: avatarUrl ?? '',
      );

  Testimonial copyWith({
    String? id,
    String? name,
    String? role,
    String? company,
    String? message,
    String? avatarUrl,
    String? linkedinUrl,
    TestimonialStatus? status,
    DateTime? createdAt,
    String? linkedinRecommendationId,
  }) =>
      Testimonial(
        id: id ?? this.id,
        name: name ?? this.name,
        role: role ?? this.role,
        company: company ?? this.company,
        message: message ?? this.message,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        linkedinUrl: linkedinUrl ?? this.linkedinUrl,
        status: status ?? this.status,
        createdAt: createdAt ?? this.createdAt,
        linkedinRecommendationId:
            linkedinRecommendationId ?? this.linkedinRecommendationId,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Testimonial &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

enum TestimonialStatus { pending, approved, rejected }
