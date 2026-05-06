import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_home_page/project/app/bloc/menu_drawer_cubit.dart';
import 'package:flutter_home_page/project/app/config/game_layout.dart';
import 'package:flutter_home_page/project/app/config/game_styles.dart';
import 'package:flutter_home_page/project/app/config/menu_features.dart';
import 'package:my_feature_flags/my_feature_flags.dart';
import 'package:url_launcher/url_launcher.dart';

/// Transparent floating drawer (M4 — RAJ-38, RAJ-39).
///
/// Slides in from the right when MenuDrawerCubit emits isOpen=true. Lists
/// `MenuFeatures.all` filtered by the active feature flags. Each entry
/// opens its target URL via url_launcher.
///
/// Renders nothing when closed. The Stack-based open state shows:
///   - a tap-anywhere scrim that closes the drawer
///   - the panel itself (right-aligned, animated translate)
///
/// Reduced-motion: skips the slide and just toggles opacity over 100ms.
class MenuDrawer extends StatelessWidget {
  const MenuDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MenuDrawerCubit, MenuDrawerState>(
      builder: (context, state) {
        // Must use Positioned.fill in both branches: this widget is a child of
        // a Stack that also holds Positioned(menu) and Positioned(arrow). A
        // non-positioned child of size zero (e.g. SizedBox.shrink) collapses
        // the Stack to 0x0 with Clip.hardEdge, which clips the menu+arrow out
        // of view (RAJ-83).
        if (!state.isOpen) {
          return Positioned.fill(
            child: const IgnorePointer(child: SizedBox.shrink()),
          );
        }
        return _OpenDrawer(onClose: () => context.read<MenuDrawerCubit>().dismiss());
      },
    );
  }
}

class _OpenDrawer extends StatefulWidget {
  const _OpenDrawer({required this.onClose});
  final VoidCallback onClose;

  @override
  State<_OpenDrawer> createState() => _OpenDrawerState();
}

class _OpenDrawerState extends State<_OpenDrawer> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final FocusNode _focusNode;
  bool _reducedMotion = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode()..requestFocus();
    _controller = AnimationController(
      vsync: this,
      duration: GameLayout.drawerEnterDuration,
      reverseDuration: GameLayout.drawerExitDuration,
    );
    _controller.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newReduced = MediaQuery.of(context).disableAnimations;
    if (newReduced != _reducedMotion) {
      _reducedMotion = newReduced;
      _controller.duration = newReduced
          ? GameLayout.drawerReducedMotionDuration
          : GameLayout.drawerEnterDuration;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _closeWithAnim() async {
    await _controller.reverse();
    if (mounted) widget.onClose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < GameLayout.drawerMobileBreakpoint;
    final panelWidth = isMobile ? width : GameLayout.drawerWidthDesktop;

    return Positioned.fill(
      child: KeyboardListener(
        focusNode: _focusNode,
        onKeyEvent: (event) {
          if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.escape) {
            _closeWithAnim();
          }
        },
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final t = Curves.easeOutCubic.transform(_controller.value);
            return Stack(
              children: [
                // Scrim
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _closeWithAnim,
                    child: ColoredBox(
                      color: Colors.black.withValues(alpha: GameStyles.scrimAlpha * t),
                    ),
                  ),
                ),
                // Panel
                Positioned(
                  top: 0,
                  bottom: 0,
                  right: 0,
                  width: panelWidth,
                  child: Transform.translate(
                    offset: Offset(_reducedMotion ? 0 : panelWidth * (1 - t), 0),
                    child: Opacity(
                      opacity: _reducedMotion ? t : 1.0,
                      child: _DrawerPanel(onClose: _closeWithAnim),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _DrawerPanel extends StatelessWidget {
  const _DrawerPanel({required this.onClose});
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final visibleFeatures = MenuFeatures.all
        .where((f) => FeatureFlags().isEnabled(f.flagKey))
        .toList();

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: GameStyles.drawerBlurSigma,
          sigmaY: GameStyles.drawerBlurSigma,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: GameStyles.drawerPanelColor.withValues(alpha: GameStyles.drawerBgAlpha),
            border: Border(
              left: BorderSide(
                color: GameStyles.drawerAccentGold.withValues(alpha: GameStyles.drawerBorderAlpha),
                width: 1,
              ),
            ),
          ),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _DrawerHeader(onClose: onClose),
                Expanded(
                  child: visibleFeatures.isEmpty
                      ? const _EmptyState()
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(
                            horizontal: GameLayout.drawerHorizontalPadding,
                            vertical: GameLayout.drawerVerticalPadding,
                          ),
                          itemCount: visibleFeatures.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: GameLayout.drawerEntryGap),
                          itemBuilder: (_, i) => _DrawerEntry(feature: visibleFeatures[i]),
                        ),
                ),
                const _DrawerFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader({required this.onClose});
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: GameLayout.drawerHeaderHeight,
      padding: const EdgeInsets.symmetric(horizontal: GameLayout.drawerHorizontalPadding),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: GameStyles.drawerAccentGold.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Text(
            'MENU',
            style: TextStyle(
              color: GameStyles.drawerAccentGold,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          const Spacer(),
          IconButton(
            tooltip: 'Close',
            icon: Icon(Icons.close, color: GameStyles.drawerTextSoft, size: 20),
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}

class _DrawerEntry extends StatelessWidget {
  const _DrawerEntry({required this.feature});
  final MenuFeature feature;

  Future<void> _open() async {
    final uri = Uri.parse(feature.url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _open,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: GameLayout.drawerEntryHeight,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Icon(feature.icon, color: GameStyles.drawerAccentGold, size: 22),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      feature.label,
                      style: TextStyle(
                        color: GameStyles.drawerTextPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      feature.description,
                      style: TextStyle(
                        color: GameStyles.drawerTextSoft,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.open_in_new,
                color: GameStyles.drawerTextSoft,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          'No features yet.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: GameStyles.drawerTextSoft,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class _DrawerFooter extends StatelessWidget {
  const _DrawerFooter();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: GameLayout.drawerHorizontalPadding,
        vertical: 16,
      ),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: GameStyles.drawerAccentGold.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
      ),
      child: Text(
        'vraj0703',
        style: TextStyle(color: GameStyles.drawerTextSoft, fontSize: 11),
      ),
    );
  }
}
