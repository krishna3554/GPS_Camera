import 'package:intl/intl.dart';

class AppDateUtils {
  static String formatDate(DateTime dt) => DateFormat('MM/dd/yyyy').format(dt);

  static String formatTime(DateTime dt) => DateFormat('hh:mm a').format(dt);

  static String formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
