import 'package:flutter/material.dart';
import 'package:snapameal/design_system/snap_ui.dart';
import 'package:snapameal/models/mission.dart';
import 'package:snapameal/services/mission_service.dart';
import 'package:snapameal/utils/logger.dart';

class MissionDetailPage extends StatefulWidget {
  final Mission mission;

  const MissionDetailPage({
    super.key,
    required this.mission,
  });

  @override
  State<MissionDetailPage> createState() => _MissionDetailPageState();
}

class _MissionDetailPageState extends State<MissionDetailPage> {
  late Mission _mission;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _mission = widget.mission;
  }

  Future<void> _completeStep(String stepId) async {
    try {
      setState(() {
        _isLoading = true;
      });

      final success = await MissionService().completeStep(_mission.id, stepId);
      if (success) {
        // Reload mission to get updated progress
        final updatedMission = await MissionService().getCurrentMission();
        if (updatedMission != null && mounted) {
          setState(() {
            _mission = updatedMission;
            _isLoading = false;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnapUI.successSnackBar('Step completed! 🎉'),
          );
        }
      }
    } catch (e) {
      Logger.d('Failed to complete step: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnapUI.errorSnackBar('Failed to complete step'),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mission Details'),
        backgroundColor: SnapColors.primaryYellow,
        foregroundColor: SnapColors.secondaryDark,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(SnapDimensions.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMissionHeader(),
            const SizedBox(height: 24),
            _buildProgressSection(),
            const SizedBox(height: 24),
            _buildStepsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildMissionHeader() {
    return Container(
      padding: EdgeInsets.all(SnapDimensions.paddingLarge),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.flag,
                color: SnapColors.primaryYellow,
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _mission.title,
                  style: SnapTypography.headlineMedium.copyWith(
                    color: SnapColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _mission.description,
            style: SnapTypography.bodyLarge.copyWith(
              color: SnapColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildInfoChip(
                icon: Icons.schedule,
                label: '${_mission.durationDays} days',
                color: SnapColors.accentBlue,
              ),
              const SizedBox(width: 12),
              _buildInfoChip(
                icon: Icons.trending_up,
                label: _mission.difficulty.name.toUpperCase(),
                color: _getDifficultyColor(_mission.difficulty),
              ),
              const SizedBox(width: 12),
              _buildInfoChip(
                icon: Icons.track_changes,
                label: _mission.goalType.replaceAll('_', ' ').toUpperCase(),
                color: SnapColors.accentPurple,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: SnapDimensions.paddingSmall,
        vertical: SnapDimensions.paddingSmall / 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(SnapDimensions.radiusS),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: SnapTypography.bodyMedium.copyWith(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Color _getDifficultyColor(MissionDifficulty difficulty) {
    switch (difficulty) {
      case MissionDifficulty.beginner:
        return SnapColors.accentGreen;
      case MissionDifficulty.intermediate:
        return SnapColors.primaryYellow;
      case MissionDifficulty.advanced:
        return SnapColors.accentRed;
    }
  }

  Widget _buildProgressSection() {
    final progress = _mission.progressPercentage;
    final completedSteps = _mission.completedStepsCount;
    final totalSteps = _mission.totalStepsCount;

    return Container(
      padding: EdgeInsets.all(SnapDimensions.paddingLarge),
      decoration: BoxDecoration(
        color: SnapColors.white,
        borderRadius: BorderRadius.circular(SnapDimensions.radiusM),
        border: Border.all(color: SnapColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Progress Overview',
            style: SnapTypography.titleLarge.copyWith(
              color: SnapColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${progress.round()}% Complete',
                      style: SnapTypography.headlineMedium.copyWith(
                        color: SnapColors.accentGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '$completedSteps of $totalSteps steps completed',
                      style: SnapTypography.bodyMedium.copyWith(
                        color: SnapColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              CircularProgressIndicator(
                value: progress / 100,
                backgroundColor: SnapColors.greyLight,
                valueColor: AlwaysStoppedAnimation<Color>(SnapColors.accentGreen),
                strokeWidth: 6,
              ),
            ],
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: progress / 100,
            backgroundColor: SnapColors.greyLight,
            valueColor: AlwaysStoppedAnimation<Color>(SnapColors.accentGreen),
            borderRadius: BorderRadius.circular(SnapDimensions.radiusS),
            minHeight: 8,
          ),
          if (_mission.isCompleted) ...[
            const SizedBox(height: 16),
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
                    Icons.celebration,
                    color: SnapColors.accentGreen,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Congratulations! You\'ve completed this mission! 🎉',
                      style: SnapTypography.bodyLarge.copyWith(
                        color: SnapColors.accentGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStepsSection() {
    return Container(
      padding: EdgeInsets.all(SnapDimensions.paddingLarge),
      decoration: BoxDecoration(
        color: SnapColors.white,
        borderRadius: BorderRadius.circular(SnapDimensions.radiusM),
        border: Border.all(color: SnapColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mission Steps',
            style: SnapTypography.titleLarge.copyWith(
              color: SnapColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _mission.steps.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final step = _mission.steps[index];
              return _buildStepCard(step, index);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStepCard(MissionStep step, int index) {
    final isCompleted = step.isCompleted;
    final isNext = !isCompleted && _mission.steps.take(index).every((s) => s.isCompleted);

    return Container(
      padding: EdgeInsets.all(SnapDimensions.paddingMedium),
      decoration: BoxDecoration(
        color: isCompleted
            ? SnapColors.accentGreen.withValues(alpha: 0.05)
            : isNext
                ? SnapColors.primaryYellow.withValues(alpha: 0.05)
                : SnapColors.greyBackground,
        borderRadius: BorderRadius.circular(SnapDimensions.radiusS),
        border: Border.all(
          color: isCompleted
              ? SnapColors.accentGreen.withValues(alpha: 0.3)
              : isNext
                  ? SnapColors.primaryYellow.withValues(alpha: 0.3)
                  : SnapColors.border,
        ),
      ),
      child: Row(
        children: [
          // Step number/status
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isCompleted
                  ? SnapColors.accentGreen
                  : isNext
                      ? SnapColors.primaryYellow
                      : SnapColors.greyLight,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: isCompleted
                  ? Icon(
                      Icons.check,
                      color: SnapColors.white,
                      size: 18,
                    )
                  : Text(
                      '${index + 1}',
                      style: SnapTypography.bodyMedium.copyWith(
                        color: isNext ? SnapColors.secondaryDark : SnapColors.textSecondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.title,
                  style: SnapTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isCompleted
                        ? SnapColors.accentGreen
                        : isNext
                            ? SnapColors.textPrimary
                            : SnapColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  step.description,
                  style: SnapTypography.bodyMedium.copyWith(
                    color: SnapColors.textSecondary,
                    height: 1.3,
                  ),
                ),
                if (isCompleted && step.completedAt != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Completed on ${_formatDate(step.completedAt!)}',
                    style: SnapTypography.bodyMedium.copyWith(
                      color: SnapColors.accentGreen,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (isNext && !isCompleted) ...[
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: _isLoading ? null : () => _completeStep(step.id),
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
              child: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Mark Done'),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
} 