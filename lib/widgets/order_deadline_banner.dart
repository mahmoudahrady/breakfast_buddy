import 'package:flutter/material.dart';
import 'dart:async';

class OrderDeadlineBanner extends StatefulWidget {
  final DateTime deadline;
  final VoidCallback? onDeadlineReached;

  const OrderDeadlineBanner({
    super.key,
    required this.deadline,
    this.onDeadlineReached,
  });

  @override
  State<OrderDeadlineBanner> createState() => _OrderDeadlineBannerState();
}

class _OrderDeadlineBannerState extends State<OrderDeadlineBanner> {
  Timer? _timer;
  Duration? _timeRemaining;

  @override
  void initState() {
    super.initState();
    _updateTimeRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateTimeRemaining();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updateTimeRemaining() {
    final now = DateTime.now();
    if (now.isAfter(widget.deadline)) {
      if (mounted) {
        setState(() {
          _timeRemaining = null;
        });
        widget.onDeadlineReached?.call();
      }
      _timer?.cancel();
    } else {
      if (mounted) {
        setState(() {
          _timeRemaining = widget.deadline.difference(now);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_timeRemaining == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        color: Colors.red,
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text(
              'Order deadline has passed',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    final hours = _timeRemaining!.inHours;
    final minutes = _timeRemaining!.inMinutes.remainder(60);
    final seconds = _timeRemaining!.inSeconds.remainder(60);

    // Determine color based on time remaining
    Color backgroundColor;
    if (hours < 1) {
      backgroundColor = Colors.red; // Less than 1 hour - urgent
    } else if (hours < 3) {
      backgroundColor = Colors.orange; // Less than 3 hours - warning
    } else {
      backgroundColor = Colors.blue; // More than 3 hours - info
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: backgroundColor,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            hours < 1 ? Icons.timer : Icons.schedule,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            'Order closes in: ',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              _formatDuration(_timeRemaining!),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }
}
