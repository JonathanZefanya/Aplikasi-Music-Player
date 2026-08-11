import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:music/src/core/responsive/responsive.dart';
import 'package:music/src/core/theme/themes.dart';
import 'package:music/src/presentation/widgets/player_bottom_app_bar.dart';

class AdaptiveDestination {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final Widget page;

  const AdaptiveDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.page,
  });
}

/// Bottom navigation on phones, a navigation rail once the window is wide
/// enough. The mini player always sits directly above the system inset.
class AdaptiveNavScaffold extends StatefulWidget {
  final List<AdaptiveDestination> destinations;
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;

  const AdaptiveNavScaffold({
    super.key,
    required this.destinations,
    required this.currentIndex,
    required this.onDestinationSelected,
  });

  @override
  State<AdaptiveNavScaffold> createState() => _AdaptiveNavScaffoldState();
}

class _AdaptiveNavScaffoldState extends State<AdaptiveNavScaffold> {
  // A page is only built once it has been opened, otherwise every tab would
  // run its queries on startup.
  final Set<int> _visited = {};

  @override
  void initState() {
    super.initState();
    _visited.add(widget.currentIndex);
  }

  @override
  void didUpdateWidget(AdaptiveNavScaffold oldWidget) {
    super.didUpdateWidget(oldWidget);
    _visited.add(widget.currentIndex);
  }

  List<AdaptiveDestination> get destinations => widget.destinations;
  int get currentIndex => widget.currentIndex;
  ValueChanged<int> get onDestinationSelected => widget.onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final bool sideNav = context.usesSideNavigation;

    final Widget body = IndexedStack(
      index: currentIndex,
      children: [
        for (int index = 0; index < destinations.length; index++)
          if (_visited.contains(index))
            destinations[index].page
          else
            const SizedBox.shrink(),
      ],
    );

    return Scaffold(
      extendBody: true,
      backgroundColor: Themes.getTheme().primaryColor,
      body: Ink(
        decoration: Themes.getBackgroundDecoration(),
        child: sideNav
            ? Row(
                children: [
                  _buildRail(context),
                  Expanded(child: body),
                ],
              )
            : body,
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const PlayerBottomAppBar(),
          if (!sideNav) _buildBottomBar(context),
        ],
      ),
    );
  }

  Widget _buildRail(BuildContext context) {
    return SafeArea(
      child: NavigationRail(
        extended: context.isExpanded,
        minExtendedWidth: 180,
        selectedIndex: currentIndex,
        onDestinationSelected: onDestinationSelected,
        labelType: context.isExpanded
            ? NavigationRailLabelType.none
            : NavigationRailLabelType.selected,
        destinations: [
          for (final AdaptiveDestination destination in destinations)
            NavigationRailDestination(
              icon: Icon(destination.icon),
              selectedIcon: Icon(destination.selectedIcon),
              label: Text(destination.label),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    // extendBody lets content scroll underneath, so the bar needs its own
    // opaque-enough surface or the list shows through it.
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          decoration: BoxDecoration(
            color: Themes.getTheme().primaryColor.withOpacity(0.92),
            border: Border(
              top: BorderSide(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.08),
              ),
            ),
          ),
          child: NavigationBar(
            selectedIndex: currentIndex,
            onDestinationSelected: onDestinationSelected,
            destinations: [
              for (final AdaptiveDestination destination in destinations)
                NavigationDestination(
                  icon: Icon(destination.icon),
                  selectedIcon: Icon(destination.selectedIcon),
                  label: destination.label,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
