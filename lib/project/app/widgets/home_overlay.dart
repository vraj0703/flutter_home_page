import 'package:flutter/material.dart';
// import 'package:flutter_ui_base/common_libs.dart'; // Removed as it doesn't exist
import 'package:google_fonts/google_fonts.dart';

class HomeOverlay extends StatefulWidget {
  final Widget child; // The GameWidget will be passed here
  final ValueNotifier<bool> showOverlayNotifier;

  const HomeOverlay({
    super.key,
    required this.child,
    required this.showOverlayNotifier,
  });

  @override
  State<HomeOverlay> createState() => _HomeOverlayState();
}

class _HomeOverlayState extends State<HomeOverlay> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Layer 0: The Game
        widget.child,

        // Layer 1: Overlay UI
        ValueListenableBuilder<bool>(
          valueListenable: widget.showOverlayNotifier,
          builder: (context, show, child) {
            return AnimatedOpacity(
              opacity: show ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOut, // Motion Designer specs
              child: IgnorePointer(
                ignoring: !show,
                child: Stack(
                  children: [
                    // Top Right: Language & Menu
                    Positioned(
                      top: 40,
                      right: 40,
                      child: Row(
                        children: [
                          // _buildLanguageSwitcher(), // Removed
                          // const SizedBox(width: 20), // Removed
                          _buildMenuCircle(),
                        ],
                      ),
                    ),

                    // Bottom: Scroll to Proceed
                    Positioned(
                      bottom: 50,
                      left: 0,
                      right: 0,
                      child: Center(child: _buildScrollPrompt()),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // Language Switcher Methods Removed

  Widget _buildMenuCircle() {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      // Icon or Menu lines would go here
    );
  }

  Widget _buildScrollPrompt() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        "SCROLL TO PROCEED",
        style: GoogleFonts.roboto(
          color: Colors.black,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          fontSize: 12,
        ),
      ),
    );
  }
}
