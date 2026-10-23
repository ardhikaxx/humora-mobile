import 'package:flutter_test/flutter_test.dart';
import 'package:humora_mobile/core/utils/qris_helper.dart';

void main() {
  group('QrisHelper', () {
    test('calculateCrc16 produces valid 4-character hex uppercase CRC', () {
      final sample = '0002010102115802ID5923PT HUMORA MEDIA KREATIF6007JAKARTA6304';
      final crc = QrisHelper.calculateCrc16(sample);

      expect(crc.length, 4);
      expect(crc, matches(r'^[A-F0-9]{4}$'));
    });

    test('makeDynamic converts static payload to dynamic with exact nominal', () {
      final staticPayload = '00020101021153033605802ID5923PT HUMORA MEDIA KREATIF6007JAKARTA63040000';
      final dynamicPayload = QrisHelper.makeDynamic(staticPayload, 15000);

      expect(dynamicPayload.contains('000201010212'), isTrue);
      expect(dynamicPayload.contains('540515000'), isTrue);
      expect(dynamicPayload.contains('5802ID'), isTrue);
      expect(dynamicPayload.endsWith(QrisHelper.calculateCrc16(
        dynamicPayload.substring(0, dynamicPayload.lastIndexOf('6304') + 4),
      )), isTrue);
    });
  });
}
