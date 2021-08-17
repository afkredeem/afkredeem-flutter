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
  List<UserRedeemSummary> usersRedeemSummary,
) {
  bool hasAlreadyReported = false;
  int maxCodesDisplayLines =
      usersRedeemSummary.map((s) => s.codesDisplayLines).reduce(max);
  int baseHeight = usersRedeemSummary.length > 1 ? 140 : 100;
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
        usersRedeemSummary
            .map(
              (UserRedeemSummary userRedeemSummary) => Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          userRedeemSummary.username,
                          style: TextStyle(
                            color: AppearanceManager().color.main,
                            fontSize: 17.0,
                          ),
                        ),
                        if (usersRedeemSummary.length > 1)
                          Text(
                            'S${userRedeemSummary.server}',
                            style: TextStyle(
                              color: AppearanceManager().color.mainBright,
                              fontSize: 14.0,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0),
                    child: Column(
                      children: [
                        codesList(context, userRedeemSummary.redeemedCodes,
                            'Redeemed', AppearanceManager().color.green),
                        codesList(context, userRedeemSummary.usedCodes,
                            'already used', AppearanceManager().color.yellow),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              children: [
                                codesList(
                                    context,
                                    userRedeemSummary.expiredCodes,
                                    'expired',
                                    AppearanceManager().color.red),
                                codesList(
                                    context,
                                    userRedeemSummary.notFoundCodes,
                                    'not found',
                                    AppearanceManager().color.red),
                              ],
                            ),
                            if (shouldReportNotFoundExpired &&
                                (userRedeemSummary.notFoundCodes.isNotEmpty ||
                                    userRedeemSummary.expiredCodes.isNotEmpty))
                              ElevatedButton.icon(
                                onPressed: () async {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      AppearanceManager().snackBarStr(
                                          'Thank you!',
                                          duration: Duration(seconds: 2)));
                                  if (hasAlreadyReported) {
                                    return;
                                  }
                                  String error = '';
                                  if (userRedeemSummary
                                      .notFoundCodes.isNotEmpty) {
                                    error +=
                                        'not found codes: ${userRedeemSummary.notFoundCodes} ';
                                  }
                                  if (userRedeemSummary
                                      .expiredCodes.isNotEmpty) {
                                    error +=
                                        'expired codes: ${userRedeemSummary.expiredCodes}';
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
                        if (userRedeemSummary.redeemedCodes.isNotEmpty)
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
                        // Text(
                        //   userRedeemSummary.redeemedCodes.isNotEmpty
                        //       ? '\n🎁       🎁       🎁'
                        //       : '',
                        //   style:
                        //       TextStyle(color: AppearanceManager().color.main),
                        // ),
                        SizedBox(
                          height: 15.0,
                        )
                      ],
                    ),
                  ),
                ],
              ),
            )
            .toList(),
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
          style: Theme.of(context).textTheme.bodyText1,
        ),
      ],
    ),
  );
}
