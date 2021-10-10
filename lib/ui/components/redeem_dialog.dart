import 'dart:math';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:device_apps/device_apps.dart';
import 'package:flutter_animation_progress_bar/flutter_animation_progress_bar.dart';

import 'package:afk_redeem/data/consts.dart';
import 'package:afk_redeem/data/redemption_code.dart';
import 'package:afk_redeem/data/services/code_redeemer.dart';
import 'package:afk_redeem/data/user_message.dart';
import 'package:afk_redeem/data/preferences.dart';
import 'package:afk_redeem/data/services/afk_redeem_api.dart';
import 'package:afk_redeem/data/account_redeem_summary.dart';
import 'package:afk_redeem/data/error_reporter.dart';
import 'package:afk_redeem/ui/appearance_manager.dart';
import 'package:afk_redeem/ui/components/help_button.dart';
import 'package:afk_redeem/ui/components/html_renderer.dart';
import 'package:afk_redeem/ui/components/carousel_dialog.dart';

enum RedeemDialogState {
  fillForm,
  running,
  summary,
  error,
}

enum AdLoadingStatus {
  init,
  loading,
  success,
  failure,
}

class RedeemDialog extends StatefulWidget {
  final AfkRedeemApi afkRedeemApi;
  final String userId;
  final RedeemSummaryFunction redeemCompletedHandler;
  final Set<RedemptionCode>? redemptionCodes;
  final ClipboardData? clipboardData;

  RedeemDialog({
    required this.afkRedeemApi,
    required this.userId,
    required this.redeemCompletedHandler,
    this.redemptionCodes,
    this.clipboardData,
  });

  @override
  _RedeemDialogState createState() => _RedeemDialogState();
}

class _RedeemDialogState extends State<RedeemDialog> {
  static const Duration kProgressBarAnimatedDuration =
      Duration(milliseconds: 500);
  static const Duration kProgressBarExtraWaitAnimationFinish =
      Duration(milliseconds: 120);
  TextEditingController redemptionCodeController = TextEditingController();
  TextEditingController verificationCodeController = TextEditingController();
  final tooltipKey = GlobalKey<State<Tooltip>>();

  static FirebaseAnalytics analytics = FirebaseAnalytics();
  static final AdRequest adRequest = AdRequest(
    keywords: kAdsKeywords,
    nonPersonalizedAds: true,
  );
  BannerAd? _adBanner;
  AdLoadingStatus _adBannerLoadingStatus = AdLoadingStatus.init;
  late Widget _adWidget = _createAdWidget();

  late bool isManualRedeem = widget.redemptionCodes == null;
  late CodeRedeemer codeRedeemer;
  late RedeemHandlers _redeemHandlers = RedeemHandlers(
    redeemRunningHandler: _redeemRunning,
    progressHandler: _progressUpdate,
    accountSelectionHandler: _selectAccount,
    redeemCompletedHandler: _redeemCompleted,
    userErrorHandler: _redeemError,
  );

  RedeemDialogState redeemDialogState = RedeemDialogState.fillForm;
  List<AccountInfo> accounts = [];
  AccountInfo? selectedAccount;
  List<AccountRedeemSummary> accountRedeemSummaries = [];
  UserMessage? errorMessage;
  int progress = 0;
  bool selectAccount = false;
  bool showContinueButton = false;

  void reset() {
    _createAnchoredBanner(context);
    setState(() {
      accounts = [];
      selectedAccount = null;
      accountRedeemSummaries = [];
      errorMessage = null;
      progress = 0;
      selectAccount = false;
      showContinueButton = false;
      redeemDialogState = RedeemDialogState.fillForm;
    });
  }

  @override
  void initState() {
    super.initState();
    _createAnchoredBanner(context);
  }

  @override
  void dispose() {
    super.dispose();
    _adBanner?.dispose();
  }

  void _redeemRunning() {
    setState(() {
      redeemDialogState = RedeemDialogState.running;
    });
  }

  void _progressUpdate(int progress) async {
    setState(() {
      this.progress = progress;
    });
    if (progress == 100) {
      await Future.delayed(
          kProgressBarAnimatedDuration + kProgressBarExtraWaitAnimationFinish);
      setState(() {
        if (_adBannerLoadingStatus == AdLoadingStatus.success) {
          showContinueButton = true;
        } else {
          // skip summary continue button and send directly to summary screen
          redeemDialogState = RedeemDialogState.summary;
        }
      });
    }
  }

  void _selectAccount(List<AccountInfo> accounts) {
    setState(() {
      this.accounts = accounts;
      selectAccount = true;
      selectedAccount = accounts[0];
    });
  }

  void _redeemCompleted(List<AccountRedeemSummary> redeemSummaries) async {
    setState(() {
      accountRedeemSummaries = redeemSummaries;
    });
    analytics.logEvent(name: 'redeem_completed');
    await Future.delayed(
        kProgressBarAnimatedDuration + kProgressBarExtraWaitAnimationFinish);
    widget.redeemCompletedHandler(accountRedeemSummaries);
  }

  void _redeemError(UserMessage errorMessage) {
    if (errorMessage == UserMessage.verificationFailed) {
      analytics.logEvent(name: 'redeem_verification_failed');
    }
    this.errorMessage = errorMessage;
    redeemDialogState = RedeemDialogState.error;
  }

  static const Map<AccountRedeemStrategy, String> kAccountRedeemStrategyStr = {
    AccountRedeemStrategy.mainAccount: 'Main Account',
    AccountRedeemStrategy.allAccounts: 'ALL Accounts',
    AccountRedeemStrategy.select: 'Select...',
  };

  Widget _openAfkArenaButton = FutureBuilder<Application?>(
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

  Widget _verificationCodeCarouselDialogButton() {
    return carouselDialogHelpButton(
      context: context,
      carouselItems: [
        Image.asset('images/game_screenshots/player.jpg'),
        Image.asset('images/game_screenshots/game_settings.jpg'),
        Image.asset('images/game_screenshots/verification_code.jpg'),
      ],
    );
  }

  late AccountRedeemStrategy accountRedeemStrategy = isManualRedeem
      ? AccountRedeemStrategy.mainAccount
      : AccountRedeemStrategy.allAccounts;

  late Widget loadingWidget = Container(
    child: Center(
      child: CircularProgressIndicator(
        color: AppearanceManager().color.main,
      ),
    ),
  );

  late ElevatedButton redeemButton = ElevatedButton(
    onPressed: () {
      if (verificationCodeController.text == '' ||
          (isManualRedeem && redemptionCodeController.text == '')) {
        ScaffoldMessenger.of(context).showSnackBar(
            AppearanceManager().errorSnackBar(UserMessage.cantBeEmpty));
        return;
      }
      Set<RedemptionCode> redemptionCodes = widget.redemptionCodes ??
          {RedemptionCode(redemptionCodeController.text)};
      codeRedeemer = CodeRedeemer(
        uid: widget.userId,
        accountRedeemStrategy: accountRedeemStrategy,
        verificationCode: verificationCodeController.text,
        redemptionCodes: redemptionCodes,
        handlers: _redeemHandlers,
      );
      codeRedeemer.redeem();
      analytics.logEvent(
        name: isManualRedeem ? 'redeem_manual_code' : 'redeem_codes',
        parameters: {'codes': redemptionCodes.length},
      );
    },
    style: ElevatedButton.styleFrom(
      minimumSize: Size(40, 40),
    ),
    child: Text(
      'Redeem!',
      style: TextStyle(fontSize: 16.0),
    ),
  );

  Widget _apiVersionNotSupportedDialog() {
    return FutureBuilder<String?>(
      future: HtmlRenderer.getHtml(
        context: context,
        uri: kFlutterHtmlUri.redeemNotSupported,
        afkRedeemApi: widget.afkRedeemApi,
      ),
      builder: (BuildContext context, AsyncSnapshot<String?> htmlSnapshot) {
        Widget? htmlWidget;
        String? html;
        if (!htmlSnapshot.hasData) {
          htmlWidget = loadingWidget;
        } else {
          html = htmlSnapshot.data!;
          htmlWidget = HtmlRenderer.tryRender(context, html);
          if (htmlWidget == null) {
            htmlWidget = Container(
              child: Text(
                  'Unfortunately, Lilith Games changed their Redeem API,\n\n'
                  'so the app is unable to redeem codes until an update is issued.\n\n'
                  'We are working on it, and will update this message when an upgrade is available.'
                  'we\'ve put everything in the clipboard for your convenience.'),
            );
          }
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
      },
    );
  }

  Widget _suggestVersionUpgradeDialog() {
    return FutureBuilder<String?>(
      future: HtmlRenderer.getHtml(
        context: context,
        uri: kFlutterHtmlUri.upgradeApp,
        afkRedeemApi: widget.afkRedeemApi,
      ),
      builder: (BuildContext context, AsyncSnapshot<String?> htmlSnapshot) {
        Widget? htmlWidget;
        String? html;
        if (!htmlSnapshot.hasData) {
          htmlWidget = loadingWidget;
        } else {
          html = htmlSnapshot.data!;
          htmlWidget = HtmlRenderer.tryRender(context, html);
          if (htmlWidget == null) {
            htmlWidget = Container(
              child: Text(
                  'It appears that Lilith Games changed their Redeem API.\n\n'
                  'The good news is that our latest app version supports it.\n\n'
                  'Upgrade in order to redeem directly from the app.'),
            );
          }
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
      },
    );
  }

  Future<void> _createAnchoredBanner(BuildContext context) async {
    if (_adBannerLoadingStatus == AdLoadingStatus.loading) {
      return;
    }
    _adBannerLoadingStatus = AdLoadingStatus.loading;
    final BannerAd banner = BannerAd(
      size: AdSize(
        height: (0.85 * AdSize.mediumRectangle.height).round(),
        width: (0.85 * AdSize.mediumRectangle.width).round(),
      ),
      request: adRequest,
      adUnitId: getAdUnitId(
        android: 'ca-app-pub-7888384607520581/1024667510',
        ios: 'ca-app-pub-7888384607520581/4701872851',
      ),
      listener: BannerAdListener(
        onAdLoaded: (Ad ad) {
          setState(() {
            _adBanner = ad as BannerAd?;
          });
          _adBannerLoadingStatus = AdLoadingStatus.success;
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          _adBannerLoadingStatus = AdLoadingStatus.failure;
          analytics.logEvent(name: 'ad_failed_to_load');
          ad.dispose();
        },
        onAdOpened: (Ad ad) => analytics.logEvent(name: 'ad_opened'),
      ),
    );
    return banner.load();
  }

  Widget _createAdWidget() {
    if (_adBanner == null) {
      return Container();
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          color: AppearanceManager().color.dialogBackground,
          width: _adBanner!.size.width.toDouble(),
          height: _adBanner!.size.height.toDouble(),
          child: AdWidget(ad: _adBanner!),
        ),
        SizedBox(
          height: 20,
        ),
      ],
    );
  }

  AlertDialog fillFormDialog() {
    if (widget.clipboardData != null &&
        widget.clipboardData!.text != null &&
        widget.clipboardData!.text!.length >=
            kMinPasteManualRedemptionCodeLength &&
        widget.clipboardData!.text!.length <=
            kMaxPasteManualRedemptionCodeLength) {
      redemptionCodeController.text = widget.clipboardData!.text!;
    }
    return AlertDialog(
      title: Text('Redeem Codes'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isManualRedeem)
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  minLeadingWidth: 0.0,
                  contentPadding: EdgeInsets.symmetric(horizontal: 0.0),
                  leading: Icon(
                    CupertinoIcons.person,
                    color: AppearanceManager().color.mainBright,
                  ),
                  title: DropdownButton<AccountRedeemStrategy>(
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
                    onChanged:
                        (AccountRedeemStrategy? newAccountRedeemStrategy) {
                      setState(() {
                        accountRedeemStrategy = newAccountRedeemStrategy!;
                      });
                    },
                    items: AccountRedeemStrategy.values
                        .map<DropdownMenuItem<AccountRedeemStrategy>>(
                            (AccountRedeemStrategy accountRedeemStrategy) {
                      return DropdownMenuItem<AccountRedeemStrategy>(
                        value: accountRedeemStrategy,
                        child: Text(
                            kAccountRedeemStrategyStr[accountRedeemStrategy]!),
                      );
                    }).toList(),
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
                    keyboardType: TextInputType
                        .visiblePassword, // disable text prediction
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
              ],
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
            trailing: _verificationCodeCarouselDialogButton(),
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

  AlertDialog runningDialog() {
    return AlertDialog(
      title: Text(selectAccount ? 'Select Account' : 'Redeem Codes'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _adWidget,
          if (selectAccount)
            ListTile(
              minLeadingWidth: 0.0,
              contentPadding: EdgeInsets.symmetric(horizontal: 0.0),
              leading: Icon(
                CupertinoIcons.person,
                color: AppearanceManager().color.mainBright,
              ),
              title: DropdownButton<AccountInfo>(
                value: selectedAccount!,
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
                    selectedAccount = newAccount!;
                  });
                },
                items: accounts
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
              ),
            ),
          if (showContinueButton)
            Center(
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    redeemDialogState = RedeemDialogState.summary;
                  });
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(40, 40),
                ),
                child: Text(
                  'Summary',
                  style: TextStyle(fontSize: 16.0),
                ),
              ),
            ),
          if (!showContinueButton && !selectAccount)
            Column(
              children: [
                SizedBox(height: 9),
                Container(
                  width: _adBanner != null
                      ? 0.65 *
                          _adBanner!.size.width
                              .toDouble() // prevent weird progress bar from dancing
                      : 200,
                  child: Center(
                    child: FAProgressBar(
                      currentValue: progress,
                      displayText: '%',
                      backgroundColor:
                          AppearanceManager().color.dialogBackgroundOverlay,
                      progressColor: AppearanceManager().color.main,
                      animatedDuration: kProgressBarAnimatedDuration,
                      displayTextStyle: TextStyle(
                        fontSize: 16.0,
                        color: AppearanceManager().color.snackBarText,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 9),
              ],
            ),
        ],
      ),
      actions: [
        if (selectAccount)
          ElevatedButton(
            onPressed: () {
              selectAccount = false;
              codeRedeemer.redeemForAccount(selectedAccount!);
            },
            child: Text(
              'Redeem!',
              style: TextStyle(fontSize: 16.0),
            ),
          ),
      ],
    );
  }

  AlertDialog redeemSummaryDialog(
    BuildContext context,
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
          accountRedeemSummaries
              .map((AccountRedeemSummary accountRedeemSummary) {
            bool shouldAddReportNotFoundExpiredButton = !isManualRedeem &&
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
                        color:
                            AppearanceManager().color.dialogBackgroundOverlay,
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
                      _codesList(accountRedeemSummary.redeemedCodes, 'Redeemed',
                          AppearanceManager().color.green),
                      _codesList(accountRedeemSummary.usedCodes, 'already used',
                          AppearanceManager().color.yellow),
                      Row(
                        mainAxisAlignment: shouldAddReportNotFoundExpiredButton
                            ? MainAxisAlignment.spaceBetween
                            : MainAxisAlignment.center,
                        children: [
                          Column(
                            children: [
                              _codesList(accountRedeemSummary.expiredCodes,
                                  'expired', AppearanceManager().color.red),
                              _codesList(accountRedeemSummary.notFoundCodes,
                                  'not found', AppearanceManager().color.red),
                            ],
                          ),
                          if (shouldAddReportNotFoundExpiredButton)
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

  Widget _codesList(List<RedemptionCode> codes, String title, Color color) {
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

  AlertDialog errorDialog(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Error',
        style: TextStyle(color: AppearanceManager().color.red),
      ),
      content: Text(
        AppearanceManager().userMessages[errorMessage]!,
        style: TextStyle(
          color: AppearanceManager().color.dialogText,
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () {
            reset();
          },
          child: Text(
            'Back 👉🏼',
            style: TextStyle(fontSize: 16.0),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // validate api version
    if (!Preferences().isRedeemApiVersionSupported) {
      if (Preferences().isRedeemApiVersionUpgradable) {
        return _suggestVersionUpgradeDialog();
      } else {
        if (isManualRedeem) {
          Clipboard.setData(ClipboardData(text: widget.userId));
          if (widget.clipboardData != null) {
            Clipboard.setData(widget.clipboardData!);
          }
        } else {
          Clipboard.setData(ClipboardData(text: widget.userId));
          for (RedemptionCode redemptionCode in widget.redemptionCodes!) {
            Clipboard.setData(ClipboardData(text: redemptionCode.code));
          }
        }
        return _apiVersionNotSupportedDialog();
      }
    }

    switch (redeemDialogState) {
      case RedeemDialogState.fillForm:
        return fillFormDialog();
      case RedeemDialogState.running:
        return runningDialog();
      case RedeemDialogState.summary:
        return redeemSummaryDialog(context);
      case RedeemDialogState.error:
        return errorDialog(context);
    }
  }
}
