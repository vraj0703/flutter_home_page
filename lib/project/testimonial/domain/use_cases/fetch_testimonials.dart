import '../entities/testimonial.dart';
import '../exception/failures.dart';
import '../repositories/repository.dart';

/// Use case: fetch approved testimonials.
class FetchTestimonials {
  final ITestimonialRepository repository;

  const FetchTestimonials(this.repository);

  Future<Result<List<Testimonial>>> invoke() =>
      repository.getApprovedTestimonials();

  Stream<List<Testimonial>> watch() => repository.watchApprovedTestimonials();
}
