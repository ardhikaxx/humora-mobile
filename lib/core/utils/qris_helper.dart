class QrisHelper {
  /// Calculate CRC-16/CCITT-FALSE (EMVCo specification: polynomial 0x1021, init 0xFFFF)
  static String calculateCrc16(String data) {
    int crc = 0xFFFF;
    for (int i = 0; i < data.length; i++) {
      crc ^= (data.codeUnitAt(i) << 8);
      for (int j = 0; j < 8; j++) {
        if ((crc & 0x8000) != 0) {
          crc = ((crc << 1) ^ 0x1021) & 0xFFFF;
        } else {
          crc = (crc << 1) & 0xFFFF;
        }
      }
    }
    return crc.toRadixString(16).toUpperCase().padLeft(4, '0');
  }

  /// Convert a static QRIS EMVCo payload into a dynamic QRIS payload with exact amount
  static String makeDynamic(String staticPayload, num amount) {
    String payload = staticPayload.trim();

    // Remove existing CRC tag 6304 if present
    final crcIndex = payload.lastIndexOf('6304');
    if (crcIndex != -1) {
      payload = payload.substring(0, crcIndex);
    }

    // Change tag 01 from static (11) to dynamic (12)
    if (payload.startsWith('000201010211')) {
      payload = '000201010212${payload.substring(12)}';
    }

    // Remove existing Tag 54 if present
    payload = payload.replaceAll(RegExp(r'54\d{2}\d+'), '');

    // Format Tag 54 (Transaction Amount)
    final amountInt = amount.round();
    final amountStr = amountInt.toString();
    final amountLen = amountStr.length.toString().padLeft(2, '0');
    final tag54 = '54$amountLen$amountStr';

    // Insert Tag 54 right before Tag 58 (5802ID)
    final tag58Index = payload.indexOf('5802ID');
    if (tag58Index != -1) {
      payload = '${payload.substring(0, tag58Index)}$tag54${payload.substring(tag58Index)}';
    } else {
      payload = '$payload$tag54';
    }

    // Append 6304 and recalculate CRC
    final dataToSign = '${payload}6304';
    final crc = calculateCrc16(dataToSign);

    return '$dataToSign$crc';
  }
}
