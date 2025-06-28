import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/mockito.dart';
import 'package:snapameal/services/auth_service.dart';
import 'package:snapameal/services/demo_data_service.dart';
import 'package:snapameal/services/openai_service.dart';
import 'package:snapameal/services/rag_service.dart';
import 'test_helper.dart';

void main() {
  group('Service Locator Tests', () {
    setUp(() {
      setupTestServiceLocator(); // Use mock services
    });

    tearDown(() {
      tearDownTestServiceLocator();
    });

    test('All core services can be retrieved from DI', () {
      final authService = GetIt.instance<AuthService>();
      final demoDataService = GetIt.instance<DemoDataService>();
      final openAIService = GetIt.instance<OpenAIService>();
      final ragService = GetIt.instance<RAGService>();

      expect(authService, isNotNull);
      expect(authService, isA<MockAuthService>());
      
      expect(demoDataService, isNotNull);
      expect(demoDataService, isA<MockDemoDataService>());
      
      expect(openAIService, isNotNull);
      expect(openAIService, isA<MockOpenAIService>());
      
      expect(ragService, isNotNull);
      expect(ragService, isA<MockRAGService>());
    });

    test('Mock services can be configured for testing', () async {
      final mockAuthService = GetIt.instance<AuthService>() as MockAuthService;
      
      // Configure mock behavior
      when(mockAuthService.getCurrentUser()).thenReturn(null);
      
      // Test the mock
      final user = mockAuthService.getCurrentUser();
      expect(user, isNull);
      
      // Verify the mock was called
      verify(mockAuthService.getCurrentUser()).called(1);
    });

    test('Services are properly isolated between tests', () {
      // This test verifies that services can be retrieved consistently
      final authService1 = GetIt.instance<AuthService>();
      final authService2 = GetIt.instance<AuthService>();
      
      // Should be the same instance (singleton)
      expect(identical(authService1, authService2), isTrue);
      expect(authService1, isA<MockAuthService>());
    });
  });
} 