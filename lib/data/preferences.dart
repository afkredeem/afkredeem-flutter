import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:afk_redeem/data/consts.dart';
import 'package:afk_redeem/data/redemption_code.dart';
import 'package:afk_redeem/data/user_message.dart';
import 'package:afk_redeem/data/json_reader.dart';

class Preferences {
  static Preferences? _singleton;
  factory Preferences() {
    return _singleton!;
  }

  SharedPreferences _prefs;
  bool _isHypogean;
  String _userID;
  bool _wasDisclosureApproved;
  int _redeemApiVersion;
  int _appInStoreApiVersionSupport;
  List<RedemptionCode> redemptionCodes;
  Map<String, RedemptionCode> redemptionCodesMap;

  bool get isHypogean => _isHypogean;
  String get userID => _userID;
  bool get wasDisclosureApproved => _wasDisclosureApproved;
  int get redeemApiVersion => _redeemApiVersion;
  int get appInStoreApiVersionSupport => _appInStoreApiVersionSupport;

  set userID(String value) {
    _userID = value;
    _prefs.setString('userID', value);
  }

  set isHypogean(bool value) {
    _isHypogean = value;
    _prefs.setBool('isHypogean', value);
  }

  set wasDisclosureApproved(bool value) {
    _wasDisclosureApproved = value;
    _prefs.setBool('wasDisclosureApproved', value);
  }

  set redeemApiVersion(int value) {
    _redeemApiVersion = value;
    _prefs.setInt('redeemApiVersion', value);
  }

  set appInStoreApiVersionSupport(int value) {
    _appInStoreApiVersionSupport = value;
    _prefs.setInt('appInStoreApiVersionSupport', value);
  }

  bool wasAppMessageShown(int messageId) {
    return _prefs.getBool('appMessageShown-$messageId') ?? false;
  }

  void setAppMessageShown(int messageId) {
    _prefs.setBool('appMessageShown-$messageId', true);
  }

  static Future<Preferences> create() async {
    if (_singleton != null) {
      return _singleton!;
    }
    SharedPreferences sp = await SharedPreferences.getInstance();
    _singleton = Preferences._create(sp);
    return _singleton!;
  }

  Preferences._create(this._prefs)
      : _isHypogean = _prefs.getBool('isHypogean') ?? kDefaultIsHypogean,
        _userID = _prefs.getString('userID') ?? '',
        _wasDisclosureApproved = _prefs.getBool('wasDisclosureApproved') ??
            kDefaultWasDisclosureApproved,
        _redeemApiVersion =
            _prefs.getInt('redeemApiVersion') ?? kDefaultRedeemApiVersion,
        _appInStoreApiVersionSupport =
            _prefs.getInt('appInStoreApiVersionSupport') ??
                kDefaultAppInStoreApiVersionSupport,
        redemptionCodes =
            _codesFromJsonString(_prefs.getString('redemptionCodes')),
        redemptionCodesMap = {} {
    // can't rely on member redemptionCodes in initialization
    redemptionCodesMap = {for (var rc in redemptionCodes) rc.code: rc};
    // sort by isActive & date
    redemptionCodes.sort();
  }

  void updateConfigData({
    required Map<String, dynamic> configData,
    required UserErrorHandler userErrorHandler,
  }) {
    JsonReader jsonReader = JsonReader(
      context: 'Preferences::updateConfigData',
      json: configData,
    );
    redeemApiVersion = jsonReader.read('redeemApiVersion');
    if (Platform.isAndroid) {
      appInStoreApiVersionSupport =
          jsonReader.read('androidAppApiVersionSupport');
    } else if (Platform.isIOS) {
      appInStoreApiVersionSupport = jsonReader.read('iosAppApiVersionSupport');
    } else {
      throw Exception('Unsupported platform for api version config data');
    }
  }

  bool get isRedeemApiVersionSupported {
    print('$redeemApiVersion <= $kRedeemApiVersion');
    return redeemApiVersion <= kRedeemApiVersion;
  }

  bool get isRedeemApiVersionUpgradable {
    return redeemApiVersion <= appInStoreApiVersionSupport;
  }

  void updateRedeemedCodes(List<RedemptionCode> redeemed) {
    for (RedemptionCode redeemedCode in redeemed) {
      redeemedCode.wasRedeemed = true;
    }
    _prefs.setString('redemptionCodes', _codesToJsonString(redemptionCodes));
  }

  void updateCodesFromExternalSource({
    required List<dynamic> newCodesJson,
    required UserErrorHandler? userErrorHandler,
  }) {
    List<RedemptionCode> newCodes =
        _codesFromJson(newCodesJson, userErrorHandler: userErrorHandler);
    if (redemptionCodes.isEmpty) {
      // first codes update
      redemptionCodes = newCodes;
      redemptionCodes.forEach((rc) {
        rc.wasRedeemed = true; // mark all redeemed
      });
      redemptionCodesMap = {for (var rc in redemptionCodes) rc.code: rc};
    } else {
      for (RedemptionCode newRC in newCodes) {
        if (redemptionCodesMap.containsKey(newRC.code)) {
          redemptionCodesMap[newRC.code]!.updateFromExternalSource(newRC);
        } else {
          redemptionCodes.add(newRC);
          redemptionCodesMap[newRC.code] = newRC;
        }
      }
    }
    // sort by isActive & date
    redemptionCodes.sort();
    _prefs.setString('redemptionCodes', _codesToJsonString(redemptionCodes));
  }

  static List<RedemptionCode> _codesFromJsonString(String? codesJsonString) {
    return codesJsonString == null
        ? []
        : _codesFromJson(json.decode(codesJsonString));
  }

  static List<RedemptionCode> _codesFromJson(List<dynamic> jsonCodes,
      {UserErrorHandler? userErrorHandler}) {
    List<RedemptionCode> codes = [];
    JsonReader jsonReader = JsonReader(
      context: 'Reading redemption codes json',
    );
    for (dynamic codeJson in jsonCodes) {
      jsonReader.json = codeJson;
      codes.add(RedemptionCode.fromJson(jsonReader));
    }
    return codes;
  }

  static String _codesToJsonString(List<RedemptionCode> redemptionCodes) {
    return jsonEncode(redemptionCodes);
  }
}
