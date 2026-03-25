import 'data/data_sources/cache.dart';
import 'data/data_sources/linkedin_data_source.dart';
import 'data/data_sources/local_data_source.dart';
import 'data/data_sources/network.dart';
import 'data/repositories/linkedin_repository.dart';
import 'data/repositories/repository.dart';
import 'domain/data_sources/cache.dart';
import 'domain/data_sources/linkedin_data_source.dart';
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

  /// LinkedIn OAuth data source — configured with client credentials.
  ///
  /// Client ID and proxy URL are provided here; the client secret is
  /// NEVER included client-side — it lives in the Cloud Function only.
  static ILinkedInDataSource _linkedInDataSource = LinkedInDataSource(
    clientId: const String.fromEnvironment(
      'LINKEDIN_CLIENT_ID',
      defaultValue: '86j5ezmctf4mh3',
    ),
    redirectUri: const String.fromEnvironment(
      'LINKEDIN_REDIRECT_URI',
      defaultValue: 'https://www.vishalraj.space/auth/linkedin/callback',
    ),
    tokenProxyUrl: const String.fromEnvironment(
      'LINKEDIN_TOKEN_PROXY_URL',
      defaultValue:
          'https://us-central1-vishal-raj-space-firebase-home.cloudfunctions.net/linkedinAuth',
    ),
  );

  /// Override the network data source (e.g. with a Firestore implementation).
  static void setNetwork(ITestimonialNetwork network) {
    _network = network;
  }

  /// Override the LinkedIn data source (e.g. for testing).
  static void setLinkedInDataSource(ILinkedInDataSource dataSource) {
    _linkedInDataSource = dataSource;
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
      _linkedInRepository ??
      ReleaseLinkedInRepository(dataSource: _linkedInDataSource);

  // -- Use cases --

  static FetchTestimonials get fetchTestimonials =>
      FetchTestimonials(repository);

  static SubmitTestimonial get submitTestimonial =>
      SubmitTestimonial(repository);

  static AuthenticateLinkedIn get authenticateLinkedIn =>
      AuthenticateLinkedIn(linkedInRepository);

  // -- BLoC --

  /// Initialize the DI container.
  ///
  /// Call after [Firebase.initializeApp] in `main.dart`.
  /// Sets the remote data source to Firestore and configures
  /// LinkedIn OAuth with dart-define values.
  static void initialize() {
    _network = TestimonialNetwork();
    // LinkedIn is already configured via const String.fromEnvironment
    // in the static _linkedInDataSource initializer above.
  }

  /// Expose the LinkedIn data source for the bloc to generate auth URLs.
  static ILinkedInDataSource get linkedInDataSource => _linkedInDataSource;

  /// Create a fully-wired [TestimonialBloc].
  static TestimonialBloc createBloc() => TestimonialBloc(
        fetchTestimonials: fetchTestimonials,
        submitTestimonial: submitTestimonial,
        authenticateLinkedIn: authenticateLinkedIn,
        linkedInDataSource: _linkedInDataSource,
      );
}
