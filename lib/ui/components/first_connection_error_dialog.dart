import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:afk_redeem/data/consts.dart';
import 'package:afk_redeem/ui/appearance_manager.dart';

AlertDialog firstConnectionErrorDialog(BuildContext context) {
  return AlertDialog(
    title: Text(
      'First Connection Error',
    ),
    content: SelectableText.rich(
      TextSpan(
        children: [
          TextSpan(
            text:
                'First connection errors usually hint a problem with securely verifying the connection to our server ',
            style: Theme.of(context).textTheme.bodyText1,
          ),
          TextSpan(
            text: 'afkredeem.com',
            style: TextStyle(color: AppearanceManager().color.main),
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                launch(kLinks.afkRedeem);
              },
          ),
          TextSpan(
            text:
                ' for the first time.\n(aka approving our SSL key or resolving our DNS for the first time).\n\n',
            style: Theme.of(context).textTheme.bodyText1,
          ),
          TextSpan(
            text:
                'This usually happens when you\'re in a public WiFi network your phone doesn\'t fully trust (which is good security-wise).\n\n',
            style: Theme.of(context).textTheme.bodyText1,
          ),
          TextSpan(
            text:
                'To fix this problem try changing your WiFi network or switch WiFi <-> mobile-data, and pull-to-refresh to retry.\n',
            style: Theme.of(context).textTheme.bodyText1,
          ),
          TextSpan(
            text: '- required only for first connection -',
            style: Theme.of(context).textTheme.bodyText1,
          ),
        ],
      ),
    ),
  );
}
