import 'package:get_it/get_it.dart';
import '../services/auth_service.dart';
import '../services/demo_data_service.dart';
import '../services/openai_service.dart';
import '../services/rag_service.dart';
import '../services/friend_service.dart';
import '../services/health_community_service.dart';
import '../services/weekly_review_service.dart';
import '../services/ai_preference_service.dart';
import '../services/in_app_notification_service.dart';
import '../services/meal_recognition_service.dart';

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
  sl.registerLazySingleton<MealRecognitionService>(() => MealRecognitionService(sl<OpenAIService>(), sl<RAGService>()));
  sl.registerLazySingleton<AIPreferenceService>(() => AIPreferenceService());
  
  // Social services
  sl.registerLazySingleton<FriendService>(() => FriendService(ragService: sl<RAGService>()));
  sl.registerLazySingleton<HealthCommunityService>(() => HealthCommunityService(sl<RAGService>(), sl<FriendService>()));
  
  // Notification services
  sl.registerLazySingleton<InAppNotificationService>(() => InAppNotificationService());
  
  // Review services
  sl.registerLazySingleton<WeeklyReviewService>(() => WeeklyReviewService(ragService: sl<RAGService>()));
  
  // Note: DemoResetService uses static methods, so no registration needed
  // Note: DemoDataValidator uses static methods, so no registration needed
  // Note: FastingService has complex dependencies, can be registered when needed
}
