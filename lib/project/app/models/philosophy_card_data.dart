import 'dart:ui';

class PhilosophyCardData {
  final String icon;
  final String title;
  final String description;
  final Color accentColor;
  final String? url;

  const PhilosophyCardData({
    required this.icon,
    required this.title,
    required this.description,
    this.accentColor = const Color(0xFFFFFFFF),
    this.url,
  });
}

final cardData = [
  const PhilosophyCardData(
    icon: "💼",
    title: "LinkedIn",
    description: "Connect with me on LinkedIn for professional updates, endorsements, and career insights.",
    accentColor: Color(0xFF0A66C2),
    url: "https://www.linkedin.com/in/ivishalraj/",
  ),
  const PhilosophyCardData(
    icon: "✉️",
    title: "Mail",
    description: "Reach out via email for collaborations, opportunities, or just to say hello.",
    accentColor: Color(0xFFEA4335),
    url: "mailto:ivishalraj@gmail.com",
  ),
  const PhilosophyCardData(
    icon: "🐙",
    title: "GitHub",
    description: "Explore my open-source contributions, side projects, and code experiments.",
    accentColor: Color(0xFFFFFFFF),
    url: "https://github.com/ivishalraj",
  ),
  const PhilosophyCardData(
    icon: "📄",
    title: "Resume",
    description: "Download my resume to learn more about my experience, skills, and achievements.",
    accentColor: Color(0xFFC78E53),
    url: "https://www.vishalraj.space/flutter/assets/assets/VishalRajResume.pdf",
  ),
];
