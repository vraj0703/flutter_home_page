import 'package:flutter_home_page/project/app/models/experience_node.dart';

class GameData {
  static const List<ExperienceNode> experienceNodes = [
    ExperienceNode(
      year: "2021",
      company: "Twin Health",
      title: "Senior Software Engineer",
      duration: "09/2021 - Present",
      location: "Remote, Lucknow, India",
      url: "https://usa.twinhealth.com",
      description: [
        "Architected scalable mobile frameworks (Daily Actions, Sensor Flows, Survey Integration), powering 35+ flows with exhaustive documentation, improving testability and time-to-production via JSON config.",
        "Built real-time communication bridges between Flutter, Android, and medical sensor SDKs using method and event channels, reducing development time by 50% through centralised UI/UX logic in flutter.",
        "Collaborated with cross-functional teams to build real-time meal feedback with macro breakdowns, mitigating EA1C decline (79% -> 62%) and unlocking a \$3M revenue uplift.",
        "Delivered end-to-end AI-based photo meal logging (95% success rate) and supplement preference flows saving over \$87K annually.",
        "Implemented dependency injection (get_it, injectables) and routing systems (go_router) in Flutter codebase to boost modularity and test coverage, enabling independent page testing, while significantly reducing development, testing, and deployment time.",
      ],
    ),
    ExperienceNode(
      year: "2017",
      company: "Flick2Know",
      title: "Senior Software Developer",
      duration: "02/2017 - 08/2021",
      location: "Gurugram, India",
      url: "https://fieldassist.com",
      description: [
        "Contributed significantly to lay down the groundwork for 7+ Android apps, focusing on scalable architecture and setting up strong foundations for the team to build upon.",
        "Led and mentored a team of four engineers in building impactful sales automation and analytics apps, with over 100K+ downloads.",
        "Transformed platform APIs into a scalable, low-latency architecture, reducing response times for faster, reliable mobile–platform communication across diverse network conditions.",
        "Established CI/CD pipelines using Azure DevOps and Fastlane, streamlining the release process and significantly reducing deployment time.",
      ],
    ),
    ExperienceNode(
      year: "2016",
      company: "PayU India",
      title: "Software Developer",
      duration: "06/2016 - 02/2017",
      location: "Gurugram, India",
      url: "https://payu.in",
      description: [
        "Worked on the PayU Cred Android app within a 15+ member team, focusing on secure credit card management and analytics capabilities.",
      ],
    ),
    ExperienceNode(
      year: "2012",
      company: "MNNIT Allahabad",
      title: "B.Tech CSE",
      duration: "05/2012 - 05/2016",
      location: "Prayagraj, India",
      url: "https://mnnit.ac.in",
      description: [
        "Engineered a Variant Particle Swarm Optimization (VPSO) algorithm for cloud workflow scheduling, significantly reducing execution and communication costs. The optimized virtual machine utilization, delivering enhanced efficiency compared to standard methods.",
        "Composed an Android app over Bluetooth to control and automate home appliances connected to an Arduino board.",
        "Designed, coded, and published multiple Android apps on Google Play Store, including games like Minesweeper, a Unity-based Flappy Bird clone, Snake & Ladder, and Bull & Cows.",
        "Created the official Android app for the college cultural and technical festivals, featuring a minimal design, elegant UI, and real-time event notifications, published on the Google Play Store.",
      ],
    ),
    ExperienceNode(
      year: "2012",
      company: "School",
      title: "Education",
      duration: "Until 2012",
      location: "",
      url: "",
      description: [],
    ),
  ];
}
