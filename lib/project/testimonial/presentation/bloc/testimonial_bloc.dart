import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/exception/failures.dart';
import '../../domain/use_cases/authenticate_linkedin.dart';
import '../../domain/use_cases/fetch_testimonials.dart';
import '../../domain/use_cases/submit_testimonial.dart';
import 'testimonial_event.dart';
import 'testimonial_state.dart';

class TestimonialBloc extends Bloc<TestimonialEvent, TestimonialState> {
  final FetchTestimonials fetchTestimonials;
  final SubmitTestimonial submitTestimonial;
  final AuthenticateLinkedIn authenticateLinkedIn;

  TestimonialBloc({
    required this.fetchTestimonials,
    required this.submitTestimonial,
    required this.authenticateLinkedIn,
  }) : super(const TestimonialInitial()) {
    on<LoadTestimonials>(_onLoad);
    on<SubmitTestimonialRequested>(_onSubmit);
    on<LinkedInAuthCompleted>(_onLinkedInAuth);
    on<ClearSubmissionFeedback>(_onClearFeedback);
  }

  Future<void> _onLoad(
    LoadTestimonials event,
    Emitter<TestimonialState> emit,
  ) async {
    emit(const TestimonialLoading());

    final result = await fetchTestimonials.invoke();
    result.fold(
      onSuccess: (testimonials) {
        emit(TestimonialLoaded(testimonials: testimonials));
      },
      onFailure: (error, details) {
        emit(TestimonialError(details ?? error.message));
      },
    );
  }

  Future<void> _onSubmit(
    SubmitTestimonialRequested event,
    Emitter<TestimonialState> emit,
  ) async {
    final current = state;
    if (current is! TestimonialLoaded) return;

    emit(current.copyWith(isSubmitting: true, submissionError: null));

    final params = SubmitTestimonialParams(
      name: event.name,
      role: event.role,
      company: event.company,
      message: event.message,
      avatarUrl: event.avatarUrl,
      linkedinUrl: event.linkedinUrl,
    );

    final result = await submitTestimonial.invoke(params);

    switch (result) {
      case Success():
        // Refresh the list after successful submission.
        final refreshed = await fetchTestimonials.invoke();
        switch (refreshed) {
          case Success(:final data):
            emit(TestimonialLoaded(
              testimonials: data,
              linkedInProfile: current.linkedInProfile,
              submissionSuccess: true,
            ));
          case Failure():
            // Submission succeeded but refresh failed — keep old list.
            emit(current.copyWith(
              isSubmitting: false,
              submissionSuccess: true,
            ));
        }
      case Failure(:final error, :final details):
        emit(current.copyWith(
          isSubmitting: false,
          submissionError: details ?? error.message,
        ));
    }
  }

  Future<void> _onLinkedInAuth(
    LinkedInAuthCompleted event,
    Emitter<TestimonialState> emit,
  ) async {
    final current = state;
    if (current is! TestimonialLoaded) return;

    final params = AuthenticateLinkedInParams(event.authorizationCode);
    final result = await authenticateLinkedIn.invoke(params);

    result.fold(
      onSuccess: (profile) {
        emit(current.copyWith(linkedInProfile: profile));
      },
      onFailure: (error, details) {
        emit(current.copyWith(
          submissionError: 'LinkedIn auth failed: ${details ?? error.message}',
        ));
      },
    );
  }

  void _onClearFeedback(
    ClearSubmissionFeedback event,
    Emitter<TestimonialState> emit,
  ) {
    final current = state;
    if (current is! TestimonialLoaded) return;

    emit(current.copyWith(
      submissionError: null,
      submissionSuccess: false,
    ));
  }
}
