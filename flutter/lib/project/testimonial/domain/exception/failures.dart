/// Testimonial feature failure types and Result wrapper.
///
/// Uses a simple sealed class instead of dart_either or freezed
/// to keep dependencies minimal.
enum TestimonialFailure {
  fetchFailed,
  submitFailed,
  authFailed,
  validationError,
  networkError,
  unknown;

  String get message => switch (this) {
        TestimonialFailure.fetchFailed => 'Failed to load testimonials',
        TestimonialFailure.submitFailed => 'Failed to submit testimonial',
        TestimonialFailure.authFailed => 'LinkedIn authentication failed',
        TestimonialFailure.validationError => 'Invalid testimonial data',
        TestimonialFailure.networkError => 'Network error',
        TestimonialFailure.unknown => 'An unknown error occurred',
      };
}

/// A simple Result type — Success or Failure.
sealed class Result<T> {
  const Result();

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failure<T>;

  /// Fold the result into a single value.
  R fold<R>({
    required R Function(T data) onSuccess,
    required R Function(TestimonialFailure error, String? details) onFailure,
  }) =>
      switch (this) {
        Success<T>(:final data) => onSuccess(data),
        Failure<T>(:final error, :final details) => onFailure(error, details),
      };
}

class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
}

class Failure<T> extends Result<T> {
  final TestimonialFailure error;
  final String? details;
  const Failure(this.error, [this.details]);
}
