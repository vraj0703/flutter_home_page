import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter_home_page/project/app/models/philosophy_card_data.dart';
import 'package:flutter_home_page/project/app/system/scroll_orchestrator.dart';
import 'package:flutter_home_page/project/app/widgets/my_game.dart';

import 'philosophy_card.dart';

class PeelingCardStackComponent extends PositionComponent
    with HasGameReference<MyGame>
    implements OpacityProvider {
  final ScrollOrchestrator scrollOrchestrator;
  final List<PhilosophyCardData> cardsData;
  late final List<PhilosophyCard> _cards = [];

  double _opacity = 0.0;

  @override
  double get opacity => _opacity;

  @override
  set opacity(double value) {
    _opacity = value;
    for (final card in _cards) {
      card.parentOpacity = _opacity;
    }
  }

  // Configuration
  final bool isEmptyStack;
  final double entranceStart;
  final double entranceEnd;
  final double peelStart;

  PeelingCardStackComponent({
    required this.scrollOrchestrator,
    this.cardsData = const [],
    this.isEmptyStack = false,
    super.position,
    super.size,
    this.entranceStart = 1600,
    this.entranceEnd = 1800,
    this.peelStart = 1800,
  });

  @override
  Future<void> onLoad() async {
    // 1. Determine Data Source
    final List<PhilosophyCardData?> activeData;
    if (isEmptyStack || cardsData.isEmpty) {
      // Create 4 Empty Cards if stack is empty (Fallback)
      activeData = List.generate(4, (index) => null);
    } else {
      activeData = cardsData;
    }

    // 2. Card Size
    // Square format as requested
    final cardSize = Vector2(550, 250);
    final centerPos = size / 2;

    // 3. Create Cards (Reverse Order)
    for (int i = activeData.length - 1; i >= 0; i--) {
      final data = activeData[i];
      final card = PhilosophyCard(
        data: data,
        index: i,
        totalCards: activeData.length,
      );
      card.size = cardSize;
      card.position = centerPos;
      card.anchor = Anchor.center;
      // Index 0 (Top) has highest priority
      card.priority = (activeData.length - i) * 10;

      add(card);
      _cards.add(card);

      card.parentOpacity = _opacity;

      // Start hidden. Controller will set to 1.0 when active.
      card.opacity = 0.0;
    }

    // Sort local list by index for logical operations
    _cards.sort((a, b) => a.index.compareTo(b.index));

    // Philosophy Page manages opacity manually via Controller.
    // So we skip internal bindings if we are in that mode.
    // If cardsData is provided, we assume we want external control (Controller).
    if (isEmptyStack && cardsData.isEmpty) {
      // Legacy mode (if ever used)
      _applyBindings();
    }
  }

  // Expose cards for Manual Control by Controller
  List<PhilosophyCard> get cards => _cards;

  void _applyBindings() {
    _bindEntrance(entranceStart, entranceEnd);
    _bindPeel(peelStart);
  }

  void _bindPeel(double startScroll) {
    // (Simplified logic kept for fallback, but likely unused in this flow)
  }

  void _bindEntrance(double startScroll, double endScroll) {
    // (Simplified logic kept for fallback)
  }
}
