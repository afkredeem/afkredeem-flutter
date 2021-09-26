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
import 'package:afk_redeem/data/services/afk_redeem_api.dart';
import 'package:afk_redeem/data/user_redeem_summary.dart';
import 'package:afk_redeem/ui/appearance_manager.dart';
import 'package:afk_redeem/ui/components/help_button.dart';
import 'package:afk_redeem/ui/components/html_renderer.dart';

class RedeemDialog {
  static late CodeRedeemer codeRedeemer;

  static Widget _openAfkArenaButton = FutureBuilder<Application?>(
    future: DeviceApps.getApp(kAfkArenaStorePackage),
    builder: (
      BuildContext context,
      AsyncSnapshot<Application?> snapshot,
    ) {
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

  static Widget _verificationCodeCarouselDialogButton(BuildContext context) {
    return carouselDialogHelpButton(
      context: context,
      carouselItems: [
        Image.asset('images/game_screenshots/player.jpg'),
        Image.asset('images/game_screenshots/game_settings.jpg'),
        Image.asset('images/game_screenshots/verification_code.jpg'),
      ],
    );
  }

  static Future<AlertDialog?> codes(
    BuildContext context,
    AfkRedeemApi afkRedeemApi,
    String userId,
    Set<RedemptionCode> redemptionCodes,
    RedeemHandlers redeemHandlers,
  ) async {
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
        codeRedeemer = CodeRedeemer(
          uid: userId,
          accountRedeemStrategy: AccountRedeemStrategy.allAccounts,
          verificationCode: verificationCodeController.text,
          redemptionCodes: redemptionCodes,
          handlers: redeemHandlers,
        );
        codeRedeemer.redeem();
        Navigator.pop(context); // pop this dialog
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
            color: AppearanceManager().color.dialogText,
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
        trailing: _verificationCodeCarouselDialogButton(context),
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
    RedeemHandlers redeemHandlers,
  ) async {
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
    AccountRedeemStrategy accountRedeemStrategy =
        AccountRedeemStrategy.mainAccount;
    final tooltipKey = GlobalKey<State<Tooltip>>();
    ElevatedButton redeemButton = ElevatedButton(
      onPressed: () {
        if (verificationCodeController.text == '' ||
            redemptionCodeController.text == '') {
          ScaffoldMessenger.of(context).showSnackBar(
              AppearanceManager().errorSnackBar(UserMessage.cantBeEmpty));
          return;
        }
        codeRedeemer = CodeRedeemer(
          uid: userId,
          accountRedeemStrategy: accountRedeemStrategy,
          verificationCode: verificationCodeController.text,
          redemptionCodes: {RedemptionCode(redemptionCodeController.text)},
          handlers: redeemHandlers,
        );
        codeRedeemer.redeem();
        Navigator.pop(context); // pop this dialog
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
              CupertinoIcons.person,
              color: AppearanceManager().color.mainBright,
            ),
            title: AccountRedeemStrategyDropdown(
              onChanged: (AccountRedeemStrategy newAccountRedeemStrategy) {
                accountRedeemStrategy = newAccountRedeemStrategy;
              },
            ),
            trailing: Tooltip(
              padding: EdgeInsets.all(8.0),
              margin: EdgeInsets.all(20.0),
              key: tooltipKey,
              message: 'Main Account - your main AFK Arena account 👑\n\n' +
                  'ALL Accounts - not recommended for vip codes since those can only be redeemed for a single account\n\n' +
                  'Select... - will open an account selection dialog after pressing redeem & verifying',
              child: helpButton(onPressed: () {
                final dynamic tooltip = tooltipKey.currentState;
                tooltip?.ensureTooltipVisible();
              }),
            ),
          ),
          ListTile(
            minLeadingWidth: 0.0,
            contentPadding: EdgeInsets.symmetric(horizontal: 0.0),
            leading: Icon(
              CupertinoIcons.gift,
              color: AppearanceManager().color.mainBright,
            ),
            title: TextField(
              autofocus: true,
              keyboardType:
                  TextInputType.visiblePassword, // disable text prediction
              controller: redemptionCodeController,
              style: TextStyle(
                fontSize: 18.0,
                color: AppearanceManager().color.dialogText,
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
                color: AppearanceManager().color.dialogText,
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
            trailing: _verificationCodeCarouselDialogButton(context),
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

  static AlertDialog selectAccount(
    BuildContext context,
    List<AccountInfo> accounts,
  ) {
    AccountInfo selectedAccount = accounts[0];

    return AlertDialog(
      title: Text('Select Account'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 10.0,
          ),
          ListTile(
            minLeadingWidth: 0.0,
            contentPadding: EdgeInsets.symmetric(horizontal: 0.0),
            leading: Icon(
              CupertinoIcons.person,
              color: AppearanceManager().color.mainBright,
            ),
            title: AccountSelectionDropdown(
              accounts: accounts,
              onChanged: (AccountInfo account) {
                selectedAccount = account;
              },
            ),
          ),
        ],
      ),
      actions: [
        ElevatedButton(
          onPressed: () {
            codeRedeemer.redeemForAccount(selectedAccount);
            Navigator.pop(context); // pop this dialog
          },
          child: Text(
            'Redeem!',
            style: TextStyle(fontSize: 16.0),
          ),
        ),
      ],
    );
  }

  static Future<AlertDialog?> _apiVersionNotSupported(
    BuildContext context,
    AfkRedeemApi afkRedeemApi,
  ) async {
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
    BuildContext context,
    AfkRedeemApi afkRedeemApi,
  ) async {
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
                launch(kLinks.storeLink);
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
}

class AccountRedeemStrategyDropdown extends StatefulWidget {
  final Function(AccountRedeemStrategy)? onChanged;
  const AccountRedeemStrategyDropdown({this.onChanged});

  @override
  _AccountRedeemStrategyDropdownState createState() =>
      _AccountRedeemStrategyDropdownState();
}

class _AccountRedeemStrategyDropdownState
    extends State<AccountRedeemStrategyDropdown> {
  static const Map<AccountRedeemStrategy, String> kAccountRedeemStrategyStr = {
    AccountRedeemStrategy.mainAccount: 'Main Account',
    AccountRedeemStrategy.allAccounts: 'ALL Accounts',
    AccountRedeemStrategy.select: 'Select...',
  };

  AccountRedeemStrategy accountRedeemStrategy =
      AccountRedeemStrategy.mainAccount;

  @override
  Widget build(BuildContext context) {
    return DropdownButton<AccountRedeemStrategy>(
      value: accountRedeemStrategy,
      isExpanded: true,
      icon: Icon(CupertinoIcons.chevron_down),
      iconSize: 20,
      style: TextStyle(
        fontSize: 18.0,
        color: AppearanceManager().color.dialogText,
      ),
      dropdownColor: AppearanceManager().color.dialogBackground,
      underline: Container(
        height: 0.75,
        color: AppearanceManager().color.textFieldHiddenBorder,
      ),
      onChanged: (AccountRedeemStrategy? newAccountRedeemStrategy) {
        setState(() {
          accountRedeemStrategy = newAccountRedeemStrategy!;
        });
        widget.onChanged?.call(accountRedeemStrategy);
      },
      items: AccountRedeemStrategy.values
          .map<DropdownMenuItem<AccountRedeemStrategy>>(
              (AccountRedeemStrategy accountRedeemStrategy) {
        return DropdownMenuItem<AccountRedeemStrategy>(
          value: accountRedeemStrategy,
          child: Text(kAccountRedeemStrategyStr[accountRedeemStrategy]!),
        );
      }).toList(),
    );
  }
}

class AccountSelectionDropdown extends StatefulWidget {
  final List<AccountInfo> accounts;
  final Function(AccountInfo)? onChanged;
  const AccountSelectionDropdown({required this.accounts, this.onChanged});

  @override
  _AccountSelectionDropdownState createState() =>
      _AccountSelectionDropdownState();
}

class _AccountSelectionDropdownState extends State<AccountSelectionDropdown> {
  late AccountInfo account = widget.accounts[0];
  final tooltipKey = GlobalKey<State<Tooltip>>();

  @override
  Widget build(BuildContext context) {
    return DropdownButton<AccountInfo>(
      value: account,
      isExpanded: true,
      icon: Icon(CupertinoIcons.chevron_down),
      iconSize: 20,
      style: TextStyle(
        fontSize: 18.0,
        color: AppearanceManager().color.dialogText,
      ),
      dropdownColor: AppearanceManager().color.dialogBackground,
      underline: Container(
        height: 0.75,
        color: AppearanceManager().color.textFieldHiddenBorder,
      ),
      onChanged: (AccountInfo? newAccount) {
        setState(() {
          account = newAccount!;
        });
        widget.onChanged?.call(account);
      },
      items: widget.accounts
          .map<DropdownMenuItem<AccountInfo>>((AccountInfo account) {
        return DropdownMenuItem<AccountInfo>(
          value: account,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  account.username,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppearanceManager().color.main,
                    fontSize: 15.0,
                  ),
                ),
              ),
              if (account.isMain)
                Tooltip(
                  message: 'Main Account',
                  child: Text(
                    '👑',
                    style: TextStyle(
                      fontSize: 15.0,
                    ),
                  ),
                ),
              Text(
                '   S${account.server}',
                style: TextStyle(
                  color: AppearanceManager().color.dialogText,
                  fontSize: 15.0,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
