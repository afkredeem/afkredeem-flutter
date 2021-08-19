import 'package:afk_redeem/data/redemption_code.dart';

class AccountInfo {
  int uid;
  String username;
  int server;
  bool isMain;

  AccountInfo(this.uid, this.username, this.server, this.isMain);

  @override
  String toString() {
    return 'uid: $uid, username: $username, $server: server, isMain: $isMain';
  }
}

class AccountRedeemSummary {
  AccountInfo account;
  List<RedemptionCode> redeemedCodes = [];
  List<RedemptionCode> usedCodes = [];
  List<RedemptionCode> notFoundCodes = [];
  List<RedemptionCode> expiredCodes = [];

  AccountRedeemSummary(this.account);

  bool get isEmpty {
    return redeemedCodes.isEmpty &&
        usedCodes.isEmpty &&
        notFoundCodes.isEmpty &&
        expiredCodes.isEmpty;
  }

  bool get isNotEmpty {
    return !isEmpty;
  }

  List<RedemptionCode> get allCodes {
    return redeemedCodes + usedCodes + notFoundCodes + expiredCodes;
  }

  static codesListDisplayLines(List<RedemptionCode> codes) {
    // 1 for list headline & 2 for space
    return codes.length + (codes.isNotEmpty ? 3 : 0);
  }

  int get codesDisplayLines {
    return codesListDisplayLines(redeemedCodes) +
        codesListDisplayLines(usedCodes) +
        codesListDisplayLines(notFoundCodes) +
        codesListDisplayLines(expiredCodes);
  }
}

typedef RedeemSummaryFunction = Function(List<AccountRedeemSummary>);
