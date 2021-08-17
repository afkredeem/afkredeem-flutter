import 'dart:async';
import 'package:bubble/bubble.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:animated_text_kit/animated_text_kit.dart';

import 'package:afk_redeem/data/preferences.dart';
import 'package:afk_redeem/data/redemption_code.dart';
import 'package:afk_redeem/data/services/afk_redeem_api.dart';
import 'package:afk_redeem/data/user_redeem_summary.dart';
import 'package:afk_redeem/data/user_message.dart';
import 'package:afk_redeem/ui/components/about_dialog.dart';
import 'package:afk_redeem/ui/components/disclosure_dialog.dart';
import 'package:afk_redeem/ui/components/help_button.dart';
import 'package:afk_redeem/ui/components/loader_overlay.dart';
import 'package:afk_redeem/ui/image_manager.dart';
import 'package:afk_redeem/ui/appearance_manager.dart';
import 'package:afk_redeem/ui/components/redemption_code_card.dart';
import 'package:afk_redeem/ui/components/app_builder.dart';
import 'package:afk_redeem/ui/components/redemption_summary_dialog.dart';
import 'package:afk_redeem/ui/components/error_dialog.dart';
import 'package:afk_redeem/ui/components/drawer_links.dart';
import 'package:afk_redeem/ui/components/redeem_dialog.dart';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

const BASE_BRUTUS_HEIGHT = 60.0;

class _MainScreenState extends State<MainScreen>
    with SingleTickerProviderStateMixin {
  late AfkRedeemApi _afkRedeemApi = AfkRedeemApi(
    redemptionCodesHandler: updateRedemptionCodes,
    appMessageHandler: showBrutusMessage,
    userErrorHandler: showSnackBarError,
  );
  RefreshController _refreshController = RefreshController(
      initialRefresh: false); // refreshing manually after checking disclosure
  TextEditingController _userIdController =
      TextEditingController(text: Preferences().userID);
  bool _userIdEmpty = false;
  FocusNode _userIdFocusNode = FocusNode();
  GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey();
  List<RedemptionCode> _redemptionCodes = Preferences().redemptionCodes;
  Set<RedemptionCode> _selectedRedemptionCodes = {};
  late AnimationController _brutusAnimationController = AnimationController(
    duration: Duration(milliseconds: 350),
    vsync: this,
  );
  double _brutusHeight = BASE_BRUTUS_HEIGHT;
  GlobalKey _brutusKey = GlobalObjectKey('brutus');
  bool _isRedeemingSelectedCodes = true;

  @override
  void initState() {
    super.initState();
    _brutusAnimationController.addListener(() {
      double heightDecrease = _brutusAnimationController.value;
      if (heightDecrease > 0.5) {
        heightDecrease = 1 - heightDecrease;
      }
      setState(() {
        _brutusHeight =
            BASE_BRUTUS_HEIGHT - heightDecrease * heightDecrease * 30;
      });
    });
    setState(() {
      _userIdEmpty = _userIdController.text == '';
      for (RedemptionCode redemptionCode in Preferences().redemptionCodes) {
        if (redemptionCode.shouldRedeem) {
          _selectedRedemptionCodes.add(redemptionCode);
        }
      }
    });
    // components are not ready - delay using them
    Future.delayed(Duration.zero, () {
      _handlePrerequisites();
    });
  }

  void _handlePrerequisites() async {
    // show disclosure
    if (!Preferences().wasDisclosureApproved) {
      await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (_) => disclosureDialog(context),
      );
    }

    _refreshController.requestRefresh();

    // user id is empty, open drawer & focus on user id text field
    if (_userIdController.text == '') {
      _scaffoldKey.currentState?.openDrawer();
      _userIdFocusNode.requestFocus();
    }
  }

  bool showBrutusMessage(String text, {Duration? duration}) {
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      return false;
    }
    RenderBox target =
        _brutusKey.currentContext!.findRenderObject()! as RenderBox;
    Rect markRect = target.localToGlobal(Offset.zero) & target.size;

    OverlayEntry overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: markRect.bottom,
        right: MediaQuery.of(context).size.width * 1 / 5,
        width: MediaQuery.of(context).size.width * 3 / 5,
        child: Material(
          type: MaterialType.transparency,
          child: Bubble(
            nip: BubbleNip.rightTop,
            alignment: Alignment.topRight,
            color: AppearanceManager().color.snackBar,
            child: Text(
              text,
              style: TextStyle(
                fontSize: 16.0,
                color: AppearanceManager().color.snackBarText,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
    Overlay.of(context)!.insert(overlayEntry);
    Future.delayed(duration ?? Duration(seconds: 5))
        .then((value) => overlayEntry.remove());
    return true;
  }

  void _onRefresh() async {
    if (!Preferences().wasDisclosureApproved) {
      return;
    }
    await _afkRedeemApi.update();
    _refreshController.refreshCompleted();
  }

  void updateRedemptionCodes(List<RedemptionCode> redemptionCodes) {
    setState(() {
      _redemptionCodes = redemptionCodes;
      // select new (non-redeemed) codes
      for (RedemptionCode code in Preferences().redemptionCodes) {
        if (code.shouldRedeem) {
          _selectedRedemptionCodes.add(code);
        }
      }
    });
  }

  void showSnackBarError(UserMessage errorMessage) {
    ScaffoldMessenger.of(context)
        .showSnackBar(AppearanceManager().errorSnackBar(errorMessage));
    _refreshController.refreshCompleted();
  }

  void _redeemRunning() {
    LoaderOverlay.show(context);
  }

  void _redeemCompleted(List<UserRedeemSummary> usersRedeemSummary) {
    LoaderOverlay.hide();
    setState(() {
      _selectedRedemptionCodes.clear();
      Preferences().updateRedeemedCodes(usersRedeemSummary[0].allCodes);
    });
    showDialog<String>(
      context: context,
      builder: (_) => redemptionSummaryDialog(
        context,
        _isRedeemingSelectedCodes,
        usersRedeemSummary,
      ),
    );
  }

  void _redeemError(UserMessage errorMessage) async {
    LoaderOverlay.hide();
    setState(() {
      _selectedRedemptionCodes.clear();
    });
    await showDialog<String>(
      context: context,
      builder: (_) => errorDialog(context, errorMessage),
    );
  }

  Future<void> _redeemSelectedCodes(BuildContext context) async {
    if (_userIdController.text == '') {
      ScaffoldMessenger.of(context).showSnackBar(
          AppearanceManager().errorSnackBar(UserMessage.missingUserId));
      return;
    }
    _isRedeemingSelectedCodes = true;
    AlertDialog? redeemDialog = await RedeemDialog.codes(
        context,
        _afkRedeemApi,
        _userIdController.text,
        _selectedRedemptionCodes,
        _redeemRunning,
        _redeemCompleted,
        _redeemError);
    if (redeemDialog != null) {
      showDialog<String>(
        context: context,
        builder: (_) => redeemDialog,
      );
    }
  }

  bool redemptionCodeSelected(RedemptionCode redemptionCode,
      {bool toggle = false}) {
    // getter + setter (cause I was lazy)
    bool isSelected = _selectedRedemptionCodes.contains(redemptionCode);
    if (toggle && redemptionCode.isActive) {
      setState(() {
        if (isSelected) {
          _selectedRedemptionCodes.remove(redemptionCode);
        } else {
          _selectedRedemptionCodes.add(redemptionCode);
        }
      });
      isSelected = !isSelected;
    }
    return isSelected;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: ImageManager().get('app_background').image,
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(
                AppearanceManager().color.appBackgroundBlend.withOpacity(
                    AppearanceManager().setting.backgroundTransparencyFactor),
                BlendMode.dstATop,
              ),
            ),
          ),
        ),
        Scaffold(
          key: _scaffoldKey,
          backgroundColor: Colors.transparent,
          drawer: SafeArea(
            child: Theme(
              data: Theme.of(context).copyWith(
                canvasColor: AppearanceManager().color.background,
                textTheme: TextTheme(
                  bodyText1: TextStyle(),
                  bodyText2: TextStyle(),
                ).apply(
                  bodyColor: AppearanceManager().color.text,
                ),
              ),
              child: Drawer(
                child: ListTileTheme(
                  iconColor: AppearanceManager().color.text,
                  child: Column(
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                image: DecorationImage(
                                  image: ImageManager()
                                      .get('drawer_background')
                                      .image,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              child: DrawerHeader(
                                child: GestureDetector(
                                  onTap: () {
                                    _scaffoldKey.currentState?.openEndDrawer();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        AppearanceManager()
                                            .snackBarStr('Baaaaaa 🌈'));
                                  },
                                  child:
                                      Image.asset('images/rainbow_nemora.png'),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 8.0, horizontal: 20.0),
                                        child: Column(
                                          children: [
                                            ListTile(
                                              leading: Icon(
                                                CupertinoIcons.person,
                                              ),
                                              title: TextField(
                                                style: TextStyle(
                                                  fontSize: 18.0,
                                                  color: AppearanceManager()
                                                      .color
                                                      .text,
                                                ),
                                                controller: _userIdController,
                                                focusNode: _userIdFocusNode,
                                                keyboardType:
                                                    TextInputType.number,
                                                inputFormatters: [
                                                  FilteringTextInputFormatter
                                                      .allow(RegExp(r'[0-9]'))
                                                ],
                                                decoration: InputDecoration(
                                                    hintText: 'User ID'),
                                                onChanged: (text) {
                                                  Preferences().userID = text;
                                                  setState(() {
                                                    _userIdEmpty =
                                                        _userIdController
                                                                .text ==
                                                            '';
                                                  });
                                                },
                                              ),
                                              trailing: _userIdEmpty
                                                  ? carouselDialogHelpButton(
                                                      context: context,
                                                      carouselItems: [
                                                        Image.asset(
                                                            'images/game_screenshots/player.jpg'),
                                                        Image.asset(
                                                            'images/game_screenshots/details.jpg'),
                                                      ],
                                                    )
                                                  : SizedBox(width: 25.0),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            'For redeeming codes from the app',
                                            style: TextStyle(
                                              color: _userIdEmpty
                                                  ? AppearanceManager()
                                                      .color
                                                      .text
                                                  : AppearanceManager()
                                                      .color
                                                      .background,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 8.0),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Container(
                                              height: 35,
                                              width: 35,
                                              child: ImageManager()
                                                  .get('celestial_icon'),
                                            ),
                                            Switch(
                                                value: AppearanceManager()
                                                    .isHypogean,
                                                inactiveTrackColor:
                                                    AppearanceManager()
                                                        .color
                                                        .inactiveSwitch,
                                                onChanged: (value) {
                                                  setState(() {
                                                    AppearanceManager()
                                                        .updateTheme(
                                                            isHypogean: value);
                                                  });
                                                  AppBuilder.of(context)
                                                      .rebuild();
                                                }),
                                            Container(
                                              height: 40,
                                              width: 40,
                                              child: ImageManager()
                                                  .get('hypogean_icon'),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  DrawerLinks(),
                                  Padding(
                                    padding:
                                        const EdgeInsets.only(bottom: 10.0),
                                    child: GestureDetector(
                                      onTap: () async {
                                        AlertDialog _aboutDialog =
                                            await aboutDialog(
                                                context, _afkRedeemApi);
                                        showDialog<String>(
                                          context: context,
                                          builder: (_) => _aboutDialog,
                                        );
                                      },
                                      child: Text(
                                        'about',
                                        style: TextStyle(
                                            color:
                                                AppearanceManager().color.main),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          appBar: PreferredSize(
            preferredSize: Size.fromHeight(60.0),
            child: SafeArea(
              child: Container(
                padding: EdgeInsets.only(top: 5.0, left: 5.0, right: 5.0),
                child: AppBar(
                  elevation: 8,
                  // backgroundColor: MAIN_COLOR,
                  backgroundColor: Colors.transparent,
                  iconTheme: IconThemeData(
                    color: AppearanceManager().color.appBarText,
                  ),
                  flexibleSpace: Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: Image(
                        image: ImageManager().get('panel_background').image,
                        fit: BoxFit.cover),
                  ),
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _selectedRedemptionCodes.isEmpty
                          ? AnimatedTextKit(
                              // use key on text color to support re-build on color change
                              key: ValueKey(
                                  AppearanceManager().color.appBarText),
                              animatedTexts: [
                                TypewriterAnimatedText(
                                  "AFK Redeem",
                                  textStyle: TextStyle(
                                    color: AppearanceManager().color.appBarText,
                                  ),
                                  speed: Duration(milliseconds: 150),
                                ),
                              ],
                              isRepeatingAnimation: false,
                            )
                          : IconButton(
                              padding: EdgeInsets.zero,
                              constraints: BoxConstraints(),
                              onPressed: () {
                                _redeemSelectedCodes(context);
                              },
                              iconSize: 32.0,
                              icon: Icon(
                                CupertinoIcons.gift,
                              ),
                            ),
                      Padding(
                        padding: const EdgeInsets.only(right: 20.0),
                        child: GestureDetector(
                          onTap: () async {
                            _brutusAnimationController.reset();
                            _brutusAnimationController.forward();
                            if (_userIdController.text == '') {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  AppearanceManager().errorSnackBar(
                                      UserMessage.missingUserId));
                              return;
                            }
                            _isRedeemingSelectedCodes = false;
                            ClipboardData? clipboardData =
                                await Clipboard.getData(Clipboard.kTextPlain);
                            AlertDialog? redeemDialog =
                                await RedeemDialog.manualCode(
                                    context,
                                    _afkRedeemApi,
                                    _userIdController.text,
                                    clipboardData,
                                    _redeemRunning,
                                    _redeemCompleted,
                                    _redeemError);
                            if (redeemDialog != null) {
                              showDialog<String>(
                                context: context,
                                builder: (_) => redeemDialog,
                              );
                            }
                          },
                          onLongPress: () {
                            HapticFeedback.vibrate();
                            _brutusAnimationController.reset();
                            _brutusAnimationController.forward();
                            showBrutusMessage(
                                'All I ever had\n🎵 Redemption songs 🎵');
                          },
                          child: Container(
                            key: _brutusKey,
                            child: Image.asset(
                              'images/brutus.png',
                              height: _brutusHeight,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: 7.0),
              child: SmartRefresher(
                controller: _refreshController,
                enablePullDown: true,
                header: WaterDropMaterialHeader(),
                onRefresh: _onRefresh,
                child: ListView(
                  children: [
                    Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          for (var redemptionCode in _redemptionCodes)
                            RedemptionCodeCard(
                                redemptionCode, redemptionCodeSelected)
                        ]),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
