import '../../domain/data_sources/cache.dart';
import '../../domain/data_sources/network.dart';
import '../../domain/entities/testimonial.dart';
import '../../domain/exception/failures.dart';
import '../../domain/repositories/repository.dart';
import '../data_sources/local_data_source.dart';
import '../models/testimonial_dto.dart';

/// Production implementation: network -> cache -> local seed fallback.
class ReleaseTestimonialRepository implements ITestimonialRepository {
  final ITestimonialCache cache;
  final ITestimonialNetwork network;
  final LocalTestimonialDataSource localDataSource;

  const ReleaseTestimonialRepository({
    required this.cache,
    required this.network,
    required this.localDataSource,
  });

  @override
  Future<Result<List<Testimonial>>> getApprovedTestimonials() async {
    // 1. Try cache first.
    final cached = await cache.getCachedTestimonials();
    if (cached != null && cached.isNotEmpty) {
      return Success(cached);
    }

    // 2. Try network.
    final networkResult = await network.fetchApprovedTestimonials();
    if (networkResult is Success<List<Testimonial>>) {
      await cache.cacheTestimonials(networkResult.data);
      return networkResult;
    }

    // 3. Fallback to local seed data.
    final local = localDataSource.getTestimonials();
    if (local.isNotEmpty) {
      await cache.cacheTestimonials(local);
      return Success(local);
    }

    return const Failure(TestimonialFailure.fetchFailed);
  }

  @override
  Future<Result<Testimonial>> submitTestimonial(
    Testimonial testimonial,
  ) async {
    final dto = TestimonialDto.fromDomain(testimonial);
    final result = await network.submitTestimonial(dto.toJson());

    if (result is Success<Testimonial>) {
      // Invalidate cache so next fetch includes the new entry.
      await cache.clearCache();
    }

    return result;
  }

  @override
  Stream<List<Testimonial>> watchApprovedTestimonials() {
    // Prefer network stream; if it emits nothing, fall back to local.
    return network.watchApprovedTestimonials().handleError((_) {
      return localDataSource.watchTestimonials();
    });
  }
}
