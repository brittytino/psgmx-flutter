import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class ConnectivityService {
  // Singleton
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _connectionChangeController = StreamController<bool>.broadcast();

  Stream<bool> get connectionChange => _connectionChangeController.stream;

  bool _hasConnection = true;
  bool get hasConnection => _hasConnection;

  void init() {
    _connectivity.onConnectivityChanged.listen(_connectionChange);
    checkConnection();
  }

  void _connectionChange(List<ConnectivityResult> result) {
    checkConnection(result);
  }

  Future<bool> checkConnection([List<ConnectivityResult>? result]) async {
    final previousConnection = _hasConnection;

    result ??= await _connectivity.checkConnectivity();
    
    // logic: If list contains .none, or is empty -> false. 
    // actually, if list contains ONLY .none -> false. 
    // If it contains .mobile or .wifi or .ethernet -> true.
    
    bool hasActiveInterface = false;
    for (var r in result) {
      if (r == ConnectivityResult.mobile || 
          r == ConnectivityResult.wifi || 
          r == ConnectivityResult.ethernet || 
          r == ConnectivityResult.vpn) {
        hasActiveInterface = true;
        break;
      }
    }

    _hasConnection = hasActiveInterface;

    if (previousConnection != _hasConnection) {
      _connectionChangeController.add(_hasConnection);
    }

    return _hasConnection;
  }
  
  void dispose() {
    _connectionChangeController.close();
  }
}

// A widget to listen and show offline status
class OfflineBanner extends StatefulWidget {
  final Widget child;
  const OfflineBanner({super.key, required this.child});

  @override
  State<OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends State<OfflineBanner> {
  late StreamSubscription _connectionSubscription;
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    ConnectivityService().init();
    _isOffline = !ConnectivityService().hasConnection;
    _connectionSubscription = ConnectivityService().connectionChange.listen((isConnected) {
      setState(() {
        _isOffline = !isConnected;
      });
    });
  }

  @override
  void dispose() {
    _connectionSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_isOffline)
          Container(
            width: double.infinity,
            color: Colors.red[900],
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: const Text(
              "You are offline. Some features may be unavailable.",
              style: TextStyle(color: Colors.white, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
        Expanded(child: widget.child),
      ],
    );
  }
}
