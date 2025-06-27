import 'package:get_it/get_it.dart';
import 'package:mockito/mockito.dart';
import 'package:snapameal/services/auth_service.dart';
import 'package:snapameal/services/demo_data_service.dart';
import 'package:snapameal/services/openai_service.dart';
import 'package:snapameal/services/rag_service.dart';

// Mock classes
class MockAuthService extends Mock implements AuthService {}
class MockDemoDataService extends Mock implements DemoDataService {}
class MockOpenAIService extends Mock implements OpenAIService {}
class MockRAGService extends Mock implements RAGService {}

/// Setup dependency injection for tests with mock services
void setupTestServiceLocator() {
  final GetIt sl = GetIt.instance;
  
  // Reset any existing registrations
  sl.reset();
  
  // Register mock services
  sl.registerLazySingleton<AuthService>(() => MockAuthService());
  sl.registerLazySingleton<DemoDataService>(() => MockDemoDataService());
  sl.registerLazySingleton<OpenAIService>(() => MockOpenAIService());
  sl.registerFactory<RAGService>(() => MockRAGService());
}

/// Setup dependency injection for tests with real services (for integration tests)
void setupRealTestServiceLocator() {
  final GetIt sl = GetIt.instance;
  
  // Reset any existing registrations
  sl.reset();
  
  // Register real services
  sl.registerLazySingleton<AuthService>(() => AuthService());
  sl.registerLazySingleton<DemoDataService>(() => DemoDataService());
  sl.registerLazySingleton<OpenAIService>(() => OpenAIService());
  sl.registerFactory<RAGService>(() => RAGService(sl<OpenAIService>()));
}

/// Clean up dependency injection after tests
void tearDownTestServiceLocator() {
  GetIt.instance.reset();
} 