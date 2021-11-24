import 'package:afk_redeem/data/json_reader.dart';
import 'package:afk_redeem/data/preferences.dart';

class AppMessage {
  int id;
  String content;
  bool isSkippable;
  DateTime expiresAt;
  int? showUpToVersion;
  Duration duration;

  AppMessage.fromJson(JsonReader jsonReader)
      : id = jsonReader.read('id'),
        content = jsonReader.read('content'),
        isSkippable = jsonReader.read('isSkippable'),
        expiresAt = DateTime.parse(jsonReader.read('expiresAt')),
        showUpToVersion = jsonReader.tryRead('showUpToVersion'),
        duration = Duration(seconds: jsonReader.read('showDurationSeconds'));

  bool get wasShown => Preferences().wasAppMessageShown(id);
  setWasShown() => Preferences().setAppMessageShown(id);

  bool get shouldShow {
    print('$showUpToVersion <= ${Preferences().appVersion}');
    return !wasShown &&
        DateTime.now().isBefore(expiresAt) &&
        (showUpToVersion == null ||
            Preferences().appVersion <= showUpToVersion!);
  }
}
