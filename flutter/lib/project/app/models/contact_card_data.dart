import 'dart:ui';

class ContactCardData {
  final String icon;
  final String title;
  final String description;
  final Color accentColor;
  final String? url;

  const ContactCardData({
    required this.icon,
    required this.title,
    required this.description,
    this.accentColor = const Color(0xFFFFFFFF),
    this.url,
  });
}

final cardData = [
  const ContactCardData(
    icon: "📄",
    title: "Resume",
    description: "Download my resume for a detailed overview of my experience, skills, and achievements.",
    accentColor: Color(0xFF00FFFF),
    // url: will be set when resume PDF is ready
  ),
  const ContactCardData(
    icon: "💼",
    title: "LinkedIn",
    description: "Connect with me on LinkedIn for professional updates, endorsements, and career insights.",
    accentColor: Color(0xFF0A66C2),
    url: "https://www.linkedin.com/in/vraj0703/",
  ),
  const ContactCardData(
    icon: "🐙",
    title: "GitHub",
    description: "Explore my open-source contributions, side projects, and code experiments on GitHub.",
    accentColor: Color(0xFFFFFFFF),
    url: "https://github.com/vraj0703",
  ),
  const ContactCardData(
    icon: "✉️",
    title: "Email",
    description: "Reach out via email for collaborations, opportunities, or just to say hello.\n\nvraj0703@gmail.com",
    accentColor: Color(0xFFEA4335),
    url: "mailto:vraj0703@gmail.com",
  ),
];
