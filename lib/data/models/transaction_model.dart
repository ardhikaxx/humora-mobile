class TransactionModel {
  final int id;
  final String trxCode;
  final int planId;
  final String planName;
  final int durationDays;
  final String paymentMethod;
  final String paymentMethodLabel;
  final double amount;
  final String formattedAmount;
  final String status; // pending, success, rejected
  final bool proofUploaded;
  final String? verifiedAt;
  final String? rejectReason;
  final String? createdAt;

  const TransactionModel({
    required this.id,
    required this.trxCode,
    required this.planId,
    required this.planName,
    required this.durationDays,
    required this.paymentMethod,
    required this.paymentMethodLabel,
    required this.amount,
    required this.formattedAmount,
    required this.status,
    required this.proofUploaded,
    this.verifiedAt,
    this.rejectReason,
    this.createdAt,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] != null ? int.tryParse(json['id'].toString()) ?? 0 : 0,
      trxCode: json['trx_code']?.toString() ?? '',
      planId: json['plan_id'] != null ? int.tryParse(json['plan_id'].toString()) ?? 0 : 0,
      planName: json['plan_name']?.toString() ?? 'Paket Langganan',
      durationDays: json['duration_days'] != null
          ? int.tryParse(json['duration_days'].toString()) ?? 30
          : 30,
      paymentMethod: json['payment_method']?.toString() ?? 'bca',
      paymentMethodLabel: json['payment_method_label']?.toString() ?? 'Transfer Bank',
      amount: json['amount'] != null
          ? double.tryParse(json['amount'].toString()) ?? 0.0
          : 0.0,
      formattedAmount: json['formatted_amount']?.toString() ??
          'Rp ${json['amount']?.toString() ?? '0'}',
      status: json['status']?.toString() ?? 'pending',
      proofUploaded: json['proof_uploaded'] == true,
      verifiedAt: json['verified_at']?.toString(),
      rejectReason: json['reject_reason']?.toString(),
      createdAt: json['created_at']?.toString(),
    );
  }

  bool get isPending => status == 'pending';
  bool get isSuccess => status == 'success';
  bool get isRejected => status == 'rejected';

  String get statusLabel {
    switch (status) {
      case 'success':
        return 'Berhasil (VIP Aktif)';
      case 'rejected':
        return 'Ditolak';
      case 'pending':
      default:
        return 'Menunggu Verifikasi Admin';
    }
  }
}
