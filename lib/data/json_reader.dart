import 'package:afk_redeem/data/error_reporter.dart';

class JsonReader {
  String context;
  Map<String, dynamic>? json;

  JsonReader({context, this.json}) : context = context ?? '';

  T read<T>(String field) {
    return readFrom<T>(json!, field);
  }

  T readFrom<T>(Map<String, dynamic> json, String field) {
    if (!json.containsKey(field)) {
      throw JsonReaderException('Missing field \'$field\' on $context\n$json');
    }
    if (!(json[field] is T)) {
      throw JsonReaderException(
          'Received field \'$field\' of type ${json[field].runtimeType}, expected $T, on $context\n$json');
    }
    return json[field] as T;
  }

  T? tryRead<T>(field) {
    return tryReadFrom(json!, field);
  }

  T? tryReadFrom<T>(Map<String, dynamic> json, field) {
    if (!json.containsKey(field)) {
      return null;
    }
    if (!(json[field] is T)) {
      return null;
    }
    return json[field] as T;
  }
}

class JsonReaderException implements Exception {
  String error = 'Json parse error';
  String reason;

  JsonReaderException(this.reason);

  report() {
    ErrorReporter.report(this, reason);
  }

  @override
  String toString() {
    // not printing reason cause error reporter receives it as a separate argument
    return error;
  }
}
