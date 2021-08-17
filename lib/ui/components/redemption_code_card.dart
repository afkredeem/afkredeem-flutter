import 'package:afk_redeem/data/user_message.dart';
import 'package:afk_redeem/ui/appearance_manager.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

import 'package:afk_redeem/data/redemption_code.dart';
import 'package:afk_redeem/ui/image_manager.dart';

class RedemptionCodeCard extends StatelessWidget {
  final RedemptionCode redemptionCode;
  final Function(RedemptionCode, {bool toggle}) redemptionCodeSelected;

  RedemptionCodeCard(this.redemptionCode, this.redemptionCodeSelected);

  bool selected({toggle = false}) {
    return redemptionCodeSelected(redemptionCode, toggle: toggle);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        selected(toggle: true);
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
                                activeColor: AppearanceManager().color.main,
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
                                          if (ImageManager()
                                              .contains('gifts/${gift.key}')) {
                                            if (gift.key ==
                                                'stargazing_cards') {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                      AppearanceManager()
                                                          .snackBarStr(
                                                "You've already made the choice\nYou're here to understand why you've made it",
                                                duration: Duration(seconds: 3),
                                              ));
                                            } else {
                                              selected(toggle: true);
                                            }
                                          } else {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                                    AppearanceManager()
                                                        .snackBarStr(gift.key
                                                            .toString()));
                                          }
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
