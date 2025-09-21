import 'package:mason_logger/mason_logger.dart';

extension LoggerExtensions on Logger {
  void success(String message) {
    info(lightGreen.wrap(message) ?? message);
  }
}
