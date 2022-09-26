import 'dart:io';

import 'package:app_settings/app_settings.dart';
import 'package:ardrive/utils/app_localizations_wrapper.dart';
import 'package:ardrive/utils/local_key_value_store.dart';
import 'package:ardrive/utils/secure_key_value_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/error_codes.dart' as error_codes;
import 'package:local_auth/local_auth.dart';

class BiometricAuthentication {
  BiometricAuthentication(
    this._auth,
    this._secureStore,
  );

  final LocalAuthentication _auth;
  final SecureKeyValueStore _secureStore;

  Future<bool> checkDeviceSupport() async {
    final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;

    final bool canAuthenticate =
        canAuthenticateWithBiometrics || await _auth.isDeviceSupported();

    return canAuthenticate;
  }

  Future<bool> isEnabled() async {
    final localStore = await LocalKeyValueStore.getInstance();
    final isEnabled = localStore.getBool('biometricEnabled');

    return isEnabled ?? false;
  }

  Future<void> disable() async {
    final localStore = await LocalKeyValueStore.getInstance();
    localStore.remove('biometricEnabled');
  }

  Future<bool> isActive() async {
    final hasPassword = await _secureStore.getString('password');

    return hasPassword != null;
  }

  Future<bool> authenticate(BuildContext context) async {
    try {
      final canAuthenticate = await checkDeviceSupport();

      if (!canAuthenticate) {
        throw BiometricUnknownException();
      }

      final authenticated = await _auth.authenticate(
        localizedReason:
            // ignore: use_build_context_synchronously
            appLocalizationsOf(context).loginUsingBiometricCredential,
        options: const AuthenticationOptions(
          biometricOnly: true,
        ),
      );

      return authenticated;
    } on PlatformException catch (e) {
      debugPrint(e.toString());
      debugPrint(e.code);
      switch (e.code) {
        case error_codes.notAvailable:
          if (await isEnabled()) {
            await disable();
          }

          /// If there is available biometrics and yet received a `NotAvailable`,
          /// it failed to authenticate. It can happen when user use the wrong fingerprint or faceid
          /// for many times. Yet the error code is not precisely,
          /// this is how it is handled in iOS 16 iPhone 11.
          final availables = await _auth.getAvailableBiometrics();

          /// Have enrolled biometrics but yet failed, so it is locked.
          if (availables.isNotEmpty) {
            throw BiometricLockedException();
          }

          final deviceSupports = await _auth.isDeviceSupported();

          /// The device supports but biometrics are not enrolled
          if (deviceSupports) {
            throw BiometricNotEnrolledException();
          }

          /// If there is not any biometrics available, show the correct modal
          throw BiometricNotAvailableException();
        case error_codes.lockedOut:
          throw BiometricLockedException();
        case error_codes.passcodeNotSet:
          throw BiometricPasscodeNotSetException();
        case error_codes.notEnrolled:
          throw BiometricNotEnrolledException();
        default:
          throw BiometricUnknownException();
      }
    } on BiometricException {
      rethrow;
    }
  }
}

/// Open the Platform specific settings where biometrics option can be enabled
Future<void> openSettingsToEnableBiometrics() async {
  if (Platform.isAndroid) {
    await AppSettings.openDeviceSettings();
    return;
  }
  await AppSettings.openAppSettings();
  return;
}

class BiometricException implements Exception {}

class BiometricUnknownException implements BiometricException {}

class BiometricNotAvailableException implements BiometricException {}

class BiometricLockedException implements BiometricException {}

class BiometricPasscodeNotSetException implements BiometricException {}

class BiometricNotEnrolledException implements BiometricException {}
