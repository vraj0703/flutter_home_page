/// Events for the testimonial BLoC.
sealed class TestimonialEvent {
  const TestimonialEvent();
}

/// Load (or reload) the approved testimonials list.
class LoadTestimonials extends TestimonialEvent {
  const LoadTestimonials();
}

/// Submit a new testimonial.
class SubmitTestimonialRequested extends TestimonialEvent {
  final String name;
  final String role;
  final String company;
  final String message;
  final String? avatarUrl;
  final String? linkedinUrl;

  const SubmitTestimonialRequested({
    required this.name,
    required this.role,
    required this.company,
    required this.message,
    this.avatarUrl,
    this.linkedinUrl,
  });
}

/// User started LinkedIn OAuth flow.
class LinkedInAuthStarted extends TestimonialEvent {
  const LinkedInAuthStarted();
}

/// User returned from LinkedIn with an authorization code.
class LinkedInAuthCompleted extends TestimonialEvent {
  final String authorizationCode;
  const LinkedInAuthCompleted(this.authorizationCode);
}

/// User cancelled LinkedIn OAuth.
class LinkedInAuthCancelled extends TestimonialEvent {
  const LinkedInAuthCancelled();
}

/// Clear any submission feedback (success/error).
class ClearSubmissionFeedback extends TestimonialEvent {
  const ClearSubmissionFeedback();
}
