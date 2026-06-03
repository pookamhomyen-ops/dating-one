String timeGreetingTh() {
  final hour = DateTime.now().hour;
  if (hour < 12) return 'สวัสดีตอนเช้า';
  if (hour < 17) return 'สวัสดีตอนบ่าย';
  if (hour < 21) return 'สวัสดีตอนเย็น';
  return 'สวัสดีตอนค่ำ';
}
