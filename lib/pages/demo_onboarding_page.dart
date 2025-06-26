import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../config/demo_personas.dart';
import '../widgets/demo_mode_indicator.dart';

/// Demo-specific onboarding page highlighting key features for investors
class DemoOnboardingPage extends StatefulWidget {
  const DemoOnboardingPage({super.key});

  @override
  State<DemoOnboardingPage> createState() => _DemoOnboardingPageState();
}

class _DemoOnboardingPageState extends State<DemoOnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  String? _currentPersona;

  @override
  void initState() {
    super.initState();
    _loadCurrentPersona();
  }

  Future<void> _loadCurrentPersona() async {
    final personaId = await AuthService().getCurrentDemoPersonaId();
    setState(() {
      _currentPersona = personaId;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Demo indicator banner
            const DemoBannerIndicator(
              message: 'Welcome to SnapAMeal Demo Experience',
            ),
            
            // Main onboarding content
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                children: _buildOnboardingPages(),
              ),
            ),
            
            // Navigation controls
            _buildNavigationControls(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildOnboardingPages() {
    final persona = _currentPersona != null 
        ? DemoPersonas.getById(_currentPersona!)
        : null;

    return [
      _buildWelcomePage(persona),
      _buildPersonaIntroPage(persona),
      _buildFeaturesOverviewPage(),
      _buildAIShowcasePage(),
      _buildSocialFeaturesPage(),
      _buildGetStartedPage(),
    ];
  }

  Widget _buildWelcomePage(DemoPersona? persona) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.waving_hand,
            size: 80,
            color: Colors.orange,
          ),
          const SizedBox(height: 24),
          const Text(
            'Welcome to SnapAMeal',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'The AI-powered health & fitness social platform',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.science_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 8),
                Text(
                  'Demo Mode Active',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Experience our full feature set with realistic data',
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonaIntroPage(DemoPersona? persona) {
    if (persona == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 60,
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            child: Text(
              persona.displayName[0],
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Meet ${persona.displayName}',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '${persona.age} years old • ${persona.occupation}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          _buildPersonaDetails(persona),
        ],
      ),
    );
  }

  Widget _buildPersonaDetails(DemoPersona persona) {
    final details = _getPersonaDetails(persona);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            details['description']!,
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: (details['highlights'] as List<String>).map((highlight) {
              return Chip(
                label: Text(highlight),
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getPersonaDetails(DemoPersona persona) {
    switch (persona.id) {
      case 'alice':
        return {
          'description': 'Alice is a disciplined freelancer focused on weight loss and energy optimization through intermittent fasting.',
          'highlights': ['14:10 Fasting', 'Social Sharer', 'Goal-Oriented', 'Tech-Savvy'],
        };
      case 'bob':
        return {
          'description': 'Bob is an active retail worker building muscle and strength while maintaining a social fitness lifestyle.',
          'highlights': ['16:8 Fasting', 'Fitness Enthusiast', 'Social Connector', 'Simple Approach'],
        };
      case 'charlie':
        return {
          'description': 'Charlie is a mindful teacher prioritizing overall health and stress reduction with a holistic approach.',
          'highlights': ['5:2 Fasting', 'Privacy-Focused', 'Mindful Eating', 'Vegetarian'],
        };
      default:
        return {
          'description': 'Exploring health and wellness through SnapAMeal.',
          'highlights': ['Health Journey'],
        };
    }
  }

  Widget _buildFeaturesOverviewPage() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const Text(
            'Core Features',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildFeatureCard(
                  Icons.timer_outlined,
                  'Smart Fasting',
                  'AI-powered fasting timers with personalized insights',
                  Colors.blue,
                ),
                _buildFeatureCard(
                  Icons.camera_alt_outlined,
                  'Meal Recognition',
                  'Instant AI meal analysis with nutrition data',
                  Colors.green,
                ),
                _buildFeatureCard(
                  Icons.groups_outlined,
                  'Health Communities',
                  'Connect with like-minded health enthusiasts',
                  Colors.purple,
                ),
                _buildFeatureCard(
                  Icons.psychology_outlined,
                  'AI Insights',
                  'Personalized health recommendations powered by RAG',
                  Colors.orange,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(IconData icon, String title, String description, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 32, color: color),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(fontSize: 12),
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildAIShowcasePage() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const Icon(
            Icons.auto_awesome,
            size: 80,
            color: Colors.amber,
          ),
          const SizedBox(height: 24),
          const Text(
            'AI-Powered Intelligence',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Expanded(
            child: ListView(
              children: [
                _buildAIFeature(
                  'RAG-Enhanced Advice',
                  'Retrieval-Augmented Generation provides personalized health insights based on your unique profile and latest research.',
                  Icons.lightbulb_outline,
                ),
                _buildAIFeature(
                  'Computer Vision',
                  'Advanced meal recognition instantly identifies food, calculates nutrition, and tracks your dietary patterns.',
                  Icons.visibility_outlined,
                ),
                _buildAIFeature(
                  'Predictive Analytics',
                  'AI learns your patterns to predict optimal fasting windows, meal timing, and health outcomes.',
                  Icons.trending_up_outlined,
                ),
                _buildAIFeature(
                  'Natural Language Processing',
                  'Chat naturally with our AI assistant for health questions, meal planning, and motivation.',
                  Icons.chat_bubble_outline,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIFeature(String title, String description, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialFeaturesPage() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const Icon(
            Icons.people_outline,
            size: 80,
            color: Colors.green,
          ),
          const SizedBox(height: 24),
          const Text(
            'Social & Community',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Connect, share, and grow together',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Expanded(
            child: Column(
              children: [
                _buildSocialFeature(
                  'Health Groups',
                  'Join communities focused on specific health goals like intermittent fasting, nutrition, or fitness.',
                  Icons.groups,
                ),
                _buildSocialFeature(
                  'Progress Stories',
                  'Share your journey with photos and milestones. Stories become more permanent based on engagement.',
                  Icons.auto_stories,
                ),
                _buildSocialFeature(
                  'Friend Challenges',
                  'Compete and support each other with shared health challenges and streak tracking.',
                  Icons.emoji_events,
                ),
                _buildSocialFeature(
                  'Smart Matching',
                  'AI suggests friends with similar health goals and complementary journeys.',
                  Icons.person_add,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialFeature(String title, String description, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.green, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGetStartedPage() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.rocket_launch,
            size: 80,
            color: Colors.purple,
          ),
          const SizedBox(height: 24),
          const Text(
            'Ready to Explore!',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Your demo environment is fully populated with realistic data showcasing 30+ days of health tracking.',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Text(
                  'Demo Features Available:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                const Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Chip(label: Text('Fasting History')),
                    Chip(label: Text('Meal Logs')),
                    Chip(label: Text('AI Insights')),
                    Chip(label: Text('Social Groups')),
                    Chip(label: Text('Progress Stories')),
                    Chip(label: Text('Health Challenges')),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            '💡 Tip: Look for the demo indicator throughout the app',
            style: TextStyle(
              fontStyle: FontStyle.italic,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationControls() {
    return Container(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          // Page indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              6,
              (index) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentPage == index
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey[300],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Navigation buttons
          Row(
            children: [
              if (_currentPage > 0)
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      _pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: const Text('Previous'),
                  ),
                ),
              if (_currentPage > 0) const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    if (_currentPage < 5) {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    } else {
                      // Finish onboarding
                      Navigator.of(context).pushReplacementNamed('/home');
                    }
                  },
                  child: Text(_currentPage < 5 ? 'Next' : 'Get Started'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
} 