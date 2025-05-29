import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/biometric_service.dart';
import '../../providers/settings_provider.dart';
import 'login_screen.dart';

class AuthScreen extends ConsumerStatefulWidget {
  final Widget child;

  const AuthScreen({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  bool _isAuthenticated = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthMethod();
    });
  }

  Future<void> _checkAuthMethod() async {
    final settings = ref.read(settingsProvider);
    settings.whenData((data) {
      final useFingerprint = data['is_activate_fingerprint']?.toLowerCase() == 'true';
      if (useFingerprint) {
        _authenticateWithBiometrics();
      }
      // If fingerprint is not active, stay on current screen which will show login
    });
  }

  Future<void> _authenticateWithBiometrics() async {
    try {
      setState(() {
        _errorMessage = null;
      });

      final isAuthenticated = await BiometricService.authenticate();
      
      if (mounted) {
        setState(() {
          _isAuthenticated = isAuthenticated;
          if (!isAuthenticated) {
            _errorMessage = 'Biometric authentication failed. Please try again.';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error: ${e.toString()}';
          _isAuthenticated = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsProvider);

    return settingsAsync.when(
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Error loading settings: $error',
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => ref.refresh(settingsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (settings) {
        if (_isAuthenticated) {
          return widget.child;
        }

        final useFingerprint = settings['is_activate_fingerprint']?.toLowerCase() == 'true';
        
        // If fingerprint is not active, show login screen
        if (!useFingerprint) {
          return const LoginScreen();
        }

        // Show biometric authentication screen
        return Scaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.fingerprint,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Biometric Authentication Required',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  if (_errorMessage != null) ...[
                    Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                  ],
                  ElevatedButton.icon(
                    onPressed: _authenticateWithBiometrics,
                    icon: const Icon(Icons.fingerprint),
                    label: const Text('Authenticate with Fingerprint'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
} 