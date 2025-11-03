import 'package:connectivity_plus/connectivity_plus.dart';

/// Utility class for checking network connectivity status
class ConnectivityUtils {
  /// Check if device is currently connected to internet
  static Future<bool> isConnected() async {
    final result = await Connectivity().checkConnectivity();
    return result != ConnectivityResult.none;
  }

  /// Stream of connectivity changes
  /// Returns true when connected, false when disconnected
  static Stream<bool> get onConnectivityChanged {
    return Connectivity().onConnectivityChanged.map(
      (result) => result != ConnectivityResult.none,
    );
  }

  /// Get current connectivity type as a string
  static Future<String> getConnectivityType() async {
    final result = await Connectivity().checkConnectivity();

    switch (result) {
      case ConnectivityResult.wifi:
        return 'WiFi';
      case ConnectivityResult.mobile:
        return 'Mobile Data';
      case ConnectivityResult.ethernet:
        return 'Ethernet';
      case ConnectivityResult.none:
      default:
        return 'Offline';
    }
  }
}
