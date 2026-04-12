/**
 * Gallery corridor dimensions — shared constants used across all gallery components.
 */
import { LEFT_PROJECTS, RIGHT_PROJECTS } from '../../../config/projects'
import { TESTIMONIALS } from '../../../config/testimonials'

/* ── Corridor ──────────────────────────────────────── */
export const CW = 8, CH = 5
export const FRAME_MAX_H = 3.0, FRAME_DEPTH = 0.2, FRAME_BORDER = 0.15, FRAME_Y = 0.8, SPACING = 5
export const WALL_X = CW / 2, FLOOR_Y = -(CH / 2 - 1), CEIL_Y = CH / 2 + 1.5
export const FOV_RAD = (65 * Math.PI) / 180, FOCUS_MARGIN = 1.5

export const CORRIDOR_LEN = LEFT_PROJECTS.length * SPACING + 8
export const BACK_WALL_Z = -(CORRIDOR_LEN - 3)
export const RIGHT_WALL_LEN = RIGHT_PROJECTS.length * SPACING + 6

/* ── Testimonials ──────────────────────────────────── */
export const TEST_CARDS = TESTIMONIALS.filter(t => !t.isCTA)
export const ALL_TEST_CARDS = TESTIMONIALS
export const TEST_SPACING = 5
export const TEST_START_X = 7
export const TEST_PAN_END = TEST_START_X + (ALL_TEST_CARDS.length - 1) * TEST_SPACING

/* ── Keyboard exhibition hall ──────────────────────── */
export const KB_ROOM = 24
const LAST_CARD_X = TEST_START_X + 6 * TEST_SPACING
export const KB_X = LAST_CARD_X + 3 + KB_ROOM / 2
export const KB_Z = BACK_WALL_Z + CW / 2
export const KB_ENTRY_X = KB_X - KB_ROOM / 2
export const KB_END_X = KB_X + KB_ROOM / 2

/* ── Camera ────────────────────────────────────────── */
export const WALL_LOCK_DIST = 4
export const WALL_LOCK_Z = BACK_WALL_Z + WALL_LOCK_DIST
