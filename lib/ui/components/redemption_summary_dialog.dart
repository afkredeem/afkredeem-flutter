import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'package:afk_redeem/data/redemption_code.dart';
import 'package:afk_redeem/ui/appearance_manager.dart';
import 'package:afk_redeem/data/error_reporter.dart';

AlertDialog redemptionSummaryDialog(
  BuildContext context,
  String username,
  bool shouldReportNotFoundExpired,
  List<RedemptionCode> redeemedCodes,
  List<RedemptionCode> usedCodes,
  List<RedemptionCode> notFoundCodes,
  List<RedemptionCode> expiredCodes,
) {
  bool hasAlreadyReported = false;
  return AlertDialog(
    title: Text('Summary'),
    content: IntrinsicHeight(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  codesList(context, notFoundCodes, 'not found',
                      AppearanceManager().color.red),
                  codesList(context, expiredCodes, 'expired',
                      AppearanceManager().color.red),
                ],
              ),
              if (shouldReportNotFoundExpired &&
                  (notFoundCodes.isNotEmpty || expiredCodes.isNotEmpty))
                ElevatedButton.icon(
                  onPressed: () async {
                    ScaffoldMessenger.of(context).showSnackBar(
                        AppearanceManager().snackBarStr('Thank you!',
                            duration: Duration(seconds: 2)));
                    if (hasAlreadyReported) {
                      return;
                    }
                    String error = '';
                    if (notFoundCodes.isNotEmpty) {
                      error += 'not found codes: $notFoundCodes ';
                    }
                    if (expiredCodes.isNotEmpty) {
                      error += 'expired codes: $expiredCodes';
                    }
                    ErrorReporter.report(
                        Exception('Bad redemption codes'), error);
                    hasAlreadyReported = true;
                  },
                  icon: Icon(
                    CupertinoIcons.arrowshape_turn_up_right_circle_fill,
                  ),
                  label: Text('report'),
                ),
            ],
          ),
          codesList(context, usedCodes, 'already used',
              AppearanceManager().color.yellow),
          codesList(context, redeemedCodes, 'Redeemed',
              AppearanceManager().color.green),
          Center(
            child: Column(
              children: [
                Text(
                  redeemedCodes.isNotEmpty ? '\n$username' : '',
                  style: TextStyle(color: AppearanceManager().color.main),
                ),
                Text(
                  redeemedCodes.isNotEmpty
                      ? '🎁🎁🎁 Your prizes await 🎁🎁🎁'
                      : '',
                  style: TextStyle(color: AppearanceManager().color.main),
                )
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

Widget codesList(BuildContext context, List<RedemptionCode> codes, String title,
    Color color) {
  if (codes.isEmpty) {
    return Container();
  }
  return RichText(
    text: TextSpan(
      children: [
        TextSpan(
          text: '\n$title\n',
          style: TextStyle(color: color),
        ),
        TextSpan(
          text: '${codes.map((rc) => rc.code).join('\n')}\n',
          style: Theme.of(context).textTheme.bodyText1,
        ),
      ],
    ),
  );
}
