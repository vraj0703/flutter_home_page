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
    id: 'raj-sadan', title: 'Raj Sadan', description: 'AI Governance System',
    url: '#', image: '/textures/logo.png',
    colors: ['#D4A800', '#5C3A1E'],
    stats: ['21 Gateways', '71 Capabilities', '3-Node Mesh'],
    visual: 'mesh',
  },
  {
    id: 'subwise', title: 'SubWise', description: 'Subscription Tracker',
    url: '#', image: '/textures/logo.png',
    colors: ['#4338CA', '#1E1B4B'],
    stats: ['Kotlin', 'Compose', 'Material 3'],
    visual: 'dashboard',
  },
  {
    id: 'twin-health', title: 'Twin Health', description: 'Digital Health Platform',
    url: '#', image: '/textures/logo.png',
    colors: ['#10B981', '#064E3B'],
    stats: ['67 Releases', '0 Hotfixes', '$87K Saved'],
    visual: 'pipeline',
  },
  {
    id: 'fieldassist', title: 'FieldAssist', description: 'Enterprise Field Force',
    url: '#', image: '/textures/logo.png',
    colors: ['#F59E0B', '#78350F'],
    stats: ['1600+ Files', '100+ Agents', 'Multi-Flavor'],
    visual: 'graph',
  },
  {
    id: 'portfolio', title: 'vishalraj.space', description: 'This Portfolio',
    url: '#', image: '/textures/logo.png',
    colors: ['#C8A45C', '#5C3A1E'],
    stats: ['Flutter', 'Three.js', 'GLSL Shaders'],
    visual: 'timeline',
  },
  {
    id: 'content-engine', title: 'Content Engine', description: 'Automated YouTube Pipeline',
    url: '#', image: '/textures/logo.png',
    colors: ['#EF4444', '#7F1D1D'],
    stats: ['TTS', 'FFmpeg', 'Auto Upload'],
    visual: 'funnel',
  },
  {
    id: 'payu-security', title: 'PayU Security', description: 'Payment Encryption',
    url: '#', image: '/textures/logo.png',
    colors: ['#6366F1', '#312E81'],
    stats: ['Triple DES', 'PINPAN', 'Client Crypto'],
    visual: 'chat',
  },
]

// Paired layout: P1+P2, P3+P4, P5+P6 facing each other, P7 alone on left
// Left wall: P1, P3, P5, P7 (indices 0, 2, 4, 6)
// Right wall: P2, P4, P6 (indices 1, 3, 5)
export const LEFT_PROJECTS = [PROJECTS[0], PROJECTS[2], PROJECTS[4], PROJECTS[6]]
export const RIGHT_PROJECTS = [PROJECTS[1], PROJECTS[3], PROJECTS[5]]
