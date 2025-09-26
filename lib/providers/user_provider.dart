import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../api/api_service.dart';
import '../models/user.dart';
import '../utils/app_logger.dart';

class UserProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final ImagePicker _picker = ImagePicker();

  User? _user;
  User? get user => _user;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  UserProvider() {
    fetchUserProfile();
  }

  Future<void> fetchUserProfile() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiService.getUserProfile();
      if (response.statusCode == 200) {
        _user = User.fromJson(jsonDecode(response.body));
      }
    } catch (e) {
      AppLogger.error('Error fetching user profile: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateUserPassword(
      String currentPassword, String newPassword) async {
    final response =
        await _apiService.updateUserPassword(currentPassword, newPassword);
    return response.statusCode == 200;
  }

  Future<bool> updateUserEmail(String email, String password) async {
    final response = await _apiService.updateUserEmail(email, password);
    if (response.statusCode == 200) {
      _user = User.fromJson(jsonDecode(response.body));
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> pickAndUpdateAvatar() async {
    final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery, maxWidth: 512, maxHeight: 512);
    if (image == null) return;

    final bytes = await image.readAsBytes();
    final base64Image =
        "data:image/${image.path.split('.').last};base64,${base64Encode(bytes)}";

    final response = await _apiService.updateUserAvatar(base64Image);
    if (response.statusCode == 200) {
      _user = User.fromJson(jsonDecode(response.body));
      notifyListeners();
    } else {
      AppLogger.error('Failed to update avatar');
    }
  }
}
