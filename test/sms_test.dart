import 'package:flutter_test/flutter_test.dart';
import 'package:sms/sms.dart';

main() {
  SmsMessage sms1 = SmsMessage("1234567890", "This is a test SmsMessage",
      date: DateTime(2018, 1, 1), threadId: 1);
  SmsMessage sms2 = SmsMessage("1234567890", "This is a test SmsMessage",
      date: DateTime(2018, 1, 1), threadId: 1);
  SmsMessage sms3 = SmsMessage("1234567890", "This is a test SmsMessage",
      date: DateTime(2018, 1, 1), threadId: 2);
  SmsThread testSmsThread = SmsThread.fromMessages([sms1, sms2]);

  test("Verifies SmsMessage equality", () {
    expect(sms1 == sms2, isTrue);
    expect(sms1 == sms3, isFalse);
  });

  test("Verifies SmsThread contains function", () {
    expect(testSmsThread.contains(sms1), isTrue);
    expect(testSmsThread.contains(sms3), isFalse);
  });
}
