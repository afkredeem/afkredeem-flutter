import 'package:intl/intl.dart';

import 'package:afk_redeem/data/json_reader.dart';

class RedemptionCode implements Comparable {
  String code; // set from internal / external source
  DateTime? addedAt; // set from internal / external source
  DateTime? expiresAt; // set from internal / external source
  bool keepEnabled; // set from internal / external source
  bool isHidden; // set from internal / external source
  Map<String, String> gifts; // set from internal / external source
  bool wasRedeemed; // set from internal source only

  RedemptionCode(this.code)
      : keepEnabled = false,
        isHidden = false,
        gifts = {},
        wasRedeemed = false;

  RedemptionCode.fromJson(JsonReader jsonReader)
      : code = jsonReader.read('code'),
        addedAt = DateTime.tryParse(jsonReader.read('addedAt')),
        expiresAt = DateTime.tryParse(jsonReader.read('expiresAt')),
        keepEnabled = jsonReader.tryRead('keepEnabled') ?? false,
        isHidden = jsonReader.tryRead('isHidden') ?? false,
        gifts = (jsonReader.read('gifts') as Map<String, dynamic>)
            .map((key, value) => MapEntry(key, value.toString())),
        wasRedeemed = jsonReader.tryRead('wasRedeemed') ?? false;

  Map toJson() => {
        'code': code,
        'addedAt':
            addedAt != null ? DateFormat('yyyy-MM-dd').format(addedAt!) : '',
        'expiresAt': expiresAt != null
            ? DateFormat('yyyy-MM-dd').format(expiresAt!)
            : '',
        'keepEnabled': keepEnabled,
        'isHidden': isHidden,
        'gifts': gifts,
        'wasRedeemed': wasRedeemed,
      };

  bool get isExpired {
    if (expiresAt == null) {
      return true;
    }
    return DateTime.now().isAfter(expiresAt!);
  }

  bool get isActive {
    return keepEnabled || !isExpired;
  }

  bool get shouldRedeem {
    return !wasRedeemed && !isExpired;
  }

  @override
  int compareTo(_other) {
    RedemptionCode other = _other as RedemptionCode;
    // sort by expired
    if (!isExpired && other.isExpired) {
      return -1;
    } else if (isExpired && !other.isExpired) {
      return 1;
    }
    // then by keep enabled
    if (keepEnabled && !other.keepEnabled) {
      return -1;
    } else if (!keepEnabled && other.keepEnabled) {
      return 1;
    }
    // sort by added date
    if (addedAt == null && other.addedAt == null) {
      return 0;
    }
    if (addedAt == null) {
      return 1;
    }
    if (other.addedAt == null) {
      return -1;
    }
    return other.addedAt!.compareTo(addedAt!);
  }

  void updateFromExternalSource(RedemptionCode externalRedemptionCode) {
    if (code != externalRedemptionCode.code) {
      throw Exception(
          'Cannot update differing redemption codes ($code != ${externalRedemptionCode.code})');
    }

    addedAt = externalRedemptionCode.addedAt;
    expiresAt = externalRedemptionCode.expiresAt;
    keepEnabled = externalRedemptionCode.keepEnabled;
    isHidden = externalRedemptionCode.isHidden;
    gifts = externalRedemptionCode.gifts;
    // not copying wasRedeemed as it is internal only
  }

  @override
  String toString() {
    return code;
  }
}
