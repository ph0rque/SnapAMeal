class DemoPersona {
  final String id;
  final String email;
  final String password;
  final String username;
  final String displayName;
  final int age;
  final String occupation;
  final Map<String, dynamic> healthProfile;

  const DemoPersona({
    required this.id,
    required this.email,
    required this.password,
    required this.username,
    required this.displayName,
    required this.age,
    required this.occupation,
    required this.healthProfile,
  });
}

class DemoPersonas {
  static final alice = DemoPersona(
    id: 'alice',
    email: 'alice.demo@snapameal.com',
    password: 'DemoAlice2024!',
    username: 'alice_freelancer',
    displayName: 'Alice',
    age: 34,
    occupation: 'Freelancer',
    healthProfile: const {
      'height': 168, // 5'6" in cm
      'weight': 63.5, // 140 lbs in kg
      'gender': 'female',
      'fastingType': '14:10',
      'calorieTarget': 1600,
      'activityLevel': 'moderate',
      'goals': ['weight_loss', 'energy'],
      'dietaryRestrictions': [],
    },
  );

  static final bob = DemoPersona(
    id: 'bob',
    email: 'bob.demo@snapameal.com',
    password: 'DemoBob2024!',
    username: 'bob_retail',
    displayName: 'Bob',
    age: 25,
    occupation: 'Retail Worker',
    healthProfile: const {
      'height': 178, // 5'10" in cm
      'weight': 81.6, // 180 lbs in kg
      'gender': 'male',
      'fastingType': '16:8',
      'calorieTarget': 1800,
      'activityLevel': 'active',
      'goals': ['muscle_gain', 'strength'],
      'dietaryRestrictions': [],
    },
  );

  static final charlie = DemoPersona(
    id: 'charlie',
    email: 'charlie.demo@snapameal.com',
    password: 'DemoCharlie2024!',
    username: 'charlie_teacher',
    displayName: 'Charlie',
    age: 41,
    occupation: 'Teacher',
    healthProfile: const {
      'height': 163, // 5'4" in cm
      'weight': 72.6, // 160 lbs in kg
      'gender': 'female',
      'fastingType': '5:2',
      'calorieTarget': 1400,
      'activityLevel': 'light',
      'goals': ['weight_loss', 'health'],
      'dietaryRestrictions': ['vegetarian'],
    },
  );

  static final List<DemoPersona> all = [alice, bob, charlie];

  static DemoPersona? getById(String id) {
    try {
      return all.firstWhere((persona) => persona.id == id);
    } catch (e) {
      return null;
    }
  }

  static DemoPersona? getByEmail(String email) {
    try {
      return all.firstWhere((persona) => persona.email == email);
    } catch (e) {
      return null;
    }
  }
}
