import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../design_system/snap_ui.dart';
import '../models/privacy_settings.dart';

class AISettingsPage extends StatefulWidget {
  const AISettingsPage({super.key});

  @override
  State<AISettingsPage> createState() => _AISettingsPageState();
}

class _AISettingsPageState extends State<AISettingsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  AIContentPreferences? _preferences;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadUserPreferences();
  }

  Future<void> _loadUserPreferences() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final doc = await _firestore
          .collection('privacy_settings')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final privacySettings = PrivacySettings.fromFirestore(doc);
        setState(() {
          _preferences = privacySettings.aiPreferences;
          _isLoading = false;
        });
      } else {
        // Create default preferences
        setState(() {
          _preferences = AIContentPreferences();
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _preferences = AIContentPreferences();
        _isLoading = false;
      });
    }
  }

  Future<void> _savePreferences() async {
    if (_preferences == null) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Get existing privacy settings or create new ones
      final doc = await _firestore
          .collection('privacy_settings')
          .doc(user.uid)
          .get();

      late PrivacySettings privacySettings;
      if (doc.exists) {
        privacySettings = PrivacySettings.fromFirestore(doc);
        privacySettings = privacySettings.copyWith(
          aiPreferences: _preferences,
          updatedAt: DateTime.now(),
        );
      } else {
        privacySettings = PrivacySettings.defaultSettings(user.uid).copyWith(
          aiPreferences: _preferences,
        );
      }

      await _firestore
          .collection('privacy_settings')
          .doc(user.uid)
          .set(privacySettings.toFirestore());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('AI preferences saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving preferences: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  void _updatePreferences(AIContentPreferences newPreferences) {
    setState(() {
      _preferences = newPreferences;
    });
  }

  void _resetToDefaults() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset to Defaults'),
        content: const Text(
          'Are you sure you want to reset all AI preferences to their default values? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _updatePreferences(AIContentPreferences());
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SnapColors.backgroundPrimary,
      appBar: AppBar(
        title: Text(
          'AI Content Settings',
          style: SnapTextStyles.bodyLarge.copyWith(
            color: SnapColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: SnapColors.backgroundPrimary,
        elevation: 0,
        iconTheme: IconThemeData(color: SnapColors.textPrimary),
        actions: [
          if (!_isLoading && _preferences != null)
            TextButton(
              onPressed: _isSaving ? null : _savePreferences,
              child: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      'Save',
                      style: SnapTextStyles.bodyMedium.copyWith(
                        color: SnapColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _preferences == null
              ? const Center(child: Text('Error loading preferences'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(SnapDimensions.paddingMedium),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildGeneralSettings(),
                      const SizedBox(height: SnapDimensions.spacingLarge),
                      _buildFrequencySettings(),
                      const SizedBox(height: SnapDimensions.spacingLarge),
                      _buildContentTypeSettings(),
                      const SizedBox(height: SnapDimensions.spacingLarge),
                      _buildPersonalizationSettings(),
                      const SizedBox(height: SnapDimensions.spacingLarge),
                      _buildSocialFeatureSettings(),
                      const SizedBox(height: SnapDimensions.spacingLarge),
                      _buildReviewSettings(),
                      const SizedBox(height: SnapDimensions.spacingLarge),
                      _buildSafetySettings(),
                      const SizedBox(height: SnapDimensions.spacingLarge),
                      _buildActionButtons(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildGeneralSettings() {
    return _buildSection(
      title: 'General AI Settings',
      children: [
        SwitchListTile(
          title: Text(
            'Enable AI Content',
            style: SnapTextStyles.bodyMedium.copyWith(
              color: SnapColors.textPrimary,
            ),
          ),
          subtitle: Text(
            'Turn on/off all AI-generated content in the app',
            style: SnapTextStyles.bodySmall.copyWith(
              color: SnapColors.textSecondary,
            ),
          ),
          value: _preferences!.enableAIContent,
          onChanged: (value) {
            _updatePreferences(_preferences!.copyWith(enableAIContent: value));
          },
          activeColor: SnapColors.primary,
        ),
        SwitchListTile(
          title: Text(
            'Use Personalized Content',
            style: SnapTextStyles.bodyMedium.copyWith(
              color: SnapColors.textPrimary,
            ),
          ),
          subtitle: Text(
            'Customize content based on your goals and preferences',
            style: SnapTextStyles.bodySmall.copyWith(
              color: SnapColors.textSecondary,
            ),
          ),
          value: _preferences!.usePersonalizedContent,
          onChanged: _preferences!.enableAIContent
              ? (value) {
                  _updatePreferences(
                      _preferences!.copyWith(usePersonalizedContent: value));
                }
              : null,
          activeColor: SnapColors.primary,
        ),
      ],
    );
  }

  Widget _buildFrequencySettings() {
    return _buildSection(
      title: 'Content Frequency',
      children: [
        _buildFrequencyTile(
          title: 'Daily Insights',
          subtitle: 'How often to show daily wellness insights',
          value: _preferences!.dailyInsightFrequency,
          onChanged: (value) {
            _updatePreferences(
                _preferences!.copyWith(dailyInsightFrequency: value));
          },
        ),
        _buildFrequencyTile(
          title: 'Meal Insights',
          subtitle: 'How often to show insights after logging meals',
          value: _preferences!.mealInsightFrequency,
          onChanged: (value) {
            _updatePreferences(
                _preferences!.copyWith(mealInsightFrequency: value));
          },
        ),
        _buildFrequencyTile(
          title: 'Feed Content',
          subtitle: 'How often to show AI content in your social feed',
          value: _preferences!.feedContentFrequency,
          onChanged: (value) {
            _updatePreferences(
                _preferences!.copyWith(feedContentFrequency: value));
          },
        ),
      ],
    );
  }

  Widget _buildFrequencyTile({
    required String title,
    required String subtitle,
    required AIContentFrequency value,
    required Function(AIContentFrequency) onChanged,
  }) {
    return ListTile(
      title: Text(
        title,
        style: SnapTextStyles.bodyMedium.copyWith(
          color: SnapColors.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: SnapTextStyles.bodySmall.copyWith(
          color: SnapColors.textSecondary,
        ),
      ),
      trailing: DropdownButton<AIContentFrequency>(
        value: value,
        onChanged: _preferences!.enableAIContent
            ? (newValue) {
                if (newValue != null) onChanged(newValue);
              }
            : null,
        items: AIContentFrequency.values.map((frequency) {
          return DropdownMenuItem(
            value: frequency,
            child: Text(
              frequency.displayName,
              style: SnapTextStyles.bodySmall,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildContentTypeSettings() {
    return _buildSection(
      title: 'Content Types',
      children: [
        Text(
          'Choose which types of AI content you want to see',
          style: SnapTextStyles.bodySmall.copyWith(
            color: SnapColors.textSecondary,
          ),
        ),
        const SizedBox(height: SnapDimensions.spacingSmall),
        ..._preferences!.contentTypePreferences.entries.map((entry) {
          return SwitchListTile(
            title: Text(
              entry.key.toUpperCase(),
              style: SnapTextStyles.bodyMedium.copyWith(
                color: SnapColors.textPrimary,
              ),
            ),
            value: entry.value,
            onChanged: _preferences!.enableAIContent
                ? (value) {
                    final newPrefs = Map<String, bool>.from(
                        _preferences!.contentTypePreferences);
                    newPrefs[entry.key] = value;
                    _updatePreferences(
                        _preferences!.copyWith(contentTypePreferences: newPrefs));
                  }
                : null,
            activeColor: SnapColors.primary,
          );
        }),
      ],
    );
  }

  Widget _buildPersonalizationSettings() {
    return _buildSection(
      title: 'Personalization',
      children: [
        SwitchListTile(
          title: Text(
            'Goal-Based Content',
            style: SnapTextStyles.bodyMedium.copyWith(
              color: SnapColors.textPrimary,
            ),
          ),
          subtitle: Text(
            'Show content based on your health goals',
            style: SnapTextStyles.bodySmall.copyWith(
              color: SnapColors.textSecondary,
            ),
          ),
          value: _preferences!.allowGoalBasedContent,
          onChanged: _preferences!.enableAIContent && _preferences!.usePersonalizedContent
              ? (value) {
                  _updatePreferences(
                      _preferences!.copyWith(allowGoalBasedContent: value));
                }
              : null,
          activeColor: SnapColors.primary,
        ),
        SwitchListTile(
          title: Text(
            'Dietary Content',
            style: SnapTextStyles.bodyMedium.copyWith(
              color: SnapColors.textPrimary,
            ),
          ),
          subtitle: Text(
            'Show content based on your dietary preferences',
            style: SnapTextStyles.bodySmall.copyWith(
              color: SnapColors.textSecondary,
            ),
          ),
          value: _preferences!.allowDietaryContent,
          onChanged: _preferences!.enableAIContent && _preferences!.usePersonalizedContent
              ? (value) {
                  _updatePreferences(
                      _preferences!.copyWith(allowDietaryContent: value));
                }
              : null,
          activeColor: SnapColors.primary,
        ),
        SwitchListTile(
          title: Text(
            'Fitness Content',
            style: SnapTextStyles.bodyMedium.copyWith(
              color: SnapColors.textPrimary,
            ),
          ),
          subtitle: Text(
            'Show content based on your fitness activities',
            style: SnapTextStyles.bodySmall.copyWith(
              color: SnapColors.textSecondary,
            ),
          ),
          value: _preferences!.allowFitnessContent,
          onChanged: _preferences!.enableAIContent && _preferences!.usePersonalizedContent
              ? (value) {
                  _updatePreferences(
                      _preferences!.copyWith(allowFitnessContent: value));
                }
              : null,
          activeColor: SnapColors.primary,
        ),
      ],
    );
  }

  Widget _buildSocialFeatureSettings() {
    return _buildSection(
      title: 'Social AI Features',
      children: [
        SwitchListTile(
          title: Text(
            'Conversation Starters',
            style: SnapTextStyles.bodyMedium.copyWith(
              color: SnapColors.textPrimary,
            ),
          ),
          subtitle: Text(
            'AI-generated discussion topics in groups',
            style: SnapTextStyles.bodySmall.copyWith(
              color: SnapColors.textSecondary,
            ),
          ),
          value: _preferences!.enableConversationStarters,
          onChanged: _preferences!.enableAIContent
              ? (value) {
                  _updatePreferences(
                      _preferences!.copyWith(enableConversationStarters: value));
                }
              : null,
          activeColor: SnapColors.primary,
        ),
        SwitchListTile(
          title: Text(
            'Friend Matching AI',
            style: SnapTextStyles.bodyMedium.copyWith(
              color: SnapColors.textPrimary,
            ),
          ),
          subtitle: Text(
            'AI explanations for friend suggestions',
            style: SnapTextStyles.bodySmall.copyWith(
              color: SnapColors.textSecondary,
            ),
          ),
          value: _preferences!.enableFriendMatchingAI,
          onChanged: _preferences!.enableAIContent
              ? (value) {
                  _updatePreferences(
                      _preferences!.copyWith(enableFriendMatchingAI: value));
                }
              : null,
          activeColor: SnapColors.primary,
        ),
        SwitchListTile(
          title: Text(
            'AI in Groups',
            style: SnapTextStyles.bodyMedium.copyWith(
              color: SnapColors.textPrimary,
            ),
          ),
          subtitle: Text(
            'Allow AI features in community groups',
            style: SnapTextStyles.bodySmall.copyWith(
              color: SnapColors.textSecondary,
            ),
          ),
          value: _preferences!.allowAIInGroups,
          onChanged: _preferences!.enableAIContent
              ? (value) {
                  _updatePreferences(
                      _preferences!.copyWith(allowAIInGroups: value));
                }
              : null,
          activeColor: SnapColors.primary,
        ),
      ],
    );
  }

  Widget _buildReviewSettings() {
    return _buildSection(
      title: 'Reviews & Insights',
      children: [
        SwitchListTile(
          title: Text(
            'Weekly Reviews',
            style: SnapTextStyles.bodyMedium.copyWith(
              color: SnapColors.textPrimary,
            ),
          ),
          subtitle: Text(
            'AI-generated weekly progress summaries',
            style: SnapTextStyles.bodySmall.copyWith(
              color: SnapColors.textSecondary,
            ),
          ),
          value: _preferences!.enableWeeklyReviews,
          onChanged: _preferences!.enableAIContent
              ? (value) {
                  _updatePreferences(
                      _preferences!.copyWith(enableWeeklyReviews: value));
                }
              : null,
          activeColor: SnapColors.primary,
        ),
        SwitchListTile(
          title: Text(
            'Monthly Reviews',
            style: SnapTextStyles.bodyMedium.copyWith(
              color: SnapColors.textPrimary,
            ),
          ),
          subtitle: Text(
            'AI-generated monthly progress summaries',
            style: SnapTextStyles.bodySmall.copyWith(
              color: SnapColors.textSecondary,
            ),
          ),
          value: _preferences!.enableMonthlyReviews,
          onChanged: _preferences!.enableAIContent
              ? (value) {
                  _updatePreferences(
                      _preferences!.copyWith(enableMonthlyReviews: value));
                }
              : null,
          activeColor: SnapColors.primary,
        ),
        SwitchListTile(
          title: Text(
            'Goal Tracking',
            style: SnapTextStyles.bodyMedium.copyWith(
              color: SnapColors.textPrimary,
            ),
          ),
          subtitle: Text(
            'AI insights about your goal progress',
            style: SnapTextStyles.bodySmall.copyWith(
              color: SnapColors.textSecondary,
            ),
          ),
          value: _preferences!.enableGoalTracking,
          onChanged: _preferences!.enableAIContent
              ? (value) {
                  _updatePreferences(
                      _preferences!.copyWith(enableGoalTracking: value));
                }
              : null,
          activeColor: SnapColors.primary,
        ),
      ],
    );
  }

  Widget _buildSafetySettings() {
    return _buildSection(
      title: 'Safety & Reporting',
      children: [
        SwitchListTile(
          title: Text(
            'Report Inappropriate Content',
            style: SnapTextStyles.bodyMedium.copyWith(
              color: SnapColors.textPrimary,
            ),
          ),
          subtitle: Text(
            'Enable reporting of inappropriate AI content',
            style: SnapTextStyles.bodySmall.copyWith(
              color: SnapColors.textSecondary,
            ),
          ),
          value: _preferences!.reportInappropriateContent,
          onChanged: (value) {
            _updatePreferences(
                _preferences!.copyWith(reportInappropriateContent: value));
          },
          activeColor: SnapColors.primary,
        ),
        ListTile(
          title: Text(
            'Blocked Keywords',
            style: SnapTextStyles.bodyMedium.copyWith(
              color: SnapColors.textPrimary,
            ),
          ),
          subtitle: Text(
            '${_preferences!.blockedKeywords.length} keywords blocked',
            style: SnapTextStyles.bodySmall.copyWith(
              color: SnapColors.textSecondary,
            ),
          ),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {
            // TODO: Implement blocked keywords management
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Blocked keywords management coming soon'),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isSaving ? null : _savePreferences,
            style: ElevatedButton.styleFrom(
              backgroundColor: SnapColors.primary,
              padding: const EdgeInsets.symmetric(vertical: SnapDimensions.paddingMedium),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(SnapDimensions.radiusMedium),
              ),
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    'Save Preferences',
                    style: SnapTextStyles.bodyMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: SnapDimensions.spacingMedium),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _resetToDefaults,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: SnapColors.textSecondary),
              padding: const EdgeInsets.symmetric(vertical: SnapDimensions.paddingMedium),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(SnapDimensions.radiusMedium),
              ),
            ),
            child: Text(
              'Reset to Defaults',
              style: SnapTextStyles.bodyMedium.copyWith(
                color: SnapColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: SnapColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(SnapDimensions.radiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(SnapDimensions.paddingMedium),
            child: Text(
              title,
              style: SnapTextStyles.bodyLarge.copyWith(
                color: SnapColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }
} 