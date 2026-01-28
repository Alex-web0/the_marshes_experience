import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/heritage_repository.dart';

// --- Theme / Constants ---
final kGameFont = GoogleFonts.pixelifySans();
final kDisplayFont = GoogleFonts.notoSansCuneiform(); // Note: Fallback might be needed if not available immediately

// --- Glass Container Helper ---
class LiquidGlassContainer extends StatelessWidget {
  final Widget child;
  final double opacity;
  final double blur;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;

  const LiquidGlassContainer({
    required this.child, 
    this.opacity = 0.1, 
    this.blur = 15.0, 
    this.padding,
    this.borderRadius = 20.0,
    super.key
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding ?? const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(opacity),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.1),
                Colors.white.withOpacity(0.05),
              ],
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

// --- Main Menu Overlay ---
class LiquidGlassMenu extends StatelessWidget {
  final VoidCallback onPlay;
  final VoidCallback onVisitWebsite;

  const LiquidGlassMenu({
    required this.onPlay,
    required this.onVisitWebsite,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: LiquidGlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "THE MARSHES",
              style: kDisplayFont.copyWith(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              "EXPERIENCE",
              style: kGameFont.copyWith(fontSize: 24, color: Colors.white70),
            ),
            const SizedBox(height: 50),
            _GlassButton(label: "PLAY", onTap: onPlay),
            const SizedBox(height: 20),
            _GlassButton(label: "OUR TEAM", onTap: () {}), // Todo: Team Dialog
            const SizedBox(height: 20),
            _GlassButton(label: "VISIT WEBSITE", onTap: onVisitWebsite),
          ],
        ),
      ),
    );
  }
}

class _GlassButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  
  const _GlassButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 200,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),

          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Center(
          child: Text(
            label, 
            style: kGameFont.copyWith(fontSize: 18, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

// --- Heritage Dialog (Story Mode) ---
// --- Heritage Dialog (Story Mode) ---
class HeritageStoryDialog extends StatefulWidget {
  final HeritageFact fact;
  final VoidCallback onDismiss;

  const HeritageStoryDialog({
    required this.fact,
    required this.onDismiss,
    super.key,
  });

  @override
  State<HeritageStoryDialog> createState() => _HeritageStoryDialogState();
}

class _HeritageStoryDialogState extends State<HeritageStoryDialog> with SingleTickerProviderStateMixin {
  bool _isFinished = false;
  late AnimationController _cursorController;

  @override
  void initState() {
    super.initState();
    _cursorController = AnimationController(
       vsync: this, 
       duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _cursorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent, // Ensure taps on empty space are caught
      onTap: () {
        if (_isFinished) {
          widget.onDismiss();
        } 
      },
      child: Stack(
        children: [
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(16.0), // Margin added
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20), // Rounded corners
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), // Glassmorphism
                  child: Container(
                    height: MediaQuery.of(context).size.height * 0.33,
                    width: double.infinity,
                    padding: const EdgeInsets.all(20.0),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6), // Slight opacity (60%)
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white, width: 2.0), // Border all sides
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                         // Avatar
                         CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.amber,
                            child: Icon(Icons.person, color: Colors.white),
                         ),
                         const SizedBox(width: 15),
                         
                         // Text Area
                         Expanded(
                           child: Column(
                             crossAxisAlignment: CrossAxisAlignment.start,
                             children: [
                                Text(widget.fact.speakerName, 
                                  style: kDisplayFont.copyWith(fontSize: 22, color: Colors.yellowAccent, fontWeight: FontWeight.bold) // Bigger Name
                                ),
                                const SizedBox(height: 10),
                                Expanded(
                                  child: DefaultTextStyle(
                                   style: kGameFont.copyWith(fontSize: 18, color: Colors.white),
                                   child: AnimatedTextKit(
                                     animatedTexts: [
                                       TypewriterAnimatedText(
                                          "${widget.fact.factText} ...continue", 
                                          speed: const Duration(milliseconds: 50),
                                          cursor: '' // Hide default cursor if any
                                       ),
                                     ],
                                     isRepeatingAnimation: false,
                                     onFinished: () {
                                        setState(() => _isFinished = true);
                                     },
                                   ),
                                 ),
                                ),
                                if (_isFinished)
                                  Align(
                                    alignment: Alignment.bottomRight,
                                    child: FadeTransition(
                                      opacity: _cursorController,
                                      child: Container(
                                        width: 15, 
                                        height: 25, 
                                        color: Colors.white, // Block cursor
                                      ),
                                    ),
                                  )
                             ],
                           ),
                         )
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
