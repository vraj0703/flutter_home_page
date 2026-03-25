import '../entities/testimonial.dart';

/// Contract for testimonial cache (in-memory, SharedPreferences, etc.).
abstract class ITestimonialCache {
  /// Retrieve cached testimonials, or null if cache is empty/stale.
  Future<List<Testimonial>?> getCachedTestimonials();

  /// Store testimonials in cache.
  Future<void> cacheTestimonials(List<Testimonial> testimonials);

  /// Invalidate the cache.
  Future<void> clearCache();
}
