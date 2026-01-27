import 'package:flutter/material.dart' as material;
import 'package:flutter_home_page/project/app/config/component_ids.dart';
import 'package:flutter_home_page/project/app/config/game_assets.dart';
import 'package:flutter_home_page/project/app/config/game_layout.dart';
import 'package:flutter_home_page/project/app/config/game_strings.dart';
import 'package:flutter_home_page/project/app/config/game_styles.dart';
import 'package:flutter_home_page/project/app/interfaces/component_builder.dart';
import 'package:flutter_home_page/project/app/models/component_context.dart';
import 'package:flutter_home_page/project/app/views/components/bold_text/bold_text_reveal_component.dart';

class BoldTextRevealBuilder extends ComponentBuilder<BoldTextRevealComponent> {
  @override
  String get id => ComponentIds.boldTextReveal;

  @override
  int get priority => 0;

  @override
  Future<BoldTextRevealComponent> build(ComponentContext context) async {
    final shader = await context.loadShader(GameAssets.boldTextShader);
    final component = BoldTextRevealComponent(
      text: GameStrings.boldText,
      textStyle: material.TextStyle(
        fontSize: GameStyles.titleFontSize,
        fontWeight: material.FontWeight.w500,
        fontFamily: GameStyles.fontInconsolata,
        letterSpacing: 2.0,
      ),
      shader: shader,
      position: context.size / 2,
    );
    component.priority = GameLayout.zBoldText;
    component.opacity = 0.0;
    return component;
  }
}
