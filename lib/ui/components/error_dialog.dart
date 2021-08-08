import 'package:afk_redeem/data/user_message.dart';
import 'package:flutter/material.dart';

import 'package:afk_redeem/ui/appearance_manager.dart';

AlertDialog errorDialog(BuildContext context, UserMessage errorMessage) {
  return AlertDialog(
    title: Text(
      'Error',
      style: TextStyle(color: AppearanceManager().color.red),
    ),
    content: RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: AppearanceManager().userMessages[errorMessage],
            style: Theme.of(context).textTheme.bodyText1,
          ),
        ],
      ),
    ),
  );
}
