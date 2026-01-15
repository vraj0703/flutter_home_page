class ExperienceNode {
  final String year;
  final String title; // "Senior Software Engineer"
  final String company; // "Twin Health"
  final String duration; // "09/2021 - Present"
  final String location; // "Remote, Lucknow, India"
  final String url;

  const ExperienceNode({
    required this.year,
    required this.title,
    required this.company,
    required this.duration,
    required this.location,
    required this.url,
  });
}

final List<ExperienceNode> data = [
  ExperienceNode(
    year: "2021",
    company: "Twin Health",
    title: "Senior Software Engineer",
    duration: "09/2021 - Present",
    location: "Remote, Lucknow, India",
    url: "https://usa.twinhealth.com",
  ),
  ExperienceNode(
    year: "2017",
    company: "Flick2Know",
    title: "Senior Software Developer",
    duration: "02/2017 - 08/2021",
    location: "Gurugram, India",
    url: "https://fieldassist.com",
  ),
  ExperienceNode(
    year: "2016",
    company: "PayU India",
    title: "Software Developer",
    duration: "06/2016 - 02/2017",
    location: "Gurugram, India",
    url: "https://payu.in",
  ),
  ExperienceNode(
    year: "2012",
    company: "MNNIT Allahabad",
    title: "B.Tech CSE",
    duration: "05/2012 - 05/2016",
    location: "Prayagraj, India",
    url: "https://mnnit.ac.in",
  ),
  ExperienceNode(
    year: "2012",
    company: "School",
    title: "Education",
    duration: "Until 2012",
    location: "",
    url: "",
  ),
];