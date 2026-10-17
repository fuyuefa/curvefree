import 'package:curvefree/app/shell/app_tab.dart';
import 'package:curvefree/app/theme/curve_colors.dart';
import 'package:curvefree/core/constants/app_tokens.dart';
import 'package:flutter/material.dart';

class CurveBottomNav extends StatelessWidget {
  const CurveBottomNav({
    super.key,
    required this.current,
    required this.onSelect,
  });

  final AppTab current;
  final ValueChanged<AppTab> onSelect;

  @override
  Widget build(BuildContext context) {
    final CurveColors colors = CurveColors.of(context);
    return Material(
      color: colors.elevated,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: colors.border)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: AppLayout.bottomNavHeight,
            child: Row(
              children: <Widget>[
                for (final _NavSpec spec in _specs)
                  Expanded(
                    child: _NavItem(
                      spec: spec,
                      selected: spec.tab == current,
                      onTap: () => onSelect(spec.tab),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavSpec {
  const _NavSpec({
    required this.tab,
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.navKey,
  });

  final AppTab tab;
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final Key navKey;
}

const List<_NavSpec> _specs = <_NavSpec>[
  _NavSpec(
    tab: AppTab.today,
    icon: Icons.today_outlined,
    activeIcon: Icons.today,
    label: AppStrings.navToday,
    navKey: Key('nav_today'),
  ),
  _NavSpec(
    tab: AppTab.training,
    icon: Icons.fitness_center_outlined,
    activeIcon: Icons.fitness_center,
    label: AppStrings.training,
    navKey: Key('nav_training'),
  ),
  _NavSpec(
    tab: AppTab.nutrition,
    icon: Icons.restaurant_outlined,
    activeIcon: Icons.restaurant,
    label: AppStrings.nutrition,
    navKey: Key('nav_nutrition'),
  ),
  _NavSpec(
    tab: AppTab.me,
    icon: Icons.person_outline,
    activeIcon: Icons.person,
    label: AppStrings.navMe,
    navKey: Key('nav_me'),
  ),
];

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.spec,
    required this.selected,
    required this.onTap,
  });

  final _NavSpec spec;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final CurveColors colors = CurveColors.of(context);
    final Color color = selected ? colors.primary : colors.textSecondary;
    return Semantics(
      button: true,
      selected: selected,
      label: spec.label,
      child: InkWell(
        key: spec.navKey,
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              width: selected ? AppLayout.navIndicatorWidth : 0,
              height: AppLayout.navIndicatorHeight,
              decoration: BoxDecoration(
                color: selected ? colors.primary : colors.elevated,
                borderRadius: BorderRadius.circular(AppRadii.chip),
              ),
            ),
            const SizedBox(height: AppSpacing.xxs),
            Icon(
              selected ? spec.activeIcon : spec.icon,
              size: AppLayout.iconSize,
              color: color,
            ),
            Text(
              spec.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: color,
                fontFamily: AppFonts.ui,
                fontFamilyFallback: AppFonts.cjkFallback,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
