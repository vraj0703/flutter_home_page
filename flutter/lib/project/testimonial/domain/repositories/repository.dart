import '../entities/testimonial.dart';
import '../exception/failures.dart';

/// Contract for testimonial data access.
abstract class ITestimonialRepository {
  /// Fetch all approved testimonials.
  Future<Result<List<Testimonial>>> getApprovedTestimonials();

  /// Submit a new testimonial (status = pending).
  Future<Result<Testimonial>> submitTestimonial(Testimonial testimonial);

  /// Stream of approved testimonials (real-time updates).
  Stream<List<Testimonial>> watchApprovedTestimonials();
}
