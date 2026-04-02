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
    icon: "👋",
    title: "Let's Connect",
    description: "I'm always open to interesting conversations, collaborations, and new opportunities. Whether you have a project in mind or just want to say hello — I'd love to hear from you.",
    accentColor: Color(0xFF00FFFF),
  ),
  const PhilosophyCardData(
    icon: "💼",
    title: "LinkedIn",
    description: "Connect with me on LinkedIn for professional updates, endorsements, and career insights.",
    accentColor: Color(0xFF0A66C2),
    url: "https://www.linkedin.com/in/ivishalraj/",
  ),
  const PhilosophyCardData(
    icon: "🐙",
    title: "GitHub",
    description: "Explore my open-source contributions, side projects, and code experiments on GitHub.",
    accentColor: Color(0xFFFFFFFF),
    url: "https://github.com/ivishalraj",
  ),
  const PhilosophyCardData(
    icon: "✉️",
    title: "Email",
    description: "Reach out via email for collaborations, opportunities, or just to say hello.\n\nivishalraj@gmail.com",
    accentColor: Color(0xFFEA4335),
    url: "mailto:ivishalraj@gmail.com",
  ),
];
