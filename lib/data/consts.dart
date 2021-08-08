import 'dart:io';
import 'package:flutter/foundation.dart';

const kRedeemApiVersion = 1;

const kConnectTimeoutMilli = 5000;
const kReceiveTimeoutMilli = 3000;

const kMinPasteManualRedemptionCodeLength = 5;
const kMaxPasteManualRedemptionCodeLength = 15;

const kDefaultIsHypogean = true;
const kDefaultWasDisclosureApproved = false;
const kDefaultRedeemApiVersion = 1000000;
const kDefaultAppInStoreApiVersionSupport = 1000000;

// mixin wins over class cause it prevents the compiler from complaining about naming conventions
mixin kLinks {
  // static const bool emulateLilithRedeem = true;
  static const bool emulateLilithRedeem = false;

  // static const bool emulateAfkRedeemApi = true;
  static const bool emulateAfkRedeemApi = false;

  static const String iosEmulator = 'http://127.0.0.1/';
  static const String androidEmulator = 'http://10.0.2.2/';

  static const String _lilithRedeem = 'https://cdkey.lilith.com/';
  static const String lilithReferer = 'https://cdkey.lilith.com/afk-global';

  static const String afkRedeem = 'https://afkredeem.com/';
  static const String githubProject =
      'https://github.com/afkredeem/afkredeem-flutter';

  static final String lilithRedeemHost = kReleaseMode || !emulateLilithRedeem
      ? _lilithRedeem
      : Platform.isAndroid
          ? androidEmulator
          : Platform.isIOS
              ? iosEmulator
              : _lilithRedeem;

  static final String afkRedeemApiHost = kReleaseMode || !emulateAfkRedeemApi
      ? afkRedeem
      : Platform.isAndroid
          ? androidEmulator
          : Platform.isIOS
              ? iosEmulator
              : afkRedeem;

  static final afkRedeemApiUrl = afkRedeemApiHost + kUris.afkRedeemApi;
}

mixin kUris {
  static const String verifyCodeUri = 'api/verify-afk-code';
  static const String usersUri = 'api/users';
  static const String consumeUri = 'api/cd-key/consume';

  static const String afkRedeemApi = 'api.json';
}

mixin kFlutterHtmlUri {
  static const String about = 'flutter_html/general/about.html';
  static const String redeemNotSupported =
      'flutter_html/general/redeem_not_supported.html';
  static const String upgradeApp = 'flutter_html/general/redeem_upgrade.html';
}
