import 'dart:convert';
import 'package:flutter/material.dart';
import '../api/api_service.dart';
import '../models/asset.dart';
import '../models/asset_category.dart';
import '../utils/app_logger.dart';

class AssetProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<Asset> _assets = [];
  List<Asset> get assets => _assets;

  List<AssetCategory> _categories = [];
  List<AssetCategory> get categories => _categories;

  double get totalAssets => _calculateTotalByType('asset');
  double get totalLiabilities => _calculateTotalByType('liability');
  double get netWorth => totalAssets - totalLiabilities;

  AssetProvider() {
    fetchData();
  }

  Future<void> fetchData() async {
    _isLoading = true;
    notifyListeners();
    try {
      await Future.wait([
        _fetchAssets(),
        _fetchCategories(),
      ]);
    } catch (e) {
      AppLogger.error('Error fetching asset data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _fetchAssets() async {
    final response = await _apiService.getAssets();
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List;
      _assets = data.map((item) => Asset.fromJson(item)).toList();
    }
  }

  Future<void> _fetchCategories() async {
    final response = await _apiService.getAssetCategories();
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List;
      _categories = data.map((item) => AssetCategory.fromJson(item)).toList();
    }
  }

  Future<bool> createAsset(String name, String categoryId) async {
    final response = await _apiService.createAsset(name, categoryId);
    if (response.statusCode == 200) {
      await _fetchAssets(); // Refresh asset list
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> createAssetRecord(
      String assetId, DateTime date, double amount) async {
    final dateStr = date.toIso8601String();
    final response =
        await _apiService.createAssetRecord(assetId, dateStr, amount);
    if (response.statusCode == 200) {
      await _fetchAssets(); // Refresh asset list
      notifyListeners();
      return true;
    }
    return false;
  }

  double _calculateTotalByType(String type) {
    double total = 0;
    final categoryMap = {for (var cat in _categories) cat.id: cat};

    for (var asset in _assets) {
      if (categoryMap[asset.categoryId]?.type == type) {
        total += asset.latestAmount;
      }
    }
    return total;
  }

  AssetCategory? getCategoryById(String id) {
    try {
      return _categories.firstWhere((cat) => cat.id == id);
    } catch (e) {
      return null;
    }
  }
}
