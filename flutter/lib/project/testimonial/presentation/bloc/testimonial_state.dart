import '../../domain/entities/linkedin_profile.dart';
import '../../domain/entities/testimonial.dart';

/// States for the testimonial BLoC.
sealed class TestimonialState {
  const TestimonialState();
}

/// Initial state before any data is loaded.
class TestimonialInitial extends TestimonialState {
  const TestimonialInitial();
}

/// Loading testimonials from repository.
class TestimonialLoading extends TestimonialState {
  const TestimonialLoading();
}

/// Testimonials loaded successfully.
class TestimonialLoaded extends TestimonialState {
  final List<Testimonial> testimonials;
  final LinkedInProfile? linkedInProfile;
  final bool isSubmitting;
  final String? submissionError;
  final bool submissionSuccess;

  const TestimonialLoaded({
    required this.testimonials,
    this.linkedInProfile,
    this.isSubmitting = false,
    this.submissionError,
    this.submissionSuccess = false,
  });

  TestimonialLoaded copyWith({
    List<Testimonial>? testimonials,
    LinkedInProfile? linkedInProfile,
    bool? isSubmitting,
    String? submissionError,
    bool? submissionSuccess,
  }) =>
      TestimonialLoaded(
        testimonials: testimonials ?? this.testimonials,
        linkedInProfile: linkedInProfile ?? this.linkedInProfile,
        isSubmitting: isSubmitting ?? this.isSubmitting,
        submissionError: submissionError,
        submissionSuccess: submissionSuccess ?? this.submissionSuccess,
      );
}

/// An unrecoverable error loading testimonials.
class TestimonialError extends TestimonialState {
  final String message;
  const TestimonialError(this.message);
}
