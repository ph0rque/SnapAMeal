import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/fasting_state_provider.dart';
import '../design_system/widgets/fasting_timer_widget.dart';
import '../design_system/widgets/fasting_status_indicators.dart';

/// Navigation wrapper that adapts based on fasting state
class FastingAwareNavigation extends StatelessWidget {
  final Widget child;
  final bool showFloatingTimer;
  final bool adaptiveTheme;

  const FastingAwareNavigation({
    super.key,
    required this.child,
    this.showFloatingTimer = true,
    this.adaptiveTheme = true,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<FastingStateProvider>(
      builder: (context, fastingState, _) {
        return Theme(
          data: adaptiveTheme
              ? _buildAdaptiveTheme(context, fastingState)
              : Theme.of(context),
          child: Stack(
            children: [
              child,

              // Floating fasting timer when active
              if (showFloatingTimer && fastingState.isActiveFasting)
                _buildFloatingTimer(fastingState),

              // Fasting mode overlay indicator
              if (fastingState.fastingModeEnabled)
                _buildFastingModeIndicator(fastingState),
            ],
          ),
        );
      },
    );
  }

  /// Build adaptive theme based on fasting state
  ThemeData _buildAdaptiveTheme(
    BuildContext context,
    FastingStateProvider fastingState,
  ) {
    final baseTheme = Theme.of(context);

    if (!fastingState.fastingModeEnabled) {
      return baseTheme;
    }

    return baseTheme.copyWith(
      primaryColor: fastingState.appThemeColor,
      colorScheme: baseTheme.colorScheme.copyWith(
        primary: fastingState.appThemeColor,
        secondary: fastingState.appThemeColor.withValues(alpha: 0.7),
      ),
      appBarTheme: baseTheme.appBarTheme.copyWith(
        backgroundColor: fastingState.appThemeColor,
        foregroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      floatingActionButtonTheme: baseTheme.floatingActionButtonTheme.copyWith(
        backgroundColor: fastingState.appThemeColor,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: fastingState.appThemeColor,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  /// Build floating fasting timer
  Widget _buildFloatingTimer(FastingStateProvider fastingState) {
    return Positioned(
      top: 100,
      right: 16,
      child: GestureDetector(
        onTap: () {
          // Navigate to full fasting page
        },
        child: FastingColorShift(
          fastingState: fastingState,
          applyToBackground: true,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: fastingState.appThemeColor.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: FastingProgressRing(
              fastingState: fastingState,
              strokeWidth: 3,
              child: FastingTimerWidget(size: 60, showControls: false),
            ),
          ),
        ),
      ),
    );
  }

  /// Build fasting mode indicator
  Widget _buildFastingModeIndicator(FastingStateProvider fastingState) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 2,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              fastingState.appThemeColor.withValues(alpha: 0.8),
              fastingState.appThemeColor,
              fastingState.appThemeColor.withValues(alpha: 0.8),
            ],
          ),
        ),
        child: LinearProgressIndicator(
          value: fastingState.progressPercentage,
          backgroundColor: Colors.transparent,
          valueColor: AlwaysStoppedAnimation<Color>(
            Colors.white.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }
}

/// Fasting-aware app bar that adapts title and actions
class FastingAwareAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final String? title;
  final List<Widget>? actions;
  final bool automaticallyImplyLeading;
  final Widget? leading;

  const FastingAwareAppBar({
    super.key,
    this.title,
    this.actions,
    this.automaticallyImplyLeading = true,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<FastingStateProvider>(
      builder: (context, fastingState, _) {
        return AppBar(
          title: Text(title ?? fastingState.appBarTitle),
          actions: _buildActions(context, fastingState),
          automaticallyImplyLeading: automaticallyImplyLeading,
          leading: leading,
          elevation: fastingState.fastingModeEnabled ? 0 : 4,
          flexibleSpace: fastingState.fastingModeEnabled
              ? _buildFastingAppBarDecoration(fastingState)
              : null,
        );
      },
    );
  }

  /// Build actions with fasting context
  List<Widget> _buildActions(
    BuildContext context,
    FastingStateProvider fastingState,
  ) {
    final List<Widget> adaptedActions = [...(actions ?? [])];

    if (fastingState.isActiveFasting) {
      // Add fasting progress indicator
      adaptedActions.insert(0, _buildFastingProgressAction(fastingState));
    }

    return adaptedActions;
  }

  /// Build fasting progress action
  Widget _buildFastingProgressAction(FastingStateProvider fastingState) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8),
      child: FastingBadge(
        fastingState: fastingState,
        size: 36,
        animate: true,
        showProgress: true,
      ),
    );
  }

  /// Build fasting app bar decoration
  Widget _buildFastingAppBarDecoration(FastingStateProvider fastingState) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            fastingState.appThemeColor,
            fastingState.appThemeColor.withValues(alpha: 0.8),
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}

/// Bottom navigation bar that adapts to fasting mode
class FastingAwareBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<BottomNavigationBarItem> items;

  const FastingAwareBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<FastingStateProvider>(
      builder: (context, fastingState, _) {
        final filteredItems = _filterNavigationItems(items, fastingState);

        return Container(
          decoration: fastingState.fastingModeEnabled
              ? BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: fastingState.appThemeColor,
                      width: 2,
                    ),
                  ),
                )
              : null,
          child: BottomNavigationBar(
            currentIndex: currentIndex,
            onTap: onTap,
            items: filteredItems,
            selectedItemColor: fastingState.fastingModeEnabled
                ? fastingState.appThemeColor
                : null,
            unselectedItemColor: fastingState.fastingModeEnabled
                ? fastingState.appThemeColor.withValues(alpha: 0.6)
                : null,
            type: BottomNavigationBarType.fixed,
          ),
        );
      },
    );
  }

  /// Filter navigation items based on fasting state
  List<BottomNavigationBarItem> _filterNavigationItems(
    List<BottomNavigationBarItem> items,
    FastingStateProvider fastingState,
  ) {
    if (!fastingState.fastingModeEnabled) {
      return items;
    }

    // Filter out items that should be hidden during fasting
    final filteredItems = <BottomNavigationBarItem>[];

    for (int i = 0; i < items.length; i++) {
      final item = items[i];

      // Check if this item should be hidden (based on label or custom logic)
      if (!_shouldHideNavigationItem(item, fastingState)) {
        // Add visual indicators to relevant items
        final enhancedItem = _enhanceNavigationItem(item, fastingState);
        filteredItems.add(enhancedItem);
      }
    }

    return filteredItems;
  }

  /// Enhance navigation item with fasting visual indicators
  BottomNavigationBarItem _enhanceNavigationItem(
    BottomNavigationBarItem item,
    FastingStateProvider fastingState,
  ) {
    final label = item.label?.toLowerCase() ?? '';

    // Add badge to camera/snap tab during fasting
    if ((label.contains('camera') || label.contains('snap')) &&
        fastingState.isActiveFasting) {
      return BottomNavigationBarItem(
        icon: Stack(
          children: [
            item.icon,
            Positioned(
              right: 0,
              top: 0,
              child: FastingBadge(
                fastingState: fastingState,
                size: 12,
                showProgress: false,
                animate: true,
              ),
            ),
          ],
        ),
        label: item.label,
        activeIcon: item.activeIcon,
        backgroundColor: item.backgroundColor,
        tooltip: item.tooltip,
      );
    }

    return item;
  }

  /// Check if navigation item should be hidden
  bool _shouldHideNavigationItem(
    BottomNavigationBarItem item,
    FastingStateProvider fastingState,
  ) {
    // Hide items based on their labels or custom keys
    final label = item.label?.toLowerCase() ?? '';

    return fastingState.hiddenNavigationItems.any(
      (hiddenItem) => label.contains(hiddenItem.toLowerCase()),
    );
  }
}

/// Drawer that adapts to fasting mode
class FastingAwareDrawer extends StatelessWidget {
  final List<Widget> children;
  final String? headerTitle;
  final String? headerSubtitle;

  const FastingAwareDrawer({
    super.key,
    required this.children,
    this.headerTitle,
    this.headerSubtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<FastingStateProvider>(
      builder: (context, fastingState, _) {
        return Drawer(
          child: Column(
            children: [
              _buildDrawerHeader(context, fastingState),

              // Fasting status section
              if (fastingState.isActiveFasting)
                _buildFastingStatusSection(fastingState),

              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: _filterDrawerItems(children, fastingState),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Build drawer header with fasting context
  Widget _buildDrawerHeader(
    BuildContext context,
    FastingStateProvider fastingState,
  ) {
    return DrawerHeader(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            fastingState.appThemeColor,
            fastingState.appThemeColor.withValues(alpha: 0.8),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            headerTitle ?? fastingState.appBarTitle,
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            headerSubtitle ??
                (fastingState.isActiveFasting
                    ? 'Fasting: ${fastingState.fastingTypeDisplay}'
                    : 'Health & Wellness'),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  /// Build fasting status section
  Widget _buildFastingStatusSection(FastingStateProvider fastingState) {
    return FastingColorShift(
      fastingState: fastingState,
      applyToBackground: true,
      child: Container(
        padding: EdgeInsets.all(16),
        margin: EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              fastingState.appThemeColor.withValues(alpha: 0.1),
              fastingState.appThemeColor.withValues(alpha: 0.05),
            ],
          ),
        ),
        child: Row(
          children: [
            FastingBadge(fastingState: fastingState, size: 32, animate: true),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    FastingStatusIndicators.getMotivationalText(
                      fastingState.progressPercentage,
                    ),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: fastingState.appThemeColor,
                    ),
                  ),
                  Text(
                    '${fastingState.elapsedTime.inHours}h ${fastingState.elapsedTime.inMinutes.remainder(60)}m elapsed',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            CircularProgressIndicator(
              value: fastingState.progressPercentage,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                fastingState.appThemeColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Filter drawer items based on fasting state
  List<Widget> _filterDrawerItems(
    List<Widget> items,
    FastingStateProvider fastingState,
  ) {
    if (!fastingState.fastingModeEnabled) {
      return items;
    }

    // Add fasting-specific items and filter out inappropriate ones
    final filteredItems = <Widget>[];

    // Add fasting controls
    filteredItems.add(_buildFastingControlsTile(fastingState));
    filteredItems.add(Divider());

    // Filter existing items
    for (final item in items) {
      if (!_shouldHideDrawerItem(item, fastingState)) {
        filteredItems.add(item);
      }
    }

    return filteredItems;
  }

  /// Build fasting controls tile
  Widget _buildFastingControlsTile(FastingStateProvider fastingState) {
    return ListTile(
      leading: Icon(Icons.settings, color: fastingState.appThemeColor),
      title: Text('Fasting Settings'),
      subtitle: Text('Filter level: ${fastingState.filterSeverity.name}'),
      onTap: () {
        // Navigate to fasting settings
      },
    );
  }

  /// Check if drawer item should be hidden
  bool _shouldHideDrawerItem(Widget item, FastingStateProvider fastingState) {
    // Custom logic to hide drawer items during fasting
    // This would need to be implemented based on your specific drawer items
    return false;
  }
}
