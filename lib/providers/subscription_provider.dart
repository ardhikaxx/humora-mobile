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
  String? _errorMessage;

  List<SubscriptionPlanModel> get plans => _plans;
  PaymentInfoModel? get paymentInfo => _paymentInfo;
  Map<String, dynamic>? get statusData => _statusData;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

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
    try {
      final res = await _api.getSubscriptionStatus();
      if (res.data != null && res.data['data'] != null) {
        _statusData = res.data['data'] as Map<String, dynamic>;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Gagal memeriksa status langganan: ${e.toString()}';
    }
  }
}
