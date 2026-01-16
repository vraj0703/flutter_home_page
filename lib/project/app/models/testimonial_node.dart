class TestimonialNode {
  final String name;
  final String role;
  final String company;
  final String quote;
  final String avatarUrl; // Optional, maybe use Initials

  const TestimonialNode({
    required this.name,
    required this.role,
    required this.company,
    required this.quote,
    this.avatarUrl = '',
  });
}

const List<TestimonialNode> testimonialData = [
  TestimonialNode(
    name: "Alex Rivera",
    role: "CTO",
    company: "TechNova",
    quote:
        "Vishal transformed our chaotic legacy codebase into a streamlined, high-performance machine. His expertise in Flutter is unmatched.",
  ),
  TestimonialNode(
    name: "Sarah Chen",
    role: "Product Manager",
    company: "Healthify",
    quote:
        "The visual polish and attention to detail Vishal brings to every screen is incredible. He doesn't just build apps; he crafts experiences.",
  ),
  TestimonialNode(
    name: "James Wilson",
    role: "Lead Engineer",
    company: "StartUp Inc",
    quote:
        "A true professional who understands both the code and the user. Working with him was a game-changer for our mobile strategy.",
  ),
  TestimonialNode(
    name: "Elena Rodriguez",
    role: "Founder",
    company: "DesignFlow",
    quote:
        "I've never met a developer who cares about pixel perfection as much as I do until I met Vishal. He communicates proactive solutions.",
  ),
  TestimonialNode(
    name: "Michael Chang",
    role: "VP of Engineering",
    company: "FinTech Sol",
    quote:
        "Scalability was our biggest issue. Vishal re-architected our state management, reducing bugs by 80%. Highly recommended.",
  ),
  TestimonialNode(
    name: "David Kim",
    role: "Senior Dev",
    company: "MobileFirst",
    quote:
        "His knowledge of Flame and complex animations opened up possibilities we didn't think were feasible in Flutter.",
  ),
  TestimonialNode(
    name: "Priya Patel",
    role: "Head of Product",
    company: "EduTech Global",
    quote:
        "Vishal delivers. On time, above expectations, and with code that our internal team loves to maintain.",
  ),
  TestimonialNode(
    name: "Robert Fox",
    role: "Creative Director",
    company: "Studio 9",
    quote:
        "Bridging the gap between design and engineering is rare. Vishal does it effortlessly. The animations feel natural and alive.",
  ),
  TestimonialNode(
    name: "Lisa Wong",
    role: "Startup Mentor",
    company: "Incubator Y",
    quote:
        "I recommend Vishal to all my portfolio companies. He is the secret weapon for getting an MVP to look like a Series B product.",
  ),
  TestimonialNode(
    name: "Tom Baker",
    role: "Lead Architect",
    company: "CloudSystems",
    quote:
        "Clean code, clear documentation, and a friendly attitude. Working with Vishal was the highlight of our project.",
  ),
];
