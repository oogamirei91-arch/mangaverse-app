import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  UserModel? _currentUser;
  bool _isCheckingSession = true; // Hanya untuk splash saat baru buka app
  bool _isLoading = false;        // Untuk loading tombol di login screen
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  bool get isCheckingSession => _isCheckingSession;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;
  String? get errorMessage => _errorMessage;

  /// Cek sesi saat splash screen / startup
  Future<void> initializeAuth() async {
    _isCheckingSession = true;
    notifyListeners();

    try {
      _currentUser = await _authService.checkCurrentSession();
    } catch (_) {
      _currentUser = null;
    } finally {
      _isCheckingSession = false;
      notifyListeners();
    }
  }

  /// Melakukan proses Sign-In via Google (dengan smart fallback jika belum ada SHA-1)
  Future<bool> loginWithGoogle() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _authService.signInWithGoogle();
      if (user != null) {
        _currentUser = user;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Gagal login: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Login cepat sebagai Tamu
  Future<bool> loginAsGuest() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _authService.signInAsGuest();
      _currentUser = user;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Gagal login tamu: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Logout
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    await _authService.signOut();
    _currentUser = null;
    _isLoading = false;
    notifyListeners();
  }
}
