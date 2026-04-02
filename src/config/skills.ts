export interface Skill {
  id: string
  label: string
  category: 'language' | 'framework' | 'tool' | 'platform' | 'ai'
  color: string // accent color for the key
}

// Keyboard layout: 4 rows mapped to skill categories
// Row 0 (top): Languages & Core
// Row 1: Frameworks & Libraries
// Row 2: Tools & Infrastructure
// Row 3 (bottom): Platforms & AI

export const SKILLS: Skill[][] = [
  // Row 0 — Languages
  [
    { id: 'dart', label: 'Dart', category: 'language', color: '#0175C2' },
    { id: 'typescript', label: 'TS', category: 'language', color: '#3178C6' },
    { id: 'javascript', label: 'JS', category: 'language', color: '#F7DF1E' },
    { id: 'python', label: 'Py', category: 'language', color: '#3776AB' },
    { id: 'glsl', label: 'GLSL', category: 'language', color: '#5586A4' },
    { id: 'sql', label: 'SQL', category: 'language', color: '#336791' },
    { id: 'html', label: 'HTML', category: 'language', color: '#E34F26' },
    { id: 'css', label: 'CSS', category: 'language', color: '#1572B6' },
  ],
  // Row 1 — Frameworks
  [
    { id: 'flutter', label: 'Flutter', category: 'framework', color: '#02569B' },
    { id: 'react', label: 'React', category: 'framework', color: '#61DAFB' },
    { id: 'threejs', label: 'Three', category: 'framework', color: '#049EF4' },
    { id: 'nodejs', label: 'Node', category: 'framework', color: '#339933' },
    { id: 'gsap', label: 'GSAP', category: 'framework', color: '#88CE02' },
    { id: 'tailwind', label: 'TW', category: 'framework', color: '#06B6D4' },
    { id: 'vite', label: 'Vite', category: 'framework', color: '#646CFF' },
  ],
  // Row 2 — Tools
  [
    { id: 'git', label: 'Git', category: 'tool', color: '#F05032' },
    { id: 'docker', label: 'Docker', category: 'tool', color: '#2496ED' },
    { id: 'postgres', label: 'PG', category: 'tool', color: '#4169E1' },
    { id: 'firebase', label: 'Fire', category: 'tool', color: '#FFCA28' },
    { id: 'linux', label: 'Linux', category: 'tool', color: '#FCC624' },
    { id: 'figma', label: 'Figma', category: 'tool', color: '#F24E1E' },
  ],
  // Row 3 — Platforms & AI
  [
    { id: 'claude', label: 'Claude', category: 'ai', color: '#D4A45C' },
    { id: 'ollama', label: 'Ollama', category: 'ai', color: '#FFFFFF' },
    { id: 'tailscale', label: 'Tail', category: 'platform', color: '#242424' },
    { id: 'cloudflare', label: 'CF', category: 'platform', color: '#F38020' },
    { id: 'rpi', label: 'RPi', category: 'platform', color: '#A22846' },
  ],
]

export const ALL_SKILLS = SKILLS.flat()
