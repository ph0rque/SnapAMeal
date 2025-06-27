import 'package:flutter/material.dart';
import 'package:snapameal/design_system/snap_ui.dart';
import 'package:snapameal/models/mission.dart';
import 'package:snapameal/services/mission_service.dart';
import 'package:snapameal/pages/mission_detail_page.dart';
import 'package:snapameal/utils/logger.dart';

class MissionCard extends StatefulWidget {
  const MissionCard({super.key});

  @override
  State<MissionCard> createState() => _MissionCardState();
}

class _MissionCardState extends State<MissionCard> {
  Mission? _currentMission;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentMission();
  }

  Future<void> _loadCurrentMission() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final mission = await MissionService().getCurrentMission();
      
      if (mounted) {
        setState(() {
          _currentMission = mission;
          _isLoading = false;
        });
      }
    } catch (e) {
      Logger.d('Failed to load current mission: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _completeStep(String stepId) async {
    if (_currentMission == null) return;

    try {
      final success = await MissionService().completeStep(_currentMission!.id, stepId);
      if (success) {
        // Reload mission to get updated progress
        await _loadCurrentMission();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnapUI.successSnackBar('Step completed! 🎉'),
          );
        }
      }
    } catch (e) {
      Logger.d('Failed to complete step: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnapUI.errorSnackBar('Failed to complete step'),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingCard();
    }

    if (_currentMission == null) {
      return _buildNoMissionCard();
    }

    return _buildMissionCard();
  }

  Widget _buildLoadingCard() {
    return Container(
      margin: EdgeInsets.all(SnapDimensions.paddingMedium),
      padding: EdgeInsets.all(SnapDimensions.paddingMedium),
      decoration: BoxDecoration(
        color: SnapColors.white,
        borderRadius: BorderRadius.circular(SnapDimensions.radiusM),
        border: Border.all(color: SnapColors.border),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 12),
          Text('Loading your mission...'),
        ],
      ),
    );
  }

  Widget _buildNoMissionCard() {
    return Container(
      margin: EdgeInsets.all(SnapDimensions.paddingMedium),
      padding: EdgeInsets.all(SnapDimensions.paddingMedium),
      decoration: BoxDecoration(
        color: SnapColors.greyBackground,
        borderRadius: BorderRadius.circular(SnapDimensions.radiusM),
        border: Border.all(color: SnapColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.flag_outlined,
                color: SnapColors.textSecondary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'No Active Mission',
                style: SnapTypography.titleLarge.copyWith(
                  color: SnapColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Complete your health profile to get personalized missions!',
            style: SnapTypography.bodyMedium.copyWith(
              color: SnapColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissionCard() {
    final mission = _currentMission!;
    final progress = mission.progressPercentage;
    final nextStep = mission.nextStep;

    return Container(
      margin: EdgeInsets.all(SnapDimensions.paddingMedium),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(SnapDimensions.radiusM),
        gradient: LinearGradient(
          colors: [
            SnapColors.primaryYellow.withValues(alpha: 0.1),
            SnapColors.accentGreen.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: SnapColors.primaryYellow.withValues(alpha: 0.3),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(SnapDimensions.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.flag,
                  color: SnapColors.primaryYellow,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mission.title,
                        style: SnapTypography.titleLarge.copyWith(
                          color: SnapColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${mission.completedStepsCount}/${mission.totalStepsCount} steps completed',
                        style: SnapTypography.bodyMedium.copyWith(
                          color: SnapColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MissionDetailPage(mission: mission),
                    ),
                  ),
                  child: Text(
                    'View All',
                    style: SnapTypography.bodyMedium.copyWith(
                      color: SnapColors.primaryYellow,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Progress bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Progress',
                      style: SnapTypography.bodyMedium.copyWith(
                        color: SnapColors.textSecondary,
                      ),
                    ),
                    Text(
                      '${progress.round()}%',
                      style: SnapTypography.bodyMedium.copyWith(
                        color: SnapColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: progress / 100,
                  backgroundColor: SnapColors.greyLight,
                  valueColor: AlwaysStoppedAnimation<Color>(SnapColors.accentGreen),
                  borderRadius: BorderRadius.circular(SnapDimensions.radiusS),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Next step
            if (nextStep != null) ...[
              Text(
                'Next Step',
                style: SnapTypography.bodyMedium.copyWith(
                  color: SnapColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: EdgeInsets.all(SnapDimensions.paddingMedium),
                decoration: BoxDecoration(
                  color: SnapColors.white,
                  borderRadius: BorderRadius.circular(SnapDimensions.radiusS),
                  border: Border.all(color: SnapColors.border),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nextStep.title,
                            style: SnapTypography.bodyLarge.copyWith(
                              fontWeight: FontWeight.w600,
                              color: SnapColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            nextStep.description,
                            style: SnapTypography.bodyMedium.copyWith(
                              color: SnapColors.textSecondary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () => _completeStep(nextStep.id),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: SnapColors.accentGreen,
                        foregroundColor: SnapColors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(SnapDimensions.radiusS),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: SnapDimensions.paddingMedium,
                          vertical: SnapDimensions.paddingSmall,
                        ),
                      ),
                      child: const Text('Done'),
                    ),
                  ],
                ),
              ),
            ] else if (mission.isCompleted) ...[
              Container(
                padding: EdgeInsets.all(SnapDimensions.paddingMedium),
                decoration: BoxDecoration(
                  color: SnapColors.accentGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(SnapDimensions.radiusS),
                  border: Border.all(color: SnapColors.accentGreen.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: SnapColors.accentGreen,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mission Completed! 🎉',
                            style: SnapTypography.bodyLarge.copyWith(
                              fontWeight: FontWeight.w600,
                              color: SnapColors.accentGreen,
                            ),
                          ),
                          Text(
                            'Great job building healthy habits!',
                            style: SnapTypography.bodyMedium.copyWith(
                              color: SnapColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
} 