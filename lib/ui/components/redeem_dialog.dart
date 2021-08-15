import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:device_apps/device_apps.dart';

import 'package:afk_redeem/data/consts.dart';
import 'package:afk_redeem/data/redemption_code.dart';
import 'package:afk_redeem/data/services/code_redeemer.dart';
import 'package:afk_redeem/data/user_message.dart';
import 'package:afk_redeem/data/preferences.dart';
import 'package:afk_redeem/ui/appearance_manager.dart';
import 'package:afk_redeem/ui/components/help_button.dart';
import 'package:afk_redeem/ui/components/html_renderer.dart';
import 'package:afk_redeem/data/services/afk_redeem_api.dart';

class RedeemDialog {
  static Future<AlertDialog?> codes(
      BuildContext context,
      AfkRedeemApi afkRedeemApi,
      String userId,
      Set<RedemptionCode> redemptionCodes,
      Function() redeemRunningCallback,
      RedeemCompletedFunction redeemCompletedCallback,
      UserErrorHandler redeemErrorCallback) async {
    if (!Preferences().isRedeemApiVersionSupported) {
      if (Preferences().isRedeemApiVersionUpgradable) {
        return _suggestVersionUpgrade(context, afkRedeemApi);
      } else {
        Clipboard.setData(ClipboardData(text: userId));
        for (RedemptionCode redemptionCode in redemptionCodes) {
          Clipboard.setData(ClipboardData(text: redemptionCode.code));
        }
        return _apiVersionNotSupported(context, afkRedeemApi);
      }
    }
    TextEditingController verificationCodeController = TextEditingController();
    ElevatedButton redeemButton = ElevatedButton(
      onPressed: () {
        if (verificationCodeController.text == '') {
          ScaffoldMessenger.of(context).showSnackBar(
              AppearanceManager().errorSnackBar(UserMessage.cantBeEmpty));
          return;
        }
        CodeRedeemer(
          uid: userId,
          verificationCode: verificationCodeController.text,
          redemptionCodes: redemptionCodes,
          redeemCompleted: redeemCompletedCallback,
          userErrorHandler: redeemErrorCallback,
        ).redeem();
        Navigator.pop(context); // pop this dialog
        redeemRunningCallback();
      },
      style: ElevatedButton.styleFrom(
        minimumSize: Size(40, 40),
      ),
      child: Text(
        'Redeem!',
        style: TextStyle(fontSize: 18.0),
      ),
    );

    return AlertDialog(
      title: Text('Redeem Code${redemptionCodes.length > 1 ? 's' : ''}'),
      content: ListTile(
        minLeadingWidth: 0.0,
        contentPadding: EdgeInsets.symmetric(horizontal: 0.0),
        leading: Icon(
          CupertinoIcons.checkmark_shield,
          color: AppearanceManager().color.mainBright,
        ),
        title: TextField(
          autofocus: true,
          controller: verificationCodeController,
          style: TextStyle(
            fontSize: 18.0,
            color: AppearanceManager().color.text,
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9]'))
          ],
          decoration: InputDecoration(hintText: 'verification code'),
          onSubmitted: (value) {
            redeemButton.onPressed?.call();
          },
        ),
        trailing: _verificationCodeCarouselDialog(context),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _openAfkArenaButton,
              redeemButton,
            ],
          ),
        ),
      ],
    );
  }

  static Future<AlertDialog?> manualCode(
      BuildContext context,
      AfkRedeemApi afkRedeemApi,
      String userId,
      ClipboardData? clipboardData,
      Function() redeemRunningCallback,
      RedeemCompletedFunction redeemCompletedCallback,
      UserErrorHandler redeemErrorCallback) async {
    if (!Preferences().isRedeemApiVersionSupported) {
      if (Preferences().isRedeemApiVersionUpgradable) {
        return _suggestVersionUpgrade(context, afkRedeemApi);
      } else {
        Clipboard.setData(ClipboardData(text: userId));
        if (clipboardData != null) {
          Clipboard.setData(clipboardData);
        }
        return _apiVersionNotSupported(context, afkRedeemApi);
      }
    }
    TextEditingController redemptionCodeController = TextEditingController();
    TextEditingController verificationCodeController = TextEditingController();
    ElevatedButton redeemButton = ElevatedButton(
      onPressed: () {
        if (verificationCodeController.text == '' ||
            redemptionCodeController.text == '') {
          ScaffoldMessenger.of(context).showSnackBar(
              AppearanceManager().errorSnackBar(UserMessage.cantBeEmpty));
          return;
        }
        CodeRedeemer(
          uid: userId,
          verificationCode: verificationCodeController.text,
          redemptionCodes: {RedemptionCode(redemptionCodeController.text)},
          redeemCompleted: redeemCompletedCallback,
          userErrorHandler: redeemErrorCallback,
        ).redeem();
        Navigator.pop(context); // pop this dialog
        redeemRunningCallback();
      },
      child: Text(
        'Redeem!',
        style: TextStyle(fontSize: 16.0),
      ),
    );

    if (clipboardData != null &&
        clipboardData.text != null &&
        clipboardData.text!.length >= kMinPasteManualRedemptionCodeLength &&
        clipboardData.text!.length <= kMaxPasteManualRedemptionCodeLength) {
      redemptionCodeController.text = clipboardData.text!;
    }
    return AlertDialog(
      title: Text('Manually Redeem Code'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            minLeadingWidth: 0.0,
            contentPadding: EdgeInsets.symmetric(horizontal: 0.0),
            leading: Icon(
              CupertinoIcons.gift,
              color: AppearanceManager().color.mainBright,
            ),
            title: TextField(
              autofocus: true,
              controller: redemptionCodeController,
              style: TextStyle(
                fontSize: 18.0,
                color: AppearanceManager().color.text,
              ),
              decoration: InputDecoration(hintText: 'redemption code'),
              textInputAction: TextInputAction.next,
            ),
            trailing: SizedBox(
              width: 25.0,
            ),
          ),
          ListTile(
            minLeadingWidth: 0.0,
            contentPadding: EdgeInsets.symmetric(horizontal: 0.0),
            leading: Icon(
              CupertinoIcons.checkmark_shield,
              color: AppearanceManager().color.mainBright,
            ),
            title: TextField(
              autofocus: true,
              controller: verificationCodeController,
              style: TextStyle(
                fontSize: 18.0,
                color: AppearanceManager().color.text,
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9]'))
              ],
              decoration: InputDecoration(hintText: 'verification code'),
              onSubmitted: (value) {
                redeemButton.onPressed?.call();
              },
            ),
            trailing: _verificationCodeCarouselDialog(context),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _openAfkArenaButton,
              redeemButton,
            ],
          ),
        ),
      ],
    );
  }

  static Future<AlertDialog?> _apiVersionNotSupported(
      BuildContext context, AfkRedeemApi afkRedeemApi) async {
    String? html = await HtmlRenderer.getHtml(
      context: context,
      uri: kFlutterHtmlUri.redeemNotSupported,
      afkRedeemApi: afkRedeemApi,
    );
    Html? htmlWidget = HtmlRenderer.tryRender(context, html);
    if (htmlWidget == null) {
      return null;
    }
    return AlertDialog(
      title: Text(HtmlRenderer.getTitle(html) ?? 'Oh no  😕'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          htmlWidget,
          SizedBox(
            height: 15.0,
          ),
          Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // pop this dialog
                String? buttonLink =
                    HtmlRenderer.lastRenderButtonLinks['Web Redeem'];
                if (buttonLink != null) {
                  launch(buttonLink);
                }
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(CupertinoIcons.globe),
                  SizedBox(
                    width: 5.0,
                  ),
                  Text(
                    'Web Redeem',
                    style: TextStyle(fontSize: 16.0),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Future<AlertDialog?> _suggestVersionUpgrade(
      BuildContext context, AfkRedeemApi afkRedeemApi) async {
    String? html = await HtmlRenderer.getHtml(
      context: context,
      uri: kFlutterHtmlUri.upgradeApp,
      afkRedeemApi: afkRedeemApi,
    );
    Html? htmlWidget = HtmlRenderer.tryRender(context, html);
    if (htmlWidget == null) {
      return null;
    }
    return AlertDialog(
      title: Text(HtmlRenderer.getTitle(html) ?? 'Upgrade Required'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          htmlWidget,
          SizedBox(
            height: 15.0,
          ),
          Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // pop this dialog
                String? upgradeLink =
                    HtmlRenderer.lastRenderButtonLinks[Platform.isAndroid
                        ? 'android-upgrade'
                        : Platform.isIOS
                            ? 'ios-upgrade'
                            : null];
                if (upgradeLink != null) {
                  launch(upgradeLink);
                }
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(CupertinoIcons.square_arrow_up_on_square),
                  SizedBox(
                    width: 5.0,
                  ),
                  Text(
                    'Upgrade',
                    style: TextStyle(fontSize: 16.0),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _openAfkArenaButton = FutureBuilder<Application?>(
    future: DeviceApps.getApp(kAfkArenaStorePackage),
    builder: (BuildContext context, AsyncSnapshot<Application?> snapshot) {
      if (!snapshot.hasData || snapshot.data == null) {
        return Container();
      }
      // app is installed
      return InkWell(
        onTap: () {
          snapshot.data!.openApp();
        },
        splashColor: AppearanceManager().color.main.withOpacity(0.5),
        child: Ink(
          height: 45,
          width: 45,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('images/afk_arena_icon.png'),
              fit: BoxFit.cover,
            ),
          ),
        ),
      );
    },
  );

  static Widget _verificationCodeCarouselDialog(BuildContext context) {
    return carouselDialogHelpButton(
      context: context,
      carouselItems: [
        Image.asset('images/game_screenshots/player.jpg'),
        Image.asset('images/game_screenshots/game_settings.jpg'),
        Image.asset('images/game_screenshots/verification_code.jpg'),
      ],
    );
  }
}
