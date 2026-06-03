import 'package:intl/intl.dart';

String formatPostTime(DateTime time) {
  final now = DateTime.now();
  final diff = now.difference(time);

  if (diff.inMinutes < 1) return 'เมื่อสักครู่';
  if (diff.inMinutes < 60) return '${diff.inMinutes} นาทีที่แล้ว';
  if (diff.inHours < 24) return '${diff.inHours} ชม.ที่แล้ว';
  if (diff.inDays < 7) return '${diff.inDays} วันที่แล้ว';
  return DateFormat('d MMM yyyy', 'th').format(time);
}

String formatChatTime(DateTime time) {
  final now = DateTime.now();
  if (time.year == now.year &&
      time.month == now.month &&
      time.day == now.day) {
    return DateFormat('HH:mm').format(time);
  }
  if (now.difference(time).inDays < 7) {
    return DateFormat('EEE', 'th').format(time);
  }
  return DateFormat('d/M/yy').format(time);
}
