import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

class NetworkController extends GetxController with WidgetsBindingObserver {
  Timer? _pollingTimer;

  bool _hasConnection = true;
  bool _isChecking = false;
  bool _isRefreshing = false;

  bool get hasConnection => _hasConnection;
  bool get isChecking => _isChecking;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    _checkConnection();
    _pollingTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _checkConnection(),
    );
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollingTimer?.cancel();
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      recheckConnection();
    }
  }

  Future<void> recheckConnection() async {
    await _checkConnection(showLoader: !_hasConnection);
  }

  Future<void> _checkConnection({bool showLoader = false}) async {
    if (_isRefreshing) {
      return;
    }

    _isRefreshing = true;
    if (showLoader) {
      _isChecking = true;
      update();
    }

    bool nextConnectionState = false;

    try {
      final result = await InternetAddress.lookup(
        'example.com',
      ).timeout(const Duration(seconds: 3));
      nextConnectionState =
          result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } catch (_) {
      nextConnectionState = false;
    }

    _hasConnection = nextConnectionState;
    _isChecking = false;
    _isRefreshing = false;
    update();
  }
}
