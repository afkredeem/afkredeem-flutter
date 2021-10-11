import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:afk_redeem/data/preferences.dart';
import 'package:afk_redeem/data/user_message.dart';
import 'package:afk_redeem/ui/image_manager.dart';

class AppearanceManager {
  static final AppearanceManager _singleton = AppearanceManager._create();
  AppearanceManager._create() {
    _applyTheme(_theme);

    // user messages conversion sanity
    for (var userMessage in UserMessage.values) {
      if (!_userMessages.containsKey(userMessage)) {
        print('Missing user message string for $userMessage');
        assert(_userMessages.containsKey(userMessage));
      }
    }
  }
  factory AppearanceManager() {
    return _singleton;
  }

  Map<UserMessage, String> _userMessages = {
    UserMessage.connectionFailed: 'Connection failed ☠️',
    UserMessage.parseError:
        'Sry 😕\nWe\'ve ran into a parser error\nhope it\'s fixed soon\n\n[if not, write us!]',
    UserMessage.verificationFailed: 'Verification failed ⛔',
    UserMessage.missingUserId: 'Set User ID',
    UserMessage.cantBeEmpty: 'Can\'t be empty',
    UserMessage.copiedToClipboard: 'Copied to clipboard',
  };

  Map<UserMessage, String> get userMessages => _userMessages;

  static const _hypogeanTheme = 'hypogean';
  static const _celestialTheme = 'celestial';
  static const _christmasTheme = 'christmas';

  String _theme = _hypogeanTheme;
  final Map<String, AppearanceSettings> _colorThemes = {
    _hypogeanTheme: AppearanceSettings(
        colorPalette: ColorPalette(
          main: Color(0xFFC52ED0),
          mainText: Color(0xFFC52ED0),
          mainBright: Color(0xFFD888EE),
          snackBar: Color(0xFF740879),
          snackBarText: Color(0xFFE2E2E2),
          snackBarError: Color(0xFF682121),
          text: Color(0xFFC2C2C2),
          boldText: Color(0xFFEFEFEF),
          giftText: Color(0xFFA5A5A5),
          hintText: Color(0xFF7B7B7B),
          dateText: Color(0xFF979797),
          disabled: Color(0xFF727272),
          appBarText: Color(0xFFFFFFFF),
          expiredLabel: Color(0xFF3D3D3D),
          textFieldHiddenBorder: Color(0xFF000000),
          background: Color(0xFF140D1F),
          appBackgroundBlend: Color(0xFF4B4B4B),
          dialogBackground: Color(0xFF27213D),
          dialogBackgroundOverlay: Color(0xFF372F57),
          dialogTitleText: Color(0xFFD888EE),
          dialogText: Color(0xFFC2C2C2),
          inactiveSwitch: Color(0xFFFFE89A),
          red: Colors.red,
          yellow: Colors.yellow,
          green: Colors.green,
        ),
        backgroundTransparencyFactor: 0.2),
    _celestialTheme: AppearanceSettings(
        colorPalette: ColorPalette(
          main: Color(0xFFEEB900),
          mainText: Color(0xFFB88E00),
          mainBright: Color(0xFFFFC941),
          snackBar: Color(0xFFFFE56B),
          snackBarText: Color(0xFF1A1A1A),
          snackBarError: Color(0xFFFF8B8B),
          text: Color(0xFF242424),
          boldText: Color(0xFF0C0C0C),
          giftText: Color(0xFF5A5A5A),
          hintText: Color(0xFF9C9C9C),
          dateText: Color(0xFF5E5E5E),
          disabled: Color(0xFF727272),
          appBarText: Color(0xFF131313),
          expiredLabel: Color(0xFF767676),
          textFieldHiddenBorder: Color(0xFFFFFFFF),
          background: Color(0xFFFFFEFB),
          appBackgroundBlend: Color(0xFFFFFFFF),
          dialogBackground: Color(0xFFFFFCF7),
          dialogBackgroundOverlay: Color(0xFFFFEFD6),
          dialogTitleText: Color(0xFF5E5E5E),
          dialogText: Color(0xFF242424),
          inactiveSwitch: Color(0xFFFFE89A),
          red: Color(0xFFE51C0B),
          yellow: Color(0xFFEEB900),
          green: Color(0xFF129915),
        ),
        backgroundTransparencyFactor: 1.0),
    _christmasTheme: AppearanceSettings(
        colorPalette: ColorPalette(
          main: Color(0xFFD02E2E),
          mainText: Color(0xFFD02E2E),
          mainBright: Color(0xFFE55959),
          snackBar: Color(0xFF790808),
          snackBarText: Color(0xFFE2E2E2),
          snackBarError: Color(0xFF682121),
          text: Color(0xFFC2C2C2),
          boldText: Color(0xFFEFEFEF),
          giftText: Color(0xFFA5A5A5),
          hintText: Color(0xFFA1A1A1),
          dateText: Color(0xFF979797),
          disabled: Color(0xFF727272),
          appBarText: Color(0xFFFFFFFF),
          expiredLabel: Color(0xFF3D3D3D),
          textFieldHiddenBorder: Color(0xFF000000),
          background: Color(0xFF170909),
          appBackgroundBlend: Color(0xFF4B4B4B),
          dialogBackground: Color(0xFFEFEFEF),
          dialogBackgroundOverlay: Color(0xFFFFC9C9),
          dialogTitleText: Color(0xFFB30000),
          dialogText: Color(0xFF424242),
          inactiveSwitch: Color(0xFFECB5B5),
          red: Color(0xFFE51C0B),
          yellow: Color(0xFFEEB900),
          green: Color(0xFF129915),
        ),
        backgroundTransparencyFactor: 0.25),
  };

  AppearanceSettings get setting {
    return _colorThemes[_theme]!;
  }

  ColorPalette get color {
    return _colorThemes[_theme]!.colorPalette;
  }

  SnackBar snackBar(UserMessage userMessage,
      {Color? backgroundColor, Duration? duration}) {
    return snackBarStr(
      userMessages[userMessage]!,
      backgroundColor: backgroundColor,
      duration: duration,
    );
  }

  SnackBar snackBarStr(String message,
      {Color? backgroundColor, Duration? duration}) {
    return SnackBar(
      content: Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: color.snackBarText,
        ),
      ),
      backgroundColor: backgroundColor ?? color.snackBar,
      duration: duration ?? Duration(milliseconds: 1250),
      behavior: SnackBarBehavior.floating,
    );
  }

  SnackBar errorSnackBar(UserMessage userMessage, {Duration? duration}) {
    return snackBar(
      userMessage,
      backgroundColor: color.snackBarError,
      duration: duration ?? Duration(seconds: 3),
    );
  }

  bool get isHypogean {
    return Preferences().isHypogean;
  }

  void updateTheme(bool isHypogean) {
    Preferences().isHypogean = isHypogean;
    applyTheme(isHypogean: isHypogean);
  }

  void applyTheme({bool? isHypogean, bool? isChristmas}) {
    if (isChristmas ?? false) {
      _applyTheme(_christmasTheme);
    } else if (isHypogean != null) {
      if (isHypogean) {
        _applyTheme(_hypogeanTheme);
      } else {
        _applyTheme(_celestialTheme);
      }
    }
  }

  bool get isChristmasThemeOn => _theme == _christmasTheme;

  void _applyTheme(String theme) {
    _colorThemes[theme]!; // throw exception if unsupported theme
    _theme = theme;
    ImageManager().applyTheme(theme);
  }

  ThemeData themeData() {
    ThemeData theme = ThemeData(
      primaryColor: color.main,
      unselectedWidgetColor: color.main,
      disabledColor: color.disabled,
      textTheme: TextTheme(
        bodyText1: TextStyle(),
        bodyText2: TextStyle(),
      ).apply(
        bodyColor: color.text,
      ),
      hintColor: color.hintText,
      inputDecorationTheme: InputDecorationTheme(
        isDense: true,
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(
            style: BorderStyle.solid,
            color: color.main,
          ),
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(
            style: BorderStyle.solid,
            color: color.textFieldHiddenBorder,
          ),
        ),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: color.main,
        selectionColor: color.mainBright,
        selectionHandleColor: color.main,
      ),
      dialogTheme: DialogTheme(
        backgroundColor: color.dialogBackground,
        titleTextStyle: TextStyle(
          fontSize: 20.0,
          color: color.dialogTitleText,
        ),
        contentTextStyle: TextStyle(
          color: color.dialogText,
        ),
      ),
      buttonTheme: ButtonThemeData(),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(primary: color.main),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          primary: color.main,
          shadowColor: Colors.grey.shade300,
          shape: new RoundedRectangleBorder(
            borderRadius: new BorderRadius.circular(10.0),
          ),
        ),
      ),
    );
    return theme.copyWith(
      colorScheme: theme.colorScheme.copyWith(secondary: color.main),
    );
  }
}

class UserMessageInfo {
  String message;
  Duration duration;

  UserMessageInfo(this.message, this.duration);
}

class AppearanceSettings {
  final colorPalette;
  final backgroundTransparencyFactor;

  AppearanceSettings({
    required this.colorPalette,
    required this.backgroundTransparencyFactor,
  });
}

class ColorPalette {
  final Color main;
  final Color mainText;
  final Color mainBright;
  final Color snackBar;
  final Color snackBarText;
  final Color snackBarError;
  final Color text;
  final Color boldText;
  final Color giftText;
  final Color hintText;
  final Color dateText;
  final Color disabled;
  final Color appBarText;
  final Color expiredLabel;
  final Color textFieldHiddenBorder;
  final Color background;
  final Color appBackgroundBlend;
  final Color dialogBackground;
  final Color dialogBackgroundOverlay;
  final Color dialogTitleText;
  final Color dialogText;
  final Color inactiveSwitch;
  final Color red;
  final Color yellow;
  final Color green;

  late final Map<String, Color> fromString = {
    "main": main,
    "mainText": mainText,
    "mainBright": mainBright,
    "snackBar": snackBar,
    "snackBarText": snackBarText,
    "snackBarError": snackBarError,
    "text": text,
    "boldText": boldText,
    "giftText": giftText,
    "hintText": hintText,
    "dateText": dateText,
    "disabled": disabled,
    "appBarText": appBarText,
    "expiredLabel": expiredLabel,
    "textFieldHiddenBorder": textFieldHiddenBorder,
    "background": background,
    "appBackgroundBlend": appBackgroundBlend,
    "dialogBackground": dialogBackground,
    "dialogBackgroundOverlay": dialogBackgroundOverlay,
    "dialogTitleText": dialogTitleText,
    "dialogText": dialogText,
    "inactiveSwitch": inactiveSwitch,
    "red": red,
    "yellow": yellow,
    "green": green,
  };

  ColorPalette(
      {required this.main,
      required this.mainText,
      required this.mainBright,
      required this.snackBar,
      required this.snackBarText,
      required this.snackBarError,
      required this.text,
      required this.boldText,
      required this.giftText,
      required this.hintText,
      required this.dateText,
      required this.disabled,
      required this.appBarText,
      required this.expiredLabel,
      required this.textFieldHiddenBorder,
      required this.background,
      required this.appBackgroundBlend,
      required this.dialogBackground,
      required this.dialogBackgroundOverlay,
      required this.dialogTitleText,
      required this.dialogText,
      required this.inactiveSwitch,
      required this.red,
      required this.yellow,
      required this.green});
}
