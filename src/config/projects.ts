export interface Project {
  id: string
  title: string
  description: string
  url: string
  image: string
  colors: [string, string]
  stats: string[]           // key metrics shown on frame
  visual: 'mesh' | 'pipeline' | 'timeline' | 'graph' | 'funnel' | 'dashboard' | 'chat'
}

export const PROJECTS: Project[] = [
  {
    id: 'raj-sadan', title: 'Raj Sadan', description: 'Multi-Agent AI Governance System',
    url: 'https://github.com/vraj0703', image: '/textures/logo.png',
    colors: ['#D4A800', '#5C3A1E'],
    stats: ['11 Public Repos', '474 Tests', '4-Layer Governance'],
    visual: 'mesh',
  },
  {
    id: 'ai-mind', title: 'ai-mind', description: 'Cognitive Orchestration Organ',
    url: 'https://github.com/vraj0703/ai-mind', image: '/textures/logo.png',
    colors: ['#4338CA', '#1E1B4B'],
    stats: ['Decision Routing', '3-Tier LLM', 'Clean Architecture'],
    visual: 'pipeline',
  },
  {
    id: 'ai-constitution', title: 'ai-constitution', description: 'Trust Layer for Autonomous Agents',
    url: 'https://github.com/vraj0703/ai-constitution', image: '/textures/logo.png',
    colors: ['#10B981', '#064E3B'],
    stats: ['Governance', 'Autonomy Limits', 'Audit Trails'],
    visual: 'timeline',
  },
  {
    id: 'ai-knowledge', title: 'ai-knowledge', description: 'Self-Learning Tool Registry',
    url: 'https://github.com/vraj0703/ai-knowledge', image: '/textures/logo.png',
    colors: ['#F59E0B', '#78350F'],
    stats: ['71 Capabilities', 'Hebbian Graph', 'Semantic Search'],
    visual: 'graph',
  },
  {
    id: 'subwise', title: 'SubWise', description: 'Subscription Tracker',
    url: 'https://github.com/vraj0703/subwise', image: '/textures/logo.png',
    colors: ['#C8A45C', '#5C3A1E'],
    stats: ['Kotlin 2', 'Compose', 'Material 3'],
    visual: 'dashboard',
  },
  {
    id: 'jotter', title: 'Jotter', description: 'Notes App with In-App Purchases',
    url: 'https://github.com/vraj0703/jotter', image: '/textures/logo.png',
    colors: ['#EF4444', '#7F1D1D'],
    stats: ['Flutter', 'RevenueCat', 'Play Store'],
    visual: 'chat',
  },
  {
    id: 'twin-health', title: 'Twin Health', description: 'Digital Health Platform',
    url: '#', image: '/textures/logo.png',
    colors: ['#6366F1', '#312E81'],
    stats: ['67 Releases', '0 Hotfixes', '$87K Saved'],
    visual: 'funnel',
  },
]

// Paired layout: P1+P2, P3+P4, P5+P6 facing each other, P7 alone on left
// Left wall: P1, P3, P5, P7 (indices 0, 2, 4, 6)
// Right wall: P2, P4, P6 (indices 1, 3, 5)
export const LEFT_PROJECTS = [PROJECTS[0], PROJECTS[2], PROJECTS[4], PROJECTS[6]]
export const RIGHT_PROJECTS = [PROJECTS[1], PROJECTS[3], PROJECTS[5]]
