import 'package:flame/components.dart';
import 'package:flutter_home_page/project/app/config/game_layout.dart';
import 'package:flutter_home_page/project/app/config/scroll_sequence_config.dart';
import 'package:flutter_home_page/project/app/models/philosophy_card_data.dart';
import 'package:flutter_home_page/project/app/system/scroll_orchestrator.dart';
import 'package:flutter_home_page/project/app/views/my_game.dart';

import 'philosophy_card.dart';

class PeelingCardStackComponent extends PositionComponent
    with HasGameReference<MyGame> {
  final ScrollOrchestrator scrollOrchestrator;
  final List<PhilosophyCardData> cardsData;
  late final List<PhilosophyCard> _cards = [];

  double _opacity = 0.0;

  double get opacity => _opacity;

  set opacity(double value) {
    _opacity = value;
    for (final card in _cards) {
      card.parentOpacity = _opacity;
    }
  }

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
    this.entranceStart = ScrollSequenceConfig.philosophyStart,
    this.entranceEnd = ScrollSequenceConfig.philosophyFadeInEnd,
    this.peelStart = ScrollSequenceConfig.philosophyPeelStart,
  });

  @override
  Future<void> onLoad() async {
    final List<PhilosophyCardData?> activeData;
    if (isEmptyStack || cardsData.isEmpty) {
      activeData = List.generate(4, (index) => null);
    } else {
      activeData = cardsData;
    }

    final cardSize = GameLayout.cardSize;
    final centerPos = size / 2;

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

      card.priority = (activeData.length - i) * 10;

      add(card);
      _cards.add(card);

      card.parentOpacity = _opacity;

      card.opacity = 0.0;
    }

    _cards.sort((a, b) => a.index.compareTo(b.index));

    if (isEmptyStack && cardsData.isEmpty) {
      // Legacy mode (if ever used)
      _applyBindings();
    }
  }

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
