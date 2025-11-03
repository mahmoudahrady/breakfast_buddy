import 'package:flutter/material.dart';

/// Enum representing the status of an order in the workflow
enum OrderStatus {
  pending,
  confirmed,
  preparing,
  ready,
  delivered,
  cancelled;

  /// Get display name for the status
  String get displayName {
    switch (this) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.preparing:
        return 'Preparing';
      case OrderStatus.ready:
        return 'Ready';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  /// Get color for the status
  Color get color {
    switch (this) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.confirmed:
        return Colors.blue;
      case OrderStatus.preparing:
        return Colors.purple;
      case OrderStatus.ready:
        return Colors.green;
      case OrderStatus.delivered:
        return Colors.grey;
      case OrderStatus.cancelled:
        return Colors.red;
    }
  }

  /// Get icon for the status
  IconData get icon {
    switch (this) {
      case OrderStatus.pending:
        return Icons.schedule;
      case OrderStatus.confirmed:
        return Icons.check_circle_outline;
      case OrderStatus.preparing:
        return Icons.restaurant;
      case OrderStatus.ready:
        return Icons.check_circle;
      case OrderStatus.delivered:
        return Icons.done_all;
      case OrderStatus.cancelled:
        return Icons.cancel;
    }
  }

  /// Check if this status can transition to another status
  bool canTransitionTo(OrderStatus newStatus) {
    // Cancelled orders can't transition to anything
    if (this == OrderStatus.cancelled) return false;

    // Delivered orders can only be cancelled
    if (this == OrderStatus.delivered) {
      return newStatus == OrderStatus.cancelled;
    }

    switch (this) {
      case OrderStatus.pending:
        return newStatus == OrderStatus.confirmed ||
            newStatus == OrderStatus.cancelled;
      case OrderStatus.confirmed:
        return newStatus == OrderStatus.preparing ||
            newStatus == OrderStatus.cancelled;
      case OrderStatus.preparing:
        return newStatus == OrderStatus.ready ||
            newStatus == OrderStatus.cancelled;
      case OrderStatus.ready:
        return newStatus == OrderStatus.delivered ||
            newStatus == OrderStatus.cancelled;
      case OrderStatus.delivered:
      case OrderStatus.cancelled:
        return false;
    }
  }

  /// Get next logical status in the workflow
  OrderStatus? get nextStatus {
    switch (this) {
      case OrderStatus.pending:
        return OrderStatus.confirmed;
      case OrderStatus.confirmed:
        return OrderStatus.preparing;
      case OrderStatus.preparing:
        return OrderStatus.ready;
      case OrderStatus.ready:
        return OrderStatus.delivered;
      case OrderStatus.delivered:
      case OrderStatus.cancelled:
        return null; // No next status
    }
  }

  /// Parse from string (for Firestore)
  static OrderStatus fromString(String? value) {
    if (value == null) return OrderStatus.pending;

    return OrderStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => OrderStatus.pending,
    );
  }
}
