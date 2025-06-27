import 'package:get_it/get_it.dart';
import '../services/auth_service.dart';
import '../services/demo_data_service.dart';
import '../services/openai_service.dart';
import '../services/rag_service.dart';

final GetIt sl = GetIt.instance;

/// Setup dependency injection container with core services
void setupServiceLocator() {
  if (sl.isRegistered<AuthService>()) return; // prevent double call

  // Core services
  sl.registerLazySingleton<AuthService>(() => AuthService());
  sl.registerLazySingleton<DemoDataService>(() => DemoDataService());
  
  // AI services
  sl.registerLazySingleton<OpenAIService>(() => OpenAIService());
  sl.registerFactory<RAGService>(() => RAGService(sl<OpenAIService>()));
  
  // Note: DemoResetService uses static methods, so no registration needed
  // Note: DemoDataValidator uses static methods, so no registration needed
  // Note: FastingService has complex dependencies, can be registered when needed
}
