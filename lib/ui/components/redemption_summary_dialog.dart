import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:math';

import 'package:afk_redeem/data/redemption_code.dart';
import 'package:afk_redeem/data/error_reporter.dart';
import 'package:afk_redeem/data/user_redeem_summary.dart';
import 'package:afk_redeem/ui/appearance_manager.dart';
import 'package:afk_redeem/ui/components/carousel_dialog.dart';

AlertDialog redemptionSummaryDialog(
  BuildContext context,
  bool shouldReportNotFoundExpired,
  List<AccountRedeemSummary> accountRedeemSummaries,
) {
  bool hasAlreadyReported = false;
  int maxCodesDisplayLines =
      accountRedeemSummaries.map((s) => s.codesDisplayLines).reduce(max);
  int baseHeight = accountRedeemSummaries.length > 1 ? 140 : 100;
  double height = (baseHeight + (15 * maxCodesDisplayLines)).toDouble();
  double width = 300;
  return AlertDialog(
    title: Text('Summary'),
    titlePadding: EdgeInsets.only(top: 15.0, left: 20.0),
    contentPadding: EdgeInsets.fromLTRB(10.0, 20.0, 10.0, 10.0),
    content: Container(
      height: height,
      width: width,
      padding: EdgeInsets.zero,
      margin: EdgeInsets.zero,
      child: CarouselViewer(
        accountRedeemSummaries.map((AccountRedeemSummary accountRedeemSummary) {
          bool shouldAddReportNotFoundExpiredButton =
              shouldReportNotFoundExpired &&
                  (accountRedeemSummary.notFoundCodes.isNotEmpty ||
                      accountRedeemSummary.expiredCodes.isNotEmpty);
          return Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: width * 2 / 3,
                  ),
                  child: Container(
                    padding: EdgeInsets.all(10.0),
                    decoration: BoxDecoration(
                      color: AppearanceManager().color.dialogBackgroundOverlay,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          accountRedeemSummary.account.username,
                          style: TextStyle(
                            color: AppearanceManager().color.main,
                            fontSize: 17.0,
                          ),
                        ),
                        if (accountRedeemSummaries.length > 1)
                          Text(
                            'S${accountRedeemSummary.account.server}',
                            style: TextStyle(
                              color: AppearanceManager().color.dialogText,
                              fontSize: 14.0,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: Column(
                  children: [
                    codesList(context, accountRedeemSummary.redeemedCodes,
                        'Redeemed', AppearanceManager().color.green),
                    codesList(context, accountRedeemSummary.usedCodes,
                        'already used', AppearanceManager().color.yellow),
                    Row(
                      mainAxisAlignment: shouldAddReportNotFoundExpiredButton
                          ? MainAxisAlignment.spaceBetween
                          : MainAxisAlignment.center,
                      children: [
                        Column(
                          children: [
                            codesList(
                                context,
                                accountRedeemSummary.expiredCodes,
                                'expired',
                                AppearanceManager().color.red),
                            codesList(
                                context,
                                accountRedeemSummary.notFoundCodes,
                                'not found',
                                AppearanceManager().color.red),
                          ],
                        ),
                        if (shouldAddReportNotFoundExpiredButton)
                          ElevatedButton.icon(
                            onPressed: () async {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  AppearanceManager().snackBarStr('Thank you!',
                                      duration: Duration(seconds: 2)));
                              if (hasAlreadyReported) {
                                return;
                              }
                              String error = '';
                              if (accountRedeemSummary
                                  .notFoundCodes.isNotEmpty) {
                                error +=
                                    'not found codes: ${accountRedeemSummary.notFoundCodes} ';
                              }
                              if (accountRedeemSummary
                                  .expiredCodes.isNotEmpty) {
                                error +=
                                    'expired codes: ${accountRedeemSummary.expiredCodes}';
                              }
                              ErrorReporter.report(
                                  Exception('Bad redemption codes'), error);
                              hasAlreadyReported = true;
                            },
                            icon: Icon(
                              CupertinoIcons
                                  .arrowshape_turn_up_right_circle_fill,
                            ),
                            label: Text('report'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Center(
                child: Column(
                  children: [
                    if (accountRedeemSummary.redeemedCodes.isNotEmpty)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            CupertinoIcons.gift,
                            color: AppearanceManager().color.main,
                            size: 20.0,
                          ),
                          SizedBox(width: 15.0),
                          Icon(
                            CupertinoIcons.gift,
                            color: AppearanceManager().color.main,
                            size: 20.0,
                          ),
                          SizedBox(width: 15.0),
                          Icon(
                            CupertinoIcons.gift,
                            color: AppearanceManager().color.main,
                            size: 20.0,
                          ),
                        ],
                      ),
                    SizedBox(
                      height: 15.0,
                    )
                  ],
                ),
              ),
            ],
          );
        }).toList(),
        aspectRatio: width / height,
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
    textAlign: TextAlign.center,
    text: TextSpan(
      children: [
        TextSpan(
          text: '\n$title\n',
          style: TextStyle(color: color),
        ),
        TextSpan(
          text: '${codes.map((rc) => rc.code).join('\n')}\n',
          style: TextStyle(color: AppearanceManager().color.dialogText),
        ),
      ],
    ),
  );
}
