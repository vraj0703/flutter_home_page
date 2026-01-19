import 'package:flutter_home_page/project/app/interfaces/scroll_observer.dart';
import 'package:flutter_home_page/project/app/config/scroll_sequence_config.dart';
import 'package:flutter_home_page/project/app/views/components/section_indicator/morphing_section_indicator.dart';

class SectionProgressController implements ScrollObserver {
  final MorphingSectionIndicator component;

  // Section boundaries (6 sections total)
  // 0: Hero (0 - 400)
  // 1: Bold Text (400 - 1900)
  // 2: Philosophy (1900 - 3600)
  // 3: Work Experience (3600 - 7100)
  // 4: Testimonials + Skills (7100 - 13200)
  // 5: Contact (13200+)

  SectionProgressController({required this.component});

  @override
  void onScroll(double scrollOffset) {
    // Calculate continuous progress (0.0 to 5.0) based on scroll position
    double progress = 0.0;

    if (scrollOffset < ScrollSequenceConfig.boldTextEntranceStart) {
      // Hero section (0.0)
      progress = 0.0;
    } else if (scrollOffset < ScrollSequenceConfig.philosophyStart) {
      // Transition from Hero to Bold Text (0.0 -> 1.0)
      final t = (scrollOffset - 0.0) / ScrollSequenceConfig.philosophyStart;
      progress = t.clamp(0.0, 1.0);
    } else if (scrollOffset < ScrollSequenceConfig.workExpTitleEntranceStart) {
      // Transition from Bold Text to Philosophy (1.0 -> 2.0)
      final t = (scrollOffset - ScrollSequenceConfig.philosophyStart) /
          (ScrollSequenceConfig.workExpTitleEntranceStart - ScrollSequenceConfig.philosophyStart);
      progress = 1.0 + t.clamp(0.0, 1.0);
    } else if (scrollOffset < ScrollSequenceConfig.testimonialEntranceStart) {
      // Transition from Philosophy to Work Experience (2.0 -> 3.0)
      final t = (scrollOffset - ScrollSequenceConfig.workExpTitleEntranceStart) /
          (ScrollSequenceConfig.testimonialEntranceStart - ScrollSequenceConfig.workExpTitleEntranceStart);
      progress = 2.0 + t.clamp(0.0, 1.0);
    } else if (scrollOffset < ScrollSequenceConfig.contactEntranceStart) {
      // Transition from Work Experience to Testimonials (3.0 -> 4.0)
      final t = (scrollOffset - ScrollSequenceConfig.testimonialEntranceStart) /
          (ScrollSequenceConfig.contactEntranceStart - ScrollSequenceConfig.testimonialEntranceStart);
      progress = 3.0 + t.clamp(0.0, 1.0);
    } else {
      // Transition from Testimonials to Contact (4.0 -> 5.0)
      final t = (scrollOffset - ScrollSequenceConfig.contactEntranceStart) /
          (ScrollSequenceConfig.contactEntranceDuration * 2);
      progress = 4.0 + t.clamp(0.0, 1.0);
    }

    component.updateScrollProgress(progress);

    // Fade in after title animation finishes, similar to bouncy arrow
    // Stay visible throughout (contact is final section, no fade out)
    if (scrollOffset < ScrollSequenceConfig.titleParallaxEnd) {
      // Hidden during title animation
      component.opacity = 0.0;
    } else if (scrollOffset < ScrollSequenceConfig.boldTextEntranceEnd) {
      // Ease in during bold text entrance (800 -> 900)
      final fadeStart = ScrollSequenceConfig.titleParallaxEnd;
      final fadeEnd = ScrollSequenceConfig.boldTextEntranceEnd;
      final t = ((scrollOffset - fadeStart) / (fadeEnd - fadeStart)).clamp(0.0, 1.0);
      // Apply ease-out curve for smooth appearance
      final easedT = _easeOut(t);
      component.opacity = easedT;
    } else {
      component.opacity = 1.0;
    }
  }

  // Simple ease-out curve for smooth fade-in
  double _easeOut(double t) {
    return 1.0 - ((1.0 - t) * (1.0 - t));
  }
}
