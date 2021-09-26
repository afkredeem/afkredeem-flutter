import 'package:dio/dio.dart';

import 'package:afk_redeem/data/consts.dart';
import 'package:afk_redeem/data/redemption_code.dart';
import 'package:afk_redeem/data/user_message.dart';
import 'package:afk_redeem/data/preferences.dart';
import 'package:afk_redeem/data/app_message.dart';
import 'package:afk_redeem/data/json_reader.dart';
import 'package:afk_redeem/data/error_reporter.dart';

typedef RedemptionCodesHandler = Function(List<RedemptionCode> redemptionCodes);
typedef AppMessageHandler = bool Function(String message, {Duration? duration});

class AfkRedeemApi {
  AfkRedeemApi({
    required this.redemptionCodesHandler,
    required this.appMessageHandler,
    required this.userErrorHandler,
    required this.notifyNewerVersionHandler,
    required this.applyThemeHandler,
  }) {
    _dio.options.connectTimeout = kConnectTimeoutMilli;
    _dio.options.receiveTimeout = kReceiveTimeoutMilli;
  }

  Dio _dio = Dio();
  RedemptionCodesHandler redemptionCodesHandler;
  AppMessageHandler appMessageHandler;
  UserErrorHandler userErrorHandler;
  Function() notifyNewerVersionHandler;
  Function() applyThemeHandler;

  Future<String?> getPage(String uri) async {
    String url = kLinks.afkRedeemApiHost + uri;
    try {
      Response response = await _dio.get(
        url,
        options: Options(
          followRedirects: false,
        ),
      );
      return response.data;
    } on DioError catch (ex) {
      userErrorHandler(UserMessage.connectionFailed);
      if (shouldReportDioError(ex)) {
        ErrorReporter.report(ex, 'Connection failed to $url');
      }
    } catch (ex) {
      userErrorHandler(UserMessage.connectionFailed);
      ErrorReporter.report(ex, 'Unknown parse error on connection to $url');
    }
  }

  Future<void> update() async {
    try {
      await _update();
    } on DioError catch (ex) {
      userErrorHandler(UserMessage.connectionFailed);
      if (ex.type != DioErrorType.connectTimeout) {
        ErrorReporter.report(
            ex, 'Connection failed to ${kLinks.afkRedeemApiUrl}');
      }
    } on JsonReaderException catch (ex) {
      userErrorHandler(UserMessage.parseError);
      ex.report();
    } catch (ex) {
      userErrorHandler(UserMessage.parseError);
      ErrorReporter.report(
          ex, 'Unknown parse error on connection to ${kLinks.afkRedeemApiUrl}');
    }
  }

  Future<void> _update() async {
    Response response = await _dio.get(
      kLinks.afkRedeemApiUrl,
      options: Options(
        followRedirects: false,
        headers: {
          'accept': 'application/json',
          'content-type': 'application/json',
        },
      ),
    );
    JsonReader jsonReader = JsonReader(
      context: 'Api-Manager reading response from ${kLinks.afkRedeemApiUrl}',
      json: response.data,
    );

    // update config data
    Preferences().updateConfigData(
      configData: jsonReader.read('config'),
      userErrorHandler: userErrorHandler,
      applyThemeHandler: applyThemeHandler,
    );

    // update codes (preferences + ui handler)
    Preferences().updateCodesFromExternalSource(
      newCodesJson: jsonReader.read('codes'),
      userErrorHandler: userErrorHandler,
    );
    redemptionCodesHandler(Preferences().redemptionCodes);

    _handleAppMessages(jsonReader.read('appMessages'));
  }

  void _handleAppMessages(List<dynamic> jsonAppMessages) {
    JsonReader appMessagesJsonReader = JsonReader(
      context:
          'Api-Manager reading app messages from ${kLinks.afkRedeemApiUrl}',
    );
    AppMessage? appMessageToShow;
    List<AppMessage> appMessages = jsonAppMessages.map((jsonMessage) {
      appMessagesJsonReader.json = jsonMessage;
      return AppMessage.fromJson(appMessagesJsonReader);
    }).toList();
    for (AppMessage appMessage in appMessages) {
      if (DateTime.now().isBefore(appMessage.expiresAt) &&
          !appMessage.wasShown) {
        // new non-expired message
        if (!appMessage.isSkippable) {
          // message is non-skippable - show it
          appMessageToShow = appMessage;
          break;
        }
        if (appMessageToShow == null) {
          appMessageToShow = appMessage;
        }
      }
    }
    if (appMessageToShow != null) {
      bool messageShown = appMessageHandler(
        appMessageToShow.content,
        duration: appMessageToShow.duration,
      );
      if (messageShown) {
        appMessageToShow.setWasShown();
      }
    } else if (Preferences().isAppUpgradable) {
      // no messages - but app is upgradable
      notifyNewerVersionHandler();
    }
  }
}
