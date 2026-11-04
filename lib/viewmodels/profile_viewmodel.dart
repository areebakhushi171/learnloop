import 'dart:io';
import 'package:flutter/material.dart';
import '../data/repositories/auth_repository.dart';

class ProfileViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;
  bool _isUpdating = false;
  String? _errorMessage;
  String? _successMessage;

  ProfileViewModel(this._authRepository);

  bool get isUpdating => _isUpdating;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  Future<void> updateAvatar(String uid, File file) async {
    _isUpdating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authRepository.uploadProfileImage(uid, file);
      _isUpdating = false;
      _successMessage = 'Profile avatar updated successfully.';
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isUpdating = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _authRepository.signOut();
    notifyListeners();
  }

  Future<void> deleteAccount() async {
    _isUpdating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authRepository.deleteAccount();
      _isUpdating = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isUpdating = false;
      notifyListeners();
    }
  }
}
