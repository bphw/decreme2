import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';
import '../config/environment.dart';

class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();
  
  static Future<bool> authenticate() async {
    // Bypass authentication in development
    if (Environment.isDevelopment) {
      return true;
    }

    try {
      final isAvailable = await _auth.canCheckBiometrics;
      final isDeviceSupported = await _auth.isDeviceSupported();

      if (!isAvailable || !isDeviceSupported) {
        return false;
      }

      return await _auth.authenticate(
        localizedReason: 'Please authenticate to continue',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } on PlatformException catch (e) {
      print('Error authenticating: $e');
      return false;
    }
  }
} 