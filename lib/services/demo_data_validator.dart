import 'package:cloud_firestore/cloud_firestore.dart';

/// Result of a validation category.
class ValidationCategoryResult {
  final String name;
  final bool success;
  final String? message;

  const ValidationCategoryResult(this.name, this.success, [this.message]);
}

/// Aggregated demo-data integrity validator.
class DemoDataValidator {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _demoPrefix = 'demo_';

  /// Run all validation checks and return list of results.
  static Future<List<ValidationCategoryResult>> validateAll() async {
    final results = <ValidationCategoryResult>[];

    Future<void> run(String name, Future<bool> Function() fn) async {
      try {
        final ok = await fn();
        results.add(ValidationCategoryResult(name, ok));
      } catch (e) {
        results.add(ValidationCategoryResult(name, false, e.toString()));
      }
    }

    await run('Demo Accounts', _validateDemoAccounts);
    await run('Reciprocal Friendships', _validateReciprocalFriendships);
    await run('Group Memberships', _validateGroupMemberships);

    return results;
  }

  // --- Individual validation helpers -------------------------------------

  static Future<bool> _validateDemoAccounts() async {
    // Ensure every user in users collection with isDemo==true has demo_ data.
    final demoUsers = await _firestore
        .collection('users')
        .where('isDemo', isEqualTo: true)
        .get();

    if (demoUsers.docs.isEmpty) return false;

    for (final doc in demoUsers.docs) {
      final hp = await _firestore
          .collection('${_demoPrefix}health_profiles')
          .doc(doc.id)
          .get();
      if (!hp.exists) return false;
    }
    return true;
  }

  static Future<bool> _validateReciprocalFriendships() async {
    final snaps = await _firestore
        .collection('${_demoPrefix}friendships')
        .get();
    for (final doc in snaps.docs) {
      final parts = doc.id.split('_');
      if (parts.length != 2) continue;
      final otherId = '${parts[1]}_${parts[0]}';
      final other = await _firestore
          .collection('${_demoPrefix}friendships')
          .doc(otherId)
          .get();
      if (!other.exists) return false;
    }
    return true;
  }

  static Future<bool> _validateGroupMemberships() async {
    final groups = await _firestore
        .collection('${_demoPrefix}health_groups')
        .get();
    for (final group in groups.docs) {
      final memberCol = _firestore
          .collection('${_demoPrefix}health_groups')
          .doc(group.id)
          .collection('members');
      final members = await memberCol.get();
      final groupData = group.data();
      if (members.docs.length != (groupData['memberCount'] ?? 0)) {
        return false;
      }
    }
    return true;
  }
}
