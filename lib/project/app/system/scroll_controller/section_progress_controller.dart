import 'package:flutter_home_page/project/app/interfaces/scroll_observer.dart';
import 'package:flutter_home_page/project/app/config/scroll_sequence_config.dart';
import 'package:flutter_home_page/project/app/views/components/section_progress_indicator.dart';

class SectionProgressController implements ScrollObserver {
  final SectionProgressIndicator component;

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
    int section = 0;

    if (scrollOffset < ScrollSequenceConfig.boldTextEntranceStart) {
      section = 0; // Hero
    } else if (scrollOffset < ScrollSequenceConfig.philosophyStart) {
      section = 1; // Bold Text
    } else if (scrollOffset < ScrollSequenceConfig.workExpTitleEntranceStart) {
      section = 2; // Philosophy
    } else if (scrollOffset < ScrollSequenceConfig.testimonialEntranceStart) {
      section = 3; // Work Experience
    } else if (scrollOffset < ScrollSequenceConfig.contactEntranceStart) {
      section = 4; // Testimonials + Skills
    } else {
      section = 5; // Contact
    }

    component.setSection(section);

    // Fade out during hero section and title, fade in as content starts
    if (scrollOffset < 200) {
      component.opacity = 0.0;
    } else if (scrollOffset < 400) {
      final t = (scrollOffset - 200) / 200.0;
      component.opacity = t;
    } else if (scrollOffset < ScrollSequenceConfig.contactExitEnd) {
      component.opacity = 1.0;
    } else {
      // Fade out at the end
      final t = (scrollOffset - ScrollSequenceConfig.contactExitEnd) / 200.0;
      component.opacity = (1.0 - t).clamp(0.0, 1.0);
    }
  }
}
