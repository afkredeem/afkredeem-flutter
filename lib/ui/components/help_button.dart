import 'package:flutter/material.dart';

import 'package:afk_redeem/ui/appearance_manager.dart';
import 'package:afk_redeem/ui/components/carousel_dialog.dart';

Widget helpButton({required Function() onPressed}) {
  return Container(
    width: 25.0,
    child: TextButton(
      style: ElevatedButton.styleFrom(
        shape: CircleBorder(),
        primary: AppearanceManager().color.main.withOpacity(0.2),
      ),
      onPressed: onPressed,
      child: Text(
        '?',
        style: TextStyle(
          fontSize: 16.0,
          color: AppearanceManager().color.appBarText.withOpacity(0.5),
        ),
      ),
    ),
  );
}

Widget carouselDialogHelpButton(
    {required BuildContext context, required List<Widget> carouselItems}) {
  return helpButton(onPressed: () {
    showDialog<String>(
      context: context,
      builder: (_) => carouselDialog(context, carouselItems),
    );
  });
}
