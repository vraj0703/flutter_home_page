import 'data/data_sources/cache.dart';
import 'data/data_sources/local_data_source.dart';
import 'data/data_sources/network.dart';
import 'data/repositories/linkedin_repository.dart';
import 'data/repositories/repository.dart';
import 'domain/data_sources/cache.dart';
import 'domain/data_sources/network.dart';
import 'domain/repositories/linkedin_repository.dart';
import 'domain/repositories/repository.dart';
import 'domain/use_cases/authenticate_linkedin.dart';
import 'domain/use_cases/fetch_testimonials.dart';
import 'domain/use_cases/submit_testimonial.dart';
import 'presentation/bloc/testimonial_bloc.dart';

/// Simple service locator for the testimonial feature.
///
/// No injectable/get_it — just a static factory class.
class TestimonialDI {
  TestimonialDI._();

  // -- Data sources --

  static final ITestimonialCache _cache = TestimonialCache();
  static ITestimonialNetwork _network = TestimonialNetwork();
  static const LocalTestimonialDataSource _localDataSource =
      LocalTestimonialDataSource();

  /// Override the network data source (e.g. with a Firestore implementation).
  static void setNetwork(ITestimonialNetwork network) {
    _network = network;
  }

  // -- Repositories --

  static ILinkedInRepository? _linkedInRepository;

  /// Override the LinkedIn repository.
  static void setLinkedInRepository(ILinkedInRepository repo) {
    _linkedInRepository = repo;
  }

  static ITestimonialRepository get repository =>
      ReleaseTestimonialRepository(
        cache: _cache,
        network: _network,
        localDataSource: _localDataSource,
      );

  static ILinkedInRepository get linkedInRepository =>
      _linkedInRepository ?? ReleaseLinkedInRepository();

  // -- Use cases --

  static FetchTestimonials get fetchTestimonials =>
      FetchTestimonials(repository);

  static SubmitTestimonial get submitTestimonial =>
      SubmitTestimonial(repository);

  static AuthenticateLinkedIn get authenticateLinkedIn =>
      AuthenticateLinkedIn(linkedInRepository);

  // -- BLoC --

  /// Create a fully-wired [TestimonialBloc].
  static TestimonialBloc createBloc() => TestimonialBloc(
        fetchTestimonials: fetchTestimonials,
        submitTestimonial: submitTestimonial,
        authenticateLinkedIn: authenticateLinkedIn,
      );
}
