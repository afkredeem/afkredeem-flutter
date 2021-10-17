import 'package:afk_redeem/data/preferences.dart';
import 'package:afk_redeem/data/user_message.dart';
import 'package:afk_redeem/ui/appearance_manager.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

import 'package:afk_redeem/data/redemption_code.dart';
import 'package:afk_redeem/ui/image_manager.dart';

class RedemptionCodeCard extends StatelessWidget {
  final RedemptionCode redemptionCode;
  final Function(RedemptionCode, {bool toggle}) redemptionCodeSelectedHandler;
  final Function() applyThemeHandler;

  static const kCommonScrollForceChristmasValue = 5;
  static int commonScrollForceChristmasCounter = 0;

  RedemptionCodeCard({
    required this.redemptionCode,
    required this.redemptionCodeSelectedHandler,
    required this.applyThemeHandler,
  });

  bool selected({toggle = false}) {
    return redemptionCodeSelectedHandler(redemptionCode, toggle: toggle);
  }

  void _onRedemptionCodeTap(BuildContext context, String giftKey) {
    if (ImageManager().contains('gifts/$giftKey')) {
      if (giftKey == 'diamonds' &&
          commonScrollForceChristmasCounter ==
              kCommonScrollForceChristmasValue &&
          !Preferences().forceChristmasTheme) {
        Preferences().forceChristmasTheme = true;
        applyThemeHandler();
        ScaffoldMessenger.of(context)
            .showSnackBar(AppearanceManager().snackBarStr(
          "🎅🏽🎅🏽🎅🏽   Christmas Forever!   🎅🏽🎅🏽🎅🏽",
          duration: Duration(seconds: 3),
        ));
      }
      if (giftKey == 'common_scrolls') {
        commonScrollForceChristmasCounter++;
      } else {
        commonScrollForceChristmasCounter = 0;
      }
      if (giftKey == 'stargazing_cards') {
        ScaffoldMessenger.of(context)
            .showSnackBar(AppearanceManager().snackBarStr(
          "You've already made the choice\nNow you have to understand it",
          duration: Duration(seconds: 3),
        ));
      }
      selected(toggle: true);
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(AppearanceManager().snackBarStr(giftKey.toString()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        selected(toggle: true);
        if (!redemptionCode.isActive) {
          ScaffoldMessenger.of(context).showSnackBar(
            AppearanceManager().snackBarStr(
              'Expired on ${DateFormat('MMM d, yyyy').format(redemptionCode.expiresAt!)}',
              duration: Duration(seconds: 2),
            ),
          );
        }
      },
      child: Container(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Transform.scale(
                              scale: 2,
                              child: Checkbox(
                                activeColor: redemptionCode.isExpired
                                    ? AppearanceManager().color.mainBright
                                    : AppearanceManager().color.main,
                                checkColor:
                                    AppearanceManager().color.background,
                                value: selected(),
                                shape: CircleBorder(),
                                onChanged: !redemptionCode.isActive
                                    ? null
                                    : (_) {
                                        selected(toggle: true);
                                      },
                              ),
                            ),
                            SizedBox(
                              width: 5.0,
                            ),
                            Stack(
                              alignment: Alignment.centerLeft,
                              children: [
                                GestureDetector(
                                  onLongPress: () {
                                    HapticFeedback.vibrate();
                                    Clipboard.setData(ClipboardData(
                                      text: redemptionCode.code,
                                    ));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        AppearanceManager().snackBar(
                                            UserMessage.copiedToClipboard));
                                  },
                                  child: Container(
                                    alignment: Alignment.bottomCenter,
                                    child: Text(
                                      redemptionCode.code,
                                      style: TextStyle(
                                          fontSize: 18.0,
                                          fontWeight:
                                              redemptionCode.shouldRedeem
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                          color: redemptionCode.shouldRedeem
                                              ? AppearanceManager()
                                                  .color
                                                  .boldText
                                              : AppearanceManager().color.text),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                Container(
                                  alignment: Alignment.bottomCenter,
                                  height: 55,
                                  child: Padding(
                                    padding: const EdgeInsets.only(left: 8.0),
                                    child: Text(
                                      redemptionCode.addedAt != null
                                          ? DateFormat('d MMM yy')
                                              .format(redemptionCode.addedAt!)
                                          : '',
                                      style: TextStyle(
                                          fontSize: 12.0,
                                          fontWeight:
                                              redemptionCode.shouldRedeem
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                          color: redemptionCode.shouldRedeem
                                              ? AppearanceManager()
                                                  .color
                                                  .boldText
                                              : AppearanceManager()
                                                  .color
                                                  .dateText),
                                    ),
                                  ),
                                ),
                                if (redemptionCode.isExpired &&
                                    redemptionCode.isActive)
                                  Positioned(
                                    top: 3,
                                    left: 10,
                                    child: RotationTransition(
                                      turns: AlwaysStoppedAnimation(15 / 360),
                                      child: GestureDetector(
                                        onTap: () {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            AppearanceManager().snackBarStr(
                                              'Expired on ${DateFormat('MMM d, yyyy').format(redemptionCode.expiresAt!)}',
                                              duration: Duration(seconds: 2),
                                            ),
                                          );
                                        },
                                        child: Container(
                                          alignment: Alignment.bottomCenter,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.rectangle,
                                            borderRadius:
                                                BorderRadius.circular(3),
                                            color: AppearanceManager()
                                                .color
                                                .expiredLabel,
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 1.0,
                                              horizontal: 6.0,
                                            ),
                                            child: Text(
                                              'EXPIRED',
                                              style: TextStyle(
                                                color: selected()
                                                    ? AppearanceManager()
                                                        .color
                                                        .mainBright
                                                    : AppearanceManager()
                                                        .color
                                                        .main,
                                                fontSize: 12.0,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            for (MapEntry gift in redemptionCode.gifts.entries)
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      GestureDetector(
                                        behavior: HitTestBehavior.translucent,
                                        onTap: () {
                                          _onRedemptionCodeTap(
                                              context, gift.key);
                                        },
                                        child: Container(
                                          height: 40,
                                          width: 40,
                                          child: ImageManager()
                                              .get('gifts/${gift.key}'),
                                        ),
                                      ),
                                      Container(
                                        height: 70,
                                        width: 35,
                                        alignment: Alignment.bottomCenter,
                                        child: Text(
                                          gift.value,
                                          style: TextStyle(
                                            color: redemptionCode.shouldRedeem
                                                ? AppearanceManager()
                                                    .color
                                                    .boldText
                                                : AppearanceManager()
                                                    .color
                                                    .giftText,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(
                                    width: 5,
                                  ),
                                ],
                              )
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Divider(
                color: AppearanceManager().color.mainBright,
                height: 10,
              )
            ],
          ),
        ),
      ),
    );
  }
}
