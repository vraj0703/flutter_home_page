import '../../domain/entities/testimonial.dart';

/// Local seed data fallback.
///
/// Provides hardcoded testimonials for development and offline mode.
class LocalTestimonialDataSource {
  const LocalTestimonialDataSource();

  static final List<Testimonial> _seedData = [
    Testimonial(
      id: 'seed-1',
      name: 'Sarah Chen',
      role: 'Product Manager',
      company: 'Healthify',
      message:
          "Vishal's architectural decisions saved us months of refactoring. "
          "His framework designs are still the backbone of our mobile platform.",
      status: TestimonialStatus.approved,
      createdAt: DateTime(2025, 6, 1),
    ),
    Testimonial(
      id: 'seed-2',
      name: 'James Wilson',
      role: 'Lead Engineer',
      company: 'StartUp Inc',
      message:
          "The zero-hotfix streak speaks for itself. Vishal doesn't just "
          "write code — he engineers reliability.",
      status: TestimonialStatus.approved,
      createdAt: DateTime(2025, 5, 15),
    ),
    Testimonial(
      id: 'seed-3',
      name: 'Alex Rivera',
      role: 'CTO',
      company: 'TechNova',
      message:
          "His ability to see the big picture while handling intricate "
          "details makes him a rare find in mobile development.",
      status: TestimonialStatus.approved,
      createdAt: DateTime(2025, 4, 20),
    ),
    Testimonial(
      id: 'seed-4',
      name: 'Elena Rodriguez',
      role: 'Founder',
      company: 'DesignFlow',
      message:
          "Vishal transformed our release process. The discipline he "
          "brought changed how our entire team ships software.",
      status: TestimonialStatus.approved,
      createdAt: DateTime(2025, 3, 10),
    ),
    Testimonial(
      id: 'seed-5',
      name: 'Priya Patel',
      role: 'Head of Product',
      company: 'EduTech Global',
      message:
          "Working with Vishal taught me what true craftsmanship in code "
          "looks like. Every PR was a learning opportunity.",
      status: TestimonialStatus.approved,
      createdAt: DateTime(2025, 2, 5),
    ),
    Testimonial(
      id: 'seed-6',
      name: 'David Kim',
      role: 'VP Engineering',
      company: 'FinTech Solutions',
      message:
          "His Flutter expertise is world-class, but what sets him apart "
          "is his systems thinking — he designs for the long term.",
      status: TestimonialStatus.approved,
      createdAt: DateTime(2025, 1, 20),
    ),
  ];

  List<Testimonial> getTestimonials() => List.unmodifiable(_seedData);

  Stream<List<Testimonial>> watchTestimonials() => Stream.value(_seedData);
}
