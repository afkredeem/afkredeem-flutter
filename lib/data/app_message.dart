import 'package:afk_redeem/data/json_reader.dart';
import 'package:afk_redeem/data/preferences.dart';

class AppMessage {
  int id;
  String content;
  bool isSkippable;
  DateTime expiresAt;
  Duration duration;

  AppMessage.fromJson(JsonReader jsonReader)
      : id = jsonReader.read('id'),
        content = jsonReader.read('content'),
        isSkippable = jsonReader.read('isSkippable'),
        expiresAt = DateTime.parse(jsonReader.read('expiresAt')),
        duration = Duration(seconds: jsonReader.read('showDurationSeconds'));

  bool get wasShown => Preferences().wasAppMessageShown(id);
  setWasShown() => Preferences().setAppMessageShown(id);
}
