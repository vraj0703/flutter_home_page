import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_home_page/project/app/bloc/menu_drawer_cubit.dart';
import 'package:flutter_home_page/project/app/config/menu_features.dart';
import 'package:flutter_home_page/project/app/views/widgets/menu_drawer.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_feature_flags/my_feature_flags.dart';

/// Smoke tests for the M4 menu drawer (RAJ-38, RAJ-39, RAJ-40).
///
/// Manual end-to-end (live website → drawer → article) is the load-bearing
/// verification path per RAJ-40's AC; these tests cover the cubit and the
/// flag-filtered rendering at the widget level.
void main() {
  group('MenuDrawerCubit', () {
    test('starts closed', () {
      final cubit = MenuDrawerCubit();
      expect(cubit.state.isOpen, isFalse);
      cubit.close();
    });

    test('open → dismiss → toggle behave correctly', () {
      final cubit = MenuDrawerCubit();
      expect(cubit.state.isOpen, isFalse);

      cubit.open();
      expect(cubit.state.isOpen, isTrue);

      cubit.dismiss();
      expect(cubit.state.isOpen, isFalse);

      cubit.toggle();
      expect(cubit.state.isOpen, isTrue);

      cubit.toggle();
      expect(cubit.state.isOpen, isFalse);

      cubit.close();
    });
  });

  group('MenuFeatures config', () {
    test('contains the mind_article entry as the first feature', () {
      expect(MenuFeatures.all, isNotEmpty);
      expect(MenuFeatures.all.first.flagKey, 'feature.mind_article.enabled');
      expect(MenuFeatures.all.first.url, 'https://vishalraj.space/articles/ai-mind-deep-dive');
    });

    test('default flag map covers every feature key', () {
      for (final feature in MenuFeatures.all) {
        expect(
          MenuFeatures.defaultFlags.containsKey(feature.flagKey),
          isTrue,
          reason: 'Default missing for ${feature.flagKey}',
        );
      }
    });
  });

  group('MenuDrawer widget', () {
    Widget _wrap(MenuDrawerCubit cubit) => MaterialApp(
          home: BlocProvider.value(
            value: cubit,
            child: const Scaffold(body: Stack(children: [MenuDrawer()])),
          ),
        );

    testWidgets('renders nothing when closed', (tester) async {
      final cubit = MenuDrawerCubit();
      await tester.pumpWidget(_wrap(cubit));
      // No drawer chrome should be visible
      expect(find.text('MENU'), findsNothing);
      cubit.close();
    });

    testWidgets(
      'closed-state does not collapse parent Stack with Positioned siblings (RAJ-83)',
      (tester) async {
        // Repro: HomeOverlay places `Positioned(menu)`, `Positioned(arrow)` and
        // `MenuDrawer()` in the same Stack. If MenuDrawer returns a non-positioned
        // SizedBox.shrink when closed, the Stack sizes itself to that 0x0 child
        // (StackFit.loose) and Clip.hardEdge clips the Positioned children out
        // of view. Regression test: verify a Positioned sibling is laid out at
        // its declared offset — this only holds when the Stack is full-screen.
        const siblingKey = ValueKey('positioned-sibling');
        final cubit = MenuDrawerCubit();
        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider.value(
              value: cubit,
              child: Scaffold(
                body: Stack(
                  children: const [
                    Positioned(
                      top: 40,
                      right: 40,
                      child: SizedBox(
                        key: siblingKey,
                        width: 50,
                        height: 50,
                      ),
                    ),
                    MenuDrawer(),
                  ],
                ),
              ),
            ),
          ),
        );

        final size = tester.getSize(find.byKey(siblingKey));
        expect(size, const Size(50, 50),
            reason: 'sibling should be its declared 50x50 — if it is 0x0 the '
                'Stack collapsed and clipped it.');
        final topLeft = tester.getTopLeft(find.byKey(siblingKey));
        expect(topLeft.dy, 40.0,
            reason: 'sibling should sit 40px from the top — if it is at 0 the '
                'Stack collapsed and Positioned no longer has reference bounds.');
        cubit.close();
      },
    );

    testWidgets('renders MENU header + a feature entry when open and flag enabled', (tester) async {
      // Ensure flag is enabled before pumping
      FeatureFlags().init({'feature.mind_article.enabled': true});
      final cubit = MenuDrawerCubit()..open();
      await tester.pumpWidget(_wrap(cubit));
      await tester.pump(const Duration(milliseconds: 300)); // settle entry animation

      expect(find.text('MENU'), findsOneWidget);
      expect(find.text('ai-mind deep dive'), findsOneWidget);
      expect(find.text('Long-form on the cognitive layer'), findsOneWidget);

      cubit.close();
    });

    testWidgets('shows empty state when no flags are enabled', (tester) async {
      // Force every known flag off
      for (final f in MenuFeatures.all) {
        FeatureFlags().disable(f.flagKey);
      }
      final cubit = MenuDrawerCubit()..open();
      await tester.pumpWidget(_wrap(cubit));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('No features yet.'), findsOneWidget);
      // No feature entries should render
      expect(find.text('ai-mind deep dive'), findsNothing);

      cubit.close();
    });
  });
}
