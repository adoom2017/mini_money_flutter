import 'dart:convert';
import 'package:flutter/material.dart';
import '../api/api_service.dart';
import '../models/transaction.dart';
import '../utils/app_logger.dart';

class TransactionProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<Transaction> _transactions = [];
  List<Transaction> get transactions => _transactions;

  TransactionProvider() {
    fetchTransactions();
  }

  Future<void> fetchTransactions() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiService.getTransactions();
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        _transactions = data.map((item) => Transaction.fromJson(item)).toList();
        // Sort by date descending
        _transactions.sort((a, b) => b.date.compareTo(a.date));
      }
    } catch (e) {
      AppLogger.error('Error fetching transactions: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteTransaction(String id) async {
    final response = await _apiService.deleteTransaction(id);
    if (response.statusCode == 200) {
      _transactions.removeWhere((t) => t.id == id);
      notifyListeners();
      return true;
    }
    return false;
  }
}
