import 'dart:ui';

class PhilosophyCardData {
  final String icon; // Emoji
  final String title;
  final String description;
  final Color accentColor;

  const PhilosophyCardData({
    required this.icon,
    required this.title,
    required this.description,
    this.accentColor = const Color(0xFFFFFFFF),
  });
}

final cardData = [
  const PhilosophyCardData(
    icon: "🎨",
    title: "Code is Craft",
    description:
        "I enjoy reading code deeply, recognizing patterns, and treating structure like a well-played game of Tetris. For me, beautiful is better than ugly, and building something well is its own reward.",
  ),
  const PhilosophyCardData(
    icon: "🏆",
    title: "Quality over Haste",
    description:
        "I commit to solutions that meet high standards of quality, maintainability, and clarity. I believe that readability counts and that problems should be solved thoughtfully, not just quickly.",
  ),
  const PhilosophyCardData(
    icon: "🧹",
    title: "Prune, Simplify, Grow",
    description:
        "I am passionate about continuously improving code by removing repetition and strengthening architecture. In the spirit of simple is better than complex, I seek the one obvious way to build systems.",
  ),
  const PhilosophyCardData(
    icon: "💡",
    title: "Ideas over Distractions",
    description:
        "I thrive in teams and discussions that revolve around ideas and solutions. I'm driven by a deep curiosity and a principled approach to collaboration, always aiming to learn and grow.",
  ),
];
