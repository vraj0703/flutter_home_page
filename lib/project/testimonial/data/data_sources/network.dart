import '../../domain/data_sources/network.dart';
import '../../domain/entities/testimonial.dart';
import '../../domain/exception/failures.dart';

/// Stub network data source — will be replaced with Firestore implementation.
///
/// TODO: Wire to Firebase Firestore when the project adds cloud_firestore.
class TestimonialNetwork implements ITestimonialNetwork {
  @override
  Future<Result<List<Testimonial>>> fetchApprovedTestimonials() async {
    // Stub: return failure so the repository falls back to local data.
    return const Failure(
      TestimonialFailure.networkError,
      'Firestore not configured yet',
    );
  }

  @override
  Future<Result<Testimonial>> submitTestimonial(
    Map<String, dynamic> data,
  ) async {
    return const Failure(
      TestimonialFailure.networkError,
      'Firestore not configured yet',
    );
  }

  @override
  Stream<List<Testimonial>> watchApprovedTestimonials() {
    // Stub: empty stream — repository will fall back to local data.
    return const Stream.empty();
  }
}
