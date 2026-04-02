import '../../domain/data_sources/cache.dart';
import '../../domain/entities/testimonial.dart';

/// In-memory cache implementation for testimonials.
class TestimonialCache implements ITestimonialCache {
  List<Testimonial>? _cached;
  DateTime? _cachedAt;

  /// Cache validity duration.
  static const _ttl = Duration(minutes: 10);

  @override
  Future<List<Testimonial>?> getCachedTestimonials() async {
    if (_cached == null || _cachedAt == null) return null;
    if (DateTime.now().difference(_cachedAt!) > _ttl) {
      _cached = null;
      _cachedAt = null;
      return null;
    }
    return _cached;
  }

  @override
  Future<void> cacheTestimonials(List<Testimonial> testimonials) async {
    _cached = List.unmodifiable(testimonials);
    _cachedAt = DateTime.now();
  }

  @override
  Future<void> clearCache() async {
    _cached = null;
    _cachedAt = null;
  }
}
