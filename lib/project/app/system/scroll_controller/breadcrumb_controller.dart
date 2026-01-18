import 'package:flutter_home_page/project/app/interfaces/scroll_observer.dart';
import 'package:flutter_home_page/project/app/views/components/transition_breadcrumb.dart';

class BreadcrumbController implements ScrollObserver {
  final TransitionBreadcrumb component;

  BreadcrumbController({required this.component});

  @override
  void onScroll(double scrollOffset) {
    // Show breadcrumbs only during transitions between major sections
    String text = "";
    double opacity = 0.0;

    // Philosophy transition (approaching from Bold Text)
    if (scrollOffset >= 1700 && scrollOffset < 2100) {
      text = "Next: Philosophy ↓";
      final t = (scrollOffset - 1700) / 200.0;
      opacity = (t * (1.0 - t) * 4).clamp(0.0, 1.0); // Fade in and out
    }
    // Work Experience transition
    else if (scrollOffset >= 3400 && scrollOffset < 3800) {
      text = "Work Experience ↓";
      final t = (scrollOffset - 3400) / 200.0;
      opacity = (t * (1.0 - t) * 4).clamp(0.0, 1.0);
    }
    // Experience details transition (shifted +550)
    else if (scrollOffset >= 5150 && scrollOffset < 5450) {
      text = "Experience ↓";
      final t = (scrollOffset - 5150) / 200.0;
      opacity = (t * (1.0 - t) * 4).clamp(0.0, 1.0);
    }
    // Testimonials transition (shifted +550)
    else if (scrollOffset >= 7550 && scrollOffset < 7950) {
      text = "Testimonials ↓";
      final t = (scrollOffset - 7550) / 200.0;
      opacity = (t * (1.0 - t) * 4).clamp(0.0, 1.0);
    }
    // Contact transition (shifted +550)
    else if (scrollOffset >= 11550 && scrollOffset < 11950) {
      text = "Contact ↓";
      final t = (scrollOffset - 11550) / 200.0;
      opacity = (t * (1.0 - t) * 4).clamp(0.0, 1.0);
    }

    component.setBreadcrumb(text);
    component.opacity = opacity;
  }
}
