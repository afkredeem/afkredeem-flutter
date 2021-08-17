import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';

import 'package:afk_redeem/data/consts.dart';
import 'package:afk_redeem/data/redemption_code.dart';
import 'package:afk_redeem/data/user_message.dart';
import 'package:afk_redeem/data/json_reader.dart';
import 'package:afk_redeem/data/error_reporter.dart';
import 'package:afk_redeem/data/user_redeem_summary.dart';

class CodeRedeemer {
  String uid;
  String verificationCode;
  Set<RedemptionCode> redemptionCodes;
  RedeemSummaryFunction redeemCompletedHandler;
  UserErrorHandler userErrorHandler;
  Dio _dio = Dio();
  CookieJar _cookieJar = CookieJar();

  CodeRedeemer(
      {required this.uid,
      required this.verificationCode,
      required this.redemptionCodes,
      required this.redeemCompletedHandler,
      required this.userErrorHandler}) {
    _dio.interceptors.add(CookieManager(_cookieJar));
    _dio.options.connectTimeout = kConnectTimeoutMilli;
    _dio.options.receiveTimeout = kReceiveTimeoutMilli;
  }

  Future<void> redeem() async {
    try {
      await _redeem();
    } on DioError catch (ex) {
      userErrorHandler(UserMessage.connectionFailed);
      if (shouldReportDioError(ex)) {
        ErrorReporter.report(
            ex, 'Connection failed to ${kLinks.lilithRedeemHost}');
      }
    } on JsonReaderException catch (ex) {
      userErrorHandler(UserMessage.parseError);
      ex.report();
    } catch (ex) {
      userErrorHandler(UserMessage.parseError);
      ErrorReporter.report(ex,
          'Unknown parse error on connection to ${kLinks.lilithRedeemHost}');
    }
  }

  Future<void> _redeem() async {
    String postData = '''
    {
        "game": "afk",
        "uid": $uid,
        "code": "$verificationCode"
    }
    ''';
    Response response =
        await _sendRequest(kUris.verifyCodeUri, postData: postData);
    JsonReader jsonReader = JsonReader(
      context:
          'Redeemer reading response from ${kLinks.lilithRedeemHost}${kUris.verifyCodeUri}',
      json: response.data as Map<String, dynamic>,
    );

    String info = jsonReader.read('info');
    if (info == 'ok') {
      await _redeemForUsers();
    } else if (info == 'err_wrong_code') {
      userErrorHandler(UserMessage.verificationFailed);
    } else {
      userErrorHandler(UserMessage.parseError);
      throw JsonReaderException(
          'Unknown ${kUris.verifyCodeUri} \'info\' value \'$info\'');
    }
  }

  Future<void> _redeemForUsers() async {
    String postData = '''
    {
        "game": "afk",
        "uid": $uid
    }
    ''';
    Response response = await _sendRequest(kUris.usersUri, postData: postData);
    JsonReader jsonReader = JsonReader(
      context:
          'Redeemer reading response from ${kLinks.lilithRedeemHost}${kUris.usersUri}',
      json: response.data as Map<String, dynamic>,
    );

    List<Future<UserRedeemSummary>> userRedeemSummaries = [];
    int concurrentConsumeOperations = 0;
    if ((jsonReader.read('info') ?? 'not-ok') == 'ok') {
      List<dynamic> users =
          jsonReader.readFrom(jsonReader.read('data'), 'users');
      for (Map<String, dynamic> user in users) {
        if (concurrentConsumeOperations >=
            kConcurrentConsumeRequestsSoftLimit) {
          await Future.wait(userRedeemSummaries);
          concurrentConsumeOperations = 0;
        }
        concurrentConsumeOperations += redemptionCodes.length;
        userRedeemSummaries.add(
          _consumeUserRedemptionCodes(
            jsonReader.readFrom(user, 'uid'),
            jsonReader.readFrom(user, 'name'),
            jsonReader.readFrom(user, 'svr_id'),
          ),
        );
      }
    }

    if (userRedeemSummaries.isEmpty) {
      userErrorHandler(UserMessage.parseError);
      ErrorReporter.report(Exception('Redeem Failed'),
          'empty userRedeemSummaries list for ${kUris.usersUri} response: ${response.data}');
      return;
    }
    concurrentConsumeOperations = 0;
    redeemCompletedHandler(await Future.wait(userRedeemSummaries));
  }

  Future<UserRedeemSummary> _consumeUserRedemptionCodes(
      int uid, String username, int server) async {
    UserRedeemSummary userRedeemSummary =
        UserRedeemSummary(uid, username, server);

    await Future.forEach(redemptionCodes,
        (RedemptionCode redemptionCode) async {
      Map<String, dynamic>? queryParams;
      if (kLinks.toggleEmulatedRedeemResponses) {
        queryParams = {'toggle-responses': null}; // mock server option
      }
      String postData = '''
      {
          "cdkey": "${redemptionCode.code}",
          "game": "afk",
          "type": "cdkey_web",
          "uid": $uid
      }
      ''';
      Response response = await _sendRequest(kUris.consumeUri,
          postData: postData, queryParameters: queryParams);
      JsonReader jsonReader = JsonReader(
        context:
            'Redeemer reading response from ${kLinks.lilithRedeemHost}${kUris.consumeUri} with code=${redemptionCode.code}',
        json: response.data as Map<String, dynamic>,
      );
      String info = jsonReader.read('info');
      switch (info) {
        case 'ok':
          userRedeemSummary.redeemedCodes.add(redemptionCode);
          break;
        case 'err_cdkey_batch_error':
          userRedeemSummary.usedCodes.add(redemptionCode);
          break;
        case 'err_cdkey_record_not_found':
          userRedeemSummary.notFoundCodes.add(redemptionCode);
          break;
        case 'err_cdkey_expired':
          userRedeemSummary.expiredCodes.add(redemptionCode);
          break;
        default:
          throw JsonReaderException(
              'Unknown ${kUris.consumeUri} \'info\' value \'$info\'');
      }
    });

    return userRedeemSummary;
  }

  Future<Response> _sendRequest(String uri,
      {String? postData, Map<String, dynamic>? queryParameters}) {
    return _dio.post(
      '${kLinks.lilithRedeemHost}$uri',
      data: postData,
      queryParameters: queryParameters,
      options: Options(
        followRedirects: false,
        validateStatus: (status) {
          return true;
        },
        headers: {
          'sec-ch-ua':
              '" Not;A Brand";v="99", "Google Chrome";v="91", "Chromium";v="91"',
          'accept': 'application/json',
          'sec-ch-ua-mobile': '?0',
          'user-agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.114 Safari/537.36',
          'content-type': 'application/json',
          'origin': kLinks.lilithRedeemHost
              .substring(0, kLinks.lilithRedeemHost.length - 1),
          'sec-fetch-site': 'same-origin',
          'sec-fetch-mode': 'cors',
          'sec-fetch-dest': 'empty',
          'referer': kLinks.lilithReferer,
          'accept-encoding': 'gzip, deflate, br',
          'accept-language': 'en-US,en;q=0.9',
        },
      ),
    );
  }
}
