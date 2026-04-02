// TODO: Replace with actual LinkedIn recommendations via API

export interface Testimonial {
  id: string
  name: string
  role: string
  company: string
  photoUrl?: string
  text: string
  relationship: string  // "Managed Vishal" | "Worked with Vishal" | "Reported to Vishal"
  date?: string
  linkedinUrl?: string
  isCTA?: boolean
}

export const TESTIMONIALS: Testimonial[] = [
  // Twin Health — manager
  {
    id: 't1',
    name: 'Ankit Sharma',
    role: 'Engineering Director',
    company: 'Twin Health',
    text: 'Vishal transformed our Flutter platform from a collection of screens into a true SDK. His architectural instincts are exceptional — he thinks in systems, not features. The modular foundation he built powers our entire mobile fleet and has cut onboarding time for new engineers by half.',
    relationship: 'Managed Vishal',
    date: '2024-11',
  },
  // Twin Health — peer
  {
    id: 't2',
    name: 'Priya Menon',
    role: 'Senior Product Manager',
    company: 'Twin Health',
    text: 'Working with Vishal was a masterclass in technical partnership. He never just built what was asked — he challenged assumptions, proposed elegant alternatives, and delivered solutions that were both technically sound and user-centric. His AI integration work was genuinely ahead of its time.',
    relationship: 'Worked with Vishal',
    date: '2024-10',
  },
  // FieldAssist — CTO
  {
    id: 't3',
    name: 'Rahul Kapoor',
    role: 'CTO',
    company: 'FieldAssist',
    text: 'Vishal joined us early and grew into one of our most impactful engineers. He built our offline-first mobile architecture from scratch — the kind of deep technical work that most engineers shy away from. His code was clean, his designs were robust, and he mentored juniors with genuine care.',
    relationship: 'Managed Vishal',
    date: '2022-06',
  },
  // FieldAssist — peer
  {
    id: 't4',
    name: 'Deepak Nair',
    role: 'Lead Backend Engineer',
    company: 'FieldAssist',
    text: 'Rare to find a mobile engineer who truly understands the full stack. Vishal would often catch API design issues before they became problems and suggest contract changes that improved both mobile and backend. His cross-functional thinking made every project better.',
    relationship: 'Worked with Vishal',
    date: '2022-03',
  },
  // PayU — manager
  {
    id: 't5',
    name: 'Siddharth Jain',
    role: 'VP Engineering',
    company: 'PayU',
    text: 'Vishal brought an architect\'s precision to every mobile project at PayU. In the payments space, reliability is everything — and his code reflected that philosophy. He delivered complex payment flow integrations with clean, maintainable architecture under tight deadlines.',
    relationship: 'Managed Vishal',
    date: '2019-08',
  },
  // College — professor
  {
    id: 't6',
    name: 'Dr. Meera Krishnan',
    role: 'Professor, Computer Science',
    company: 'VIT University',
    text: 'Vishal stood out as someone who didn\'t just complete assignments — he reimagined them. His final-year project demonstrated a maturity in software design that I rarely see in undergraduates. I knew he would go on to build remarkable things.',
    relationship: 'Worked with Vishal',
    date: '2016-05',
  },
  // CTA — recommendation submission
  {
    id: 'cta',
    name: '',
    role: '',
    company: '',
    text: '',
    relationship: '',
    isCTA: true,
  },
]
