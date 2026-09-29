import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();

  /// Memeriksa apakah perangkat mendukung autentikasi biometrik atau kredensial layar kunci
  static Future<bool> canAuthenticate() async {
    try {
      final bool canCheck = await _auth.canCheckBiometrics;
      final bool isDeviceSupported = await _auth.isDeviceSupported();
      return canCheck || isDeviceSupported;
    } catch (_) {
      return false;
    }
  }

  /// Mengambil daftar biometrik yang terpasang di perangkat (fingerprint, face, dll)
  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (_) {
      return [];
    }
  }

  /// Meminta autentikasi sidik jari atau biometrik kepada pengguna
  static Future<bool> authenticate({
    String reason = 'Pindai sidik jari atau biometrik Anda untuk keamanan Safe Search',
  }) async {
    try {
      final bool isSupported = await canAuthenticate();
      if (!isSupported) {
        // Jika perangkat tidak memiliki sensor biometrik atau emulator, izinkan langsung
        return true;
      }

      final bool didAuthenticate = await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // Memungkinkan fallback PIN / Pola perangkat jika sidik jari gagal
          useErrorDialogs: true,
        ),
      );
      return didAuthenticate;
    } on PlatformException catch (e) {
      // Kode error umum: NotAvailable, NotEnrolled, LockedOut, PermanentlyLockedOut
      if (e.code == 'NotEnrolled' || e.code == 'PasscodeNotSet') {
        // Jika belum ada sidik jari yang didaftarkan di setelan HP
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}
