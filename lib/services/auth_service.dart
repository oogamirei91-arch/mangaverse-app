import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class AuthService {
  static const String _userStorageKey = 'current_logged_in_user';
  
  // Instance GoogleSignIn resmi
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  /// Login menggunakan Google Account
  Future<UserModel?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleAccount = await _googleSignIn.signIn();
      
      if (googleAccount != null) {
        final user = UserModel(
          id: googleAccount.id,
          displayName: googleAccount.displayName ?? 'Penggemar Manga',
          email: googleAccount.email,
          photoUrl: googleAccount.photoUrl,
        );

        // Simpan sesi ke local storage
        await _saveUserToLocal(user);
        return user;
      }
      return null;
    } catch (e) {
      // Fallback untuk mode pengujian/development lokal tanpa konfigurasi Firebase/SHA1
      print('Google Sign-In Error: $e');
      rethrow;
    }
  }

  /// Memeriksa apakah user sudah login sebelumnya saat aplikasi pertama kali dibuka
  Future<UserModel?> checkCurrentSession() async {
    final prefs = await SharedPreferences.getInstance();
    final userString = prefs.getString(_userStorageKey);
    if (userString != null) {
      return UserModel.fromJson(jsonDecode(userString));
    }
    return null;
  }

  /// Logout dari akun Google dan hapus sesi lokal
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userStorageKey);
  }

  Future<void> _saveUserToLocal(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userStorageKey, jsonEncode(user.toJson()));
  }
}
