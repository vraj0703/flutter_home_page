# 3D Hero-Style Keyboard Implementation Plan

## Overview
Transform the skills keyboard into a cinematic 3D hero object with metallic shader effects, enhanced depth, and square hero keys for primary tools (Flutter, Dart, Flame). This will make the keyboard feel like a premium, interactive centerpiece rather than a flat display.

## Current State
- Simple isometric keycaps with 10px depth (side face offset)
- Static highlight for Flutter/Dart/Flame (white fill + black text)
- All keys animate as single unit (no stagger)
- No shader effects or dynamic lighting
- 4 rows: 6, 7, 7, 5 keys

## Target State
- **3D Hero Keys**: Square metallic keys for Flutter/Dart/Flame with shader
- **Enhanced Depth**: Increased depth with gradient lighting
- **Dynamic Lighting**: Keys respond to god ray position
- **Stagger Animation**: Keys pop in sequentially with elastic bounce
- **Improved Chassis**: Multi-layer beveled chassis with gloss effect
- **Perspective Tilt**: Subtle 3D rotation for depth perception

---

## Implementation Approach

### Phase 1: Hero Keys with Metallic Shader

#### 1.1 Modify KeycapComponent to Support Shaders
**File**: `lib/project/app/views/components/skills/keycap_component.dart`

**Changes**:
- Add optional `FragmentShader? shader` parameter
- Add `bool isHeroKey` flag (true for Flutter/Dart/Flame)
- Make hero keys **square** (80×80px) vs regular (60×60px)
- Add `_time` field and increment in `update()`
- Override `render()` to set shader uniforms for hero keys only
- Apply shader to text foreground Paint for hero keys
- Add `HasGameReference` mixin for god ray access

**Hero Key Pattern**:
```dart
class KeycapComponent extends PositionComponent with HasPaint, HasGameReference {
  final String label;
  final FragmentShader? shader;
  final bool isHeroKey;
  double _time = 0.0;

  KeycapComponent({
    required this.label,
    required Vector2 size,
    this.shader,
  }) : isHeroKey = ["Flutter", "Dart", "Flame"].contains(label),
       super(size: size);

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
  }

  @override
  void render(Canvas canvas) {
    if (opacity == 0.0) return;

    // ... existing keycap rendering ...

    // For hero keys with shader: set uniforms
    if (isHeroKey && shader != null && hasGameRef) {
      final dpr = game.canvasSize.x / game.size.x;
      final physicalTopLeft = absolutePositionOf(Vector2.zero()) * dpr;
      final physicalSize = size * dpr;
      final physicalLightPos = game.godRay.position * dpr;

      shader!
        ..setFloat(0, physicalSize.x)
        ..setFloat(1, physicalSize.y)
        ..setFloat(2, physicalTopLeft.x)
        ..setFloat(3, physicalTopLeft.y)
        ..setFloat(4, _time)
        ..setFloat(5, 0.9) // Bright silver base color
        ..setFloat(6, 0.9)
        ..setFloat(7, 0.95)
        ..setFloat(8, opacity)
        ..setFloat(9, physicalLightPos.x)
        ..setFloat(10, physicalLightPos.y);
    }

    super.render(canvas);
  }

  @override
  Future<void> onLoad() async {
    TextStyle textStyle = TextStyle(
      fontFamily: GameStyles.fontInter,
      fontSize: isHeroKey ? 12.0 : GameStyles.keyFontSize,
      fontWeight: isHeroKey ? FontWeight.w900 : FontWeight.bold,
      color: isHeroKey ? const Color(0xFFFFD700) : GameStyles.keyTextNormal,
    );

    // For hero keys: apply shader to foreground
    if (isHeroKey && shader != null) {
      textStyle = textStyle.copyWith(
        foreground: Paint()..shader = shader,
      );
    }

    final text = TextComponent(
      text: label,
      textRenderer: TextPaint(style: textStyle),
    );
    text.anchor = Anchor.center;
    text.position = size / 2;
    add(text);
  }
}
```

#### 1.2 Modify SkillsKeyboardComponent to Pass Shader
**File**: `lib/project/app/views/components/skills/skills_keyboard_component.dart`

**Changes**:
- Add `FragmentShader? metallicShader` constructor parameter
- Pass shader to KeycapComponent constructor
- Adjust layout to accommodate square hero keys (80×80 vs 60×60)
- Dynamically calculate row widths for mixed key sizes

**Layout Adjustment**:
```dart
// Calculate row width accounting for hero keys
double calculateRowWidth(int row) {
  double width = 0.0;
  int startIndex = getStartIndexForRow(row);
  int count = rows[row];

  for (int i = 0; i < count; i++) {
    final toolName = tools[startIndex + i];
    final isHeroKey = ["Flutter", "Dart", "Flame"].contains(toolName);
    width += isHeroKey ? 80.0 : 60.0;
    if (i < count - 1) width += spacing;
  }
  return width;
}

// In key creation loop
final isHeroKey = ["Flutter", "Dart", "Flame"].contains(toolName);
final keySize = isHeroKey ? 80.0 : GameLayout.keyboardKeySize;

final key = KeycapComponent(
  label: toolName,
  size: Vector2(keySize, keySize),
  shader: isHeroKey ? metallicShader : null,
);
```

#### 1.3 Wire Shader from Factory
**File**: `lib/project/app/system/game_component_factory.dart`

**Changes**:
```dart
skillsPage = SkillsKeyboardComponent(
  size: size,
  metallicShader: metallicShader, // Pass shader
);
```

---

### Phase 2: Enhanced 3D Depth & Lighting

#### 2.1 Increase Key Depth
**File**: `lib/project/app/config/game_layout.dart`

**Changes**:
```dart
// Change from 10.0 to 20.0
static const double keyboardKeyDepth = 20.0;
```

#### 2.2 Add Gradient Lighting to Keys
**File**: `lib/project/app/views/components/skills/keycap_component.dart`

**Changes** (in `render()` method):
```dart
// Top face with gradient lighting
final topGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [
    color.withValues(alpha: opacity * 1.0),
    color.withValues(alpha: opacity * 0.7),
  ],
);

final rect = Rect.fromLTWH(0, 0, size.x, size.y);
final paint = Paint()..shader = topGradient.createShader(rect);

canvas.drawRRect(topRect, paint);
```

#### 2.3 Add Cast Shadows
**File**: `lib/project/app/views/components/skills/keycap_component.dart`

**Changes** (before side face):
```dart
// Cast shadow on chassis
canvas.drawRRect(
  RRect.fromRectAndRadius(
    Rect.fromLTWH(-2, depth + 2, size.x + 4, 3),
    Radius.circular(radius),
  ),
  Paint()
    ..color = Colors.black.withValues(alpha: opacity * 0.3)
    ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2.0),
);
```

---

### Phase 3: Staggered Entrance Animation

#### 3.1 Add Per-Key Animation System
**File**: `lib/project/app/views/components/skills/skills_keyboard_component.dart`

**Changes**:
```dart
class SkillsKeyboardComponent extends PositionComponent with HasPaint {
  final List<double> _keyEntranceDelays = [];
  double _globalEntranceProgress = 0.0;

  @override
  Future<void> onLoad() async {
    // ... chassis setup ...

    int keyIndex = 0;
    for (int r = 0; r < rows.length; r++) {
      for (int k = 0; k < count; k++) {
        // Stagger: row delay (100ms) + column delay (30ms)
        final delay = (r * 0.1) + (k * 0.03);
        _keyEntranceDelays.add(delay);

        // ... create key ...
        keyIndex++;
      }
    }
  }

  void setEntranceProgress(double progress) {
    _globalEntranceProgress = progress;
    _updateKeyAnimations();
  }

  void _updateKeyAnimations() {
    int keyIndex = 0;
    for (final child in children) {
      if (child is KeycapComponent && keyIndex < _keyEntranceDelays.length) {
        final delay = _keyEntranceDelays[keyIndex];
        final t = (_globalEntranceProgress - delay).clamp(0.0, 1.0);

        // Elastic bounce
        final curvedT = _elasticEaseOut(t);

        child.scale = Vector2.all(0.5 + (0.5 * curvedT));
        child.opacity = curvedT * opacity; // Respect parent opacity

        keyIndex++;
      }
    }
  }

  double _elasticEaseOut(double t) {
    if (t == 0.0 || t == 1.0) return t;
    const amplitude = 0.4;
    const period = 0.3;
    return pow(2, -10 * t) * sin((t - amplitude / 4) * (2 * pi) / period) + 1;
  }

  @override
  set opacity(double val) {
    super.opacity = val;
    if (isLoaded) _updateKeyAnimations();
  }
}
```

#### 3.2 Trigger from Controller
**File**: `lib/project/app/system/scroll_controller/skills_page_controller.dart`

**Changes**:
```dart
@override
void onScroll(double scrollOffset) {
  // ... existing phases ...

  if (scrollOffset >= entranceStart && scrollOffset < entranceEnd) {
    final t = (scrollOffset - entranceStart) / (entranceEnd - entranceStart);
    component.setEntranceProgress(t);
  } else if (scrollOffset >= entranceEnd) {
    component.setEntranceProgress(1.0);
  }
}
```

---

### Phase 4: Multi-Layer Beveled Chassis

#### 4.1 Enhanced Chassis
**File**: `lib/project/app/views/components/skills/skills_keyboard_component.dart`

**Changes** (in `onLoad()`):
```dart
// Layer 1: Shadow (deepest)
final shadow = RectangleComponent(
  position: chassisPos + Vector2(0, 15),
  size: Vector2(chassisWidth, chassisHeight),
  paint: Paint()..color = Color(0xFF000000).withValues(alpha: opacity * 0.5),
  priority: -3,
);
add(shadow);

// Layer 2: Side
final side = RectangleComponent(
  position: chassisPos + Vector2(0, 10),
  size: Vector2(chassisWidth, chassisHeight),
  paint: Paint()..color = GameStyles.keyboardChassisSide.withValues(alpha: opacity),
  priority: -2,
);
add(side);

// Layer 3: Main with bevel gradient
final bevelRect = Rect.fromLTWH(chassisPos.x, chassisPos.y, chassisWidth, chassisHeight);
final bevelGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [
    GameStyles.keyboardChassis.withValues(alpha: opacity * 1.2),
    GameStyles.keyboardChassis.withValues(alpha: opacity),
    GameStyles.keyboardChassis.withValues(alpha: opacity * 0.8),
  ],
  stops: [0.0, 0.5, 1.0],
);

_chassis = RectangleComponent(
  position: chassisPos,
  size: Vector2(chassisWidth, chassisHeight),
  paint: Paint()..shader = bevelGradient.createShader(bevelRect),
  priority: -1,
);
add(_chassis);
```

---

## Implementation Order

1. **Phase 1** (1.1-1.3): Hero keys with metallic shader
2. **Phase 2** (2.1-2.2): Enhanced depth and gradient lighting
3. **Phase 3** (3.1-3.2): Staggered entrance animation
4. **Phase 4** (4.1): Multi-layer beveled chassis
5. **Phase 2.3**: Cast shadows (polish)

---

## Files to Modify

1. `lib/project/app/views/components/skills/keycap_component.dart`
2. `lib/project/app/views/components/skills/skills_keyboard_component.dart`
3. `lib/project/app/config/game_layout.dart`
4. `lib/project/app/system/game_component_factory.dart`
5. `lib/project/app/system/scroll_controller/skills_page_controller.dart`

---

## Configuration Changes

**File**: `lib/project/app/config/game_layout.dart`
```dart
// Change
static const double keyboardKeyDepth = 10.0; // → 20.0

// Optional: Add
static const double keyboardHeroKeySize = 80.0;
```

---

## Verification

### Visual Tests
1. Flutter/Dart/Flame keys are square (80×80) with metallic shine
2. Keys respond to god ray with dynamic lighting
3. Keys pop in with stagger (row-by-row, then left-to-right)
4. 20px depth visible with gradient lighting
5. Multi-layer chassis with beveled appearance

### Scroll Positions
- 11200: Stagger begins
- 11600: All keys visible
- 12800: Hold phase
- 13200: Exit begins

### Performance
- Maintain 60 FPS during animations
- Shader rendering smooth (only 3 keys)

---

## Edge Cases

1. **Hero Key Layout**: Dynamically calculate row widths for mixed sizes
2. **Game Reference**: Add `HasGameReference` mixin to access god ray
3. **DPR Coordinates**: Use `game.canvasSize / game.size` for shader
4. **Opacity Propagation**: Respect parent opacity in per-key animations

---

## Rollback Plan

Each phase independent:
- Phase 1: Remove shader parameter
- Phase 2.1: Revert depth to 10px
- Phase 3: Remove stagger system
- Phase 4: Simplify chassis to single layer

---

## Expected Outcome

A cinematic 3D keyboard with:
- Premium metallic hero keys (Flutter/Dart/Flame)
- Enhanced depth with proper shadows
- Engaging staggered entrance
- Consistent with existing theme
- 60 FPS performance maintained
