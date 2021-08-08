import 'package:flutter/material.dart';

import 'package:afk_redeem/ui/appearance_manager.dart';

class LoaderOverlay {
  static OverlayEntry? overlayEntry;
  static void show(BuildContext context) {
    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 0,
        left: 0,
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        child: Material(
          type: MaterialType.transparency,
          child: SizedBox.expand(
            child: Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: CircularProgressIndicator(
                  color: AppearanceManager().color.main,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    Overlay.of(context)!.insert(overlayEntry!);
  }

  static void hide({Duration? delay}) {
    overlayEntry?.remove();
    overlayEntry = null;
  }
}
