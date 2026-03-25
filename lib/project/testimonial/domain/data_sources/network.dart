import '../entities/testimonial.dart';
import '../exception/failures.dart';

/// Contract for testimonial network data source (Firestore, REST API, etc.).
abstract class ITestimonialNetwork {
  /// Fetch all approved testimonials from remote.
  Future<Result<List<Testimonial>>> fetchApprovedTestimonials();

  /// Submit a new testimonial to remote.
  Future<Result<Testimonial>> submitTestimonial(Map<String, dynamic> data);

  /// Real-time stream of approved testimonials.
  Stream<List<Testimonial>> watchApprovedTestimonials();
}
