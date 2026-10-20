class BankAccountModel {
  final String code;
  final String bankName;
  final String? bankLogo;
  final String? bankLogoUrl;
  final String accountNumber;
  final String accountName;
  final String instructions;

  const BankAccountModel({
    required this.code,
    required this.bankName,
    this.bankLogo,
    this.bankLogoUrl,
    required this.accountNumber,
    required this.accountName,
    required this.instructions,
  });

  factory BankAccountModel.fromJson(Map<String, dynamic> json) {
    return BankAccountModel(
      code: json['code']?.toString() ?? 'bca',
      bankName: json['bank_name']?.toString() ?? 'Bank Transfer',
      bankLogo: json['bank_logo']?.toString(),
      bankLogoUrl: json['bank_logo_url']?.toString(),
      accountNumber: json['account_number']?.toString() ?? '',
      accountName: json['account_name']?.toString() ?? 'PT HUMORA MEDIA KREATIF',
      instructions: json['instructions']?.toString() ?? '',
    );
  }
}

class QrisModel {
  final String code;
  final bool isConfigured;
  final String? qrisImageUrl;
  final String accountName;
  final String instructions;

  const QrisModel({
    this.code = 'qris',
    this.isConfigured = false,
    this.qrisImageUrl,
    required this.accountName,
    required this.instructions,
  });

  factory QrisModel.fromJson(Map<String, dynamic> json) {
    return QrisModel(
      code: json['code']?.toString() ?? 'qris',
      isConfigured: json['is_configured'] == true,
      qrisImageUrl: json['qris_image_url']?.toString(),
      accountName: json['account_name']?.toString() ?? 'HUMORA MEDIA KREATIF',
      instructions: json['instructions']?.toString() ?? '',
    );
  }
}

class PaymentInfoModel {
  final List<BankAccountModel> bankAccounts;
  final QrisModel? qris;

  const PaymentInfoModel({
    required this.bankAccounts,
    this.qris,
  });

  factory PaymentInfoModel.fromJson(Map<String, dynamic> json) {
    List<BankAccountModel> banks = [];
    if (json['bank_accounts'] is List) {
      banks = (json['bank_accounts'] as List)
          .map((b) => BankAccountModel.fromJson(b as Map<String, dynamic>))
          .toList();
    }

    QrisModel? qrisModel;
    if (json['qris'] is Map) {
      qrisModel = QrisModel.fromJson(json['qris'] as Map<String, dynamic>);
    }

    return PaymentInfoModel(
      bankAccounts: banks,
      qris: qrisModel,
    );
  }
}
