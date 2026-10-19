import 'dart:io';
import 'package:flutter/material.dart';
import '../core/network/api_service.dart';
import '../data/models/transaction_model.dart';

class TransactionProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  List<TransactionModel> _transactions = [];
  TransactionModel? _currentTransaction;
  bool _isLoading = false;
  bool _isUploading = false;
  String? _errorMessage;

  List<TransactionModel> get transactions => _transactions;
  TransactionModel? get currentTransaction => _currentTransaction;
  bool get isLoading => _isLoading;
  bool get isUploading => _isUploading;
  String? get errorMessage => _errorMessage;

  TransactionModel? get latestPendingTransaction {
    try {
      return _transactions.firstWhere((t) => t.isPending);
    } catch (_) {
      return null;
    }
  }

  Future<void> fetchTransactions() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _api.getTransactions();
      if (res.data != null && res.data['data'] is List) {
        _transactions = (res.data['data'] as List)
            .map((item) => TransactionModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      _errorMessage = 'Gagal memuat riwayat transaksi: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<TransactionModel?> uploadPaymentProof({
    required int planId,
    required String paymentMethod,
    required File proofFile,
    int? transactionId,
    String? trxCode,
  }) async {
    _isUploading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _api.uploadPaymentProof(
        planId: planId,
        paymentMethod: paymentMethod,
        proofFile: proofFile,
        transactionId: transactionId,
        trxCode: trxCode,
      );

      if (res.data != null && res.data['data'] != null && res.data['data']['transaction'] != null) {
        final trx = TransactionModel.fromJson(
          res.data['data']['transaction'] as Map<String, dynamic>,
        );
        _currentTransaction = trx;
        _transactions.insert(0, trx);
        return trx;
      }
      return null;
    } catch (e) {
      _errorMessage = 'Gagal mengunggah bukti pembayaran: ${e.toString()}';
      rethrow;
    } finally {
      _isUploading = false;
      notifyListeners();
    }
  }

  Future<TransactionModel?> checkTransactionStatus(int id) async {
    try {
      final res = await _api.getTransactionDetail(id);
      if (res.data != null && res.data['data'] != null && res.data['data']['transaction'] != null) {
        final updated = TransactionModel.fromJson(
          res.data['data']['transaction'] as Map<String, dynamic>,
        );
        _currentTransaction = updated;

        final idx = _transactions.indexWhere((t) => t.id == id);
        if (idx != -1) {
          _transactions[idx] = updated;
        } else {
          _transactions.insert(0, updated);
        }
        notifyListeners();
        return updated;
      }
      return null;
    } catch (e) {
      _errorMessage = 'Gagal memeriksa status: ${e.toString()}';
      return null;
    }
  }

  void setCurrentTransaction(TransactionModel trx) {
    _currentTransaction = trx;
    notifyListeners();
  }
}
