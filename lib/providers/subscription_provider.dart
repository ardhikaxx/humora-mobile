import 'package:flutter/material.dart';
import '../core/network/api_service.dart';
import '../data/models/payment_info_model.dart';
import '../data/models/subscription_plan_model.dart';

class SubscriptionProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  List<SubscriptionPlanModel> _plans = [];
  PaymentInfoModel? _paymentInfo;
  Map<String, dynamic>? _statusData;
  bool _isLoading = false;
  bool _isLoadingStatus = false;
  String? _errorMessage;

  List<SubscriptionPlanModel> get plans => _plans;
  PaymentInfoModel? get paymentInfo => _paymentInfo;
  Map<String, dynamic>? get statusData => _statusData;
  bool get isLoading => _isLoading;
  bool get isLoadingStatus => _isLoadingStatus;
  String? get errorMessage => _errorMessage;

  bool get isPremium => _statusData?['is_premium'] == true;
  String get effectiveTier => _statusData?['effective_tier']?.toString() ?? 'free';
  int get remainingDays => _statusData?['remaining_days'] != null
      ? int.tryParse(_statusData!['remaining_days'].toString()) ?? 0
      : 0;
  String? get validUntil => _statusData?['valid_until']?.toString();

  Map<String, dynamic>? get activePlan =>
      _statusData?['active_plan'] as Map<String, dynamic>?;
  String? get activePlanName => activePlan?['name']?.toString();
  String? get activePlanStartDate => activePlan?['start_date']?.toString();
  String? get activePlanEndDate => activePlan?['end_date']?.toString();

  Map<String, dynamic>? get pendingTransaction =>
      _statusData?['pending_transaction'] as Map<String, dynamic>?;

  Future<void> fetchPlans() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _api.getSubscriptionPlans();
      if (res.data != null && res.data['data'] is List) {
        _plans = (res.data['data'] as List)
            .map((item) => SubscriptionPlanModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      _errorMessage = 'Gagal memuat paket VIP: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchPaymentInfo() async {
    try {
      final res = await _api.getPaymentInfo();
      if (res.data != null && res.data['data'] != null) {
        _paymentInfo = PaymentInfoModel.fromJson(
          res.data['data'] as Map<String, dynamic>,
        );
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Gagal memuat informasi pembayaran: ${e.toString()}';
    }
  }

  Future<void> fetchStatus() async {
    _isLoadingStatus = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _api.getSubscriptionStatus();
      if (res.data != null && res.data['data'] != null) {
        _statusData = res.data['data'] as Map<String, dynamic>;
      }
    } catch (e) {
      _errorMessage = 'Gagal memeriksa status langganan: ${e.toString()}';
    } finally {
      _isLoadingStatus = false;
      notifyListeners();
    }
  }
}
