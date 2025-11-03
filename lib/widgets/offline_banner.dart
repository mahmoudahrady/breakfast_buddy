import 'package:flutter/material.dart';
import '../utils/connectivity_utils.dart';

/// Banner that shows when the device is offline
/// Automatically appears/disappears based on connectivity status
class OfflineBanner extends StatelessWidget {
  /// Optional callback when retry button is pressed
  final VoidCallback? onRetry;

  const OfflineBanner({
    super.key,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: ConnectivityUtils.onConnectivityChanged,
      initialData: true, // Assume online initially
      builder: (context, snapshot) {
        final isOnline = snapshot.data ?? true;

        if (isOnline) {
          return const SizedBox.shrink();
        }

        return MaterialBanner(
          backgroundColor: Colors.orange.shade100,
          leading: const Icon(
            Icons.wifi_off,
            color: Colors.orange,
          ),
          content: const Text(
            'You are offline. Showing cached data.',
            style: TextStyle(color: Colors.black87),
          ),
          actions: [
            if (onRetry != null)
              TextButton(
                onPressed: onRetry,
                child: const Text('Retry'),
              )
            else
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
                },
                child: const Text('Dismiss'),
              ),
          ],
        );
      },
    );
  }
}

/// Simple connectivity indicator widget
/// Shows a colored dot indicating connection status
class ConnectivityIndicator extends StatelessWidget {
  /// Size of the indicator dot
  final double size;

  /// Whether to show the status text
  final bool showText;

  const ConnectivityIndicator({
    super.key,
    this.size = 12.0,
    this.showText = false,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: ConnectivityUtils.onConnectivityChanged,
      initialData: true,
      builder: (context, snapshot) {
        final isOnline = snapshot.data ?? true;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isOnline ? Colors.green : Colors.red,
              ),
            ),
            if (showText) ...[
              const SizedBox(width: 8),
              Text(
                isOnline ? 'Online' : 'Offline',
                style: TextStyle(
                  fontSize: 12,
                  color: isOnline ? Colors.green : Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

/// Widget that wraps content and shows offline overlay when needed
class OfflineWrapper extends StatelessWidget {
  /// Child widget to wrap
  final Widget child;

  /// Optional custom offline message
  final String? offlineMessage;

  const OfflineWrapper({
    super.key,
    required this.child,
    this.offlineMessage,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: ConnectivityUtils.onConnectivityChanged,
      initialData: true,
      builder: (context, snapshot) {
        final isOnline = snapshot.data ?? true;

        return Stack(
          children: [
            child,
            if (!isOnline)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  color: Colors.orange.shade100,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.wifi_off,
                        size: 16,
                        color: Colors.orange,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          offlineMessage ?? 'Offline - Showing cached data',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
