import '../entities/testimonial.dart';
import '../exception/failures.dart';
import '../repositories/repository.dart';

/// Parameters for submitting a testimonial.
class SubmitTestimonialParams {
  final String name;
  final String role;
  final String company;
  final String message;
  final String? avatarUrl;
  final String? linkedinUrl;

  const SubmitTestimonialParams({
    required this.name,
    required this.role,
    required this.company,
    required this.message,
    this.avatarUrl,
    this.linkedinUrl,
  });
}

/// Use case: submit a new testimonial with validation.
class SubmitTestimonial {
  final ITestimonialRepository repository;

  const SubmitTestimonial(this.repository);

  Future<Result<Testimonial>> invoke(SubmitTestimonialParams params) {
    if (params.name.trim().isEmpty) {
      return Future.value(
        const Failure(TestimonialFailure.validationError, 'Name is required'),
      );
    }
    if (params.message.trim().length < 20) {
      return Future.value(
        const Failure(
          TestimonialFailure.validationError,
          'Message must be at least 20 characters',
        ),
      );
    }
    if (params.company.trim().isEmpty) {
      return Future.value(
        const Failure(
          TestimonialFailure.validationError,
          'Company is required',
        ),
      );
    }

    final testimonial = Testimonial(
      id: '',
      name: params.name.trim(),
      role: params.role.trim(),
      company: params.company.trim(),
      message: params.message.trim(),
      avatarUrl: params.avatarUrl,
      linkedinUrl: params.linkedinUrl,
      status: TestimonialStatus.pending,
      createdAt: DateTime.now(),
    );

    return repository.submitTestimonial(testimonial);
  }
}
