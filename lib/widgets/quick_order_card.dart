import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/group.dart';
import '../screens/groups/group_menu_screen.dart';
import '../config/tropical_theme.dart';

class QuickOrderCard extends StatelessWidget {
  final Group group;
  final String? restaurantName;
  final int orderCount;

  const QuickOrderCard({
    super.key,
    required this.group,
    this.restaurantName,
    this.orderCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final hasDeadline = group.orderDeadline != null;
    final isDeadlineSoon = hasDeadline &&
        group.orderDeadline!.difference(DateTime.now()).inHours < 2;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: TropicalColors.orange.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isDeadlineSoon
              ? TropicalColors.error
              : Colors.black.withValues(alpha: 0.04),
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => GroupMenuScreen(groupId: group.id),
              ),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  children: [
                    // Icon Container with gradient background
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            TropicalColors.orange,
                            TropicalColors.coral,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: TropicalColors.orange.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.restaurant_menu_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Group Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            group.name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: TropicalColors.darkText,
                              letterSpacing: -0.3,
                            ),
                          ),
                          if (restaurantName != null) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.store_rounded,
                                  size: 16,
                                  color: TropicalColors.mediumText,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    restaurantName!,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: TropicalColors.mediumText,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Active Badge
                    if (group.isActive)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: TropicalColors.mint.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: TropicalColors.mint,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'Active',
                              style: TextStyle(
                                color: TropicalColors.darkGreen,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),

                // Deadline Section (if exists)
                if (hasDeadline) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDeadlineSoon
                            ? [
                                TropicalColors.error.withValues(alpha: 0.12),
                                TropicalColors.error.withValues(alpha: 0.06),
                              ]
                            : [
                                TropicalColors.orange.withValues(alpha: 0.08),
                                TropicalColors.coral.withValues(alpha: 0.05),
                              ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDeadlineSoon
                            ? TropicalColors.error.withValues(alpha: 0.2)
                            : TropicalColors.orange.withValues(alpha: 0.15),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isDeadlineSoon
                                ? TropicalColors.error.withValues(alpha: 0.15)
                                : TropicalColors.orange.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            isDeadlineSoon
                                ? Icons.timer_off_rounded
                                : Icons.schedule_rounded,
                            size: 20,
                            color: isDeadlineSoon
                                ? TropicalColors.error
                                : TropicalColors.orange,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isDeadlineSoon ? '⚠️ Deadline Soon!' : 'Order Deadline',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: isDeadlineSoon
                                      ? TropicalColors.error
                                      : TropicalColors.darkText,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                DateFormat('MMM d, h:mm a').format(group.orderDeadline!),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: TropicalColors.mediumText,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isDeadlineSoon
                                ? TropicalColors.error
                                : TropicalColors.orange,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _formatDuration(group.timeUntilDeadline),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 18),

                // Order Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => GroupMenuScreen(groupId: group.id),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TropicalColors.orange,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shadowColor: TropicalColors.orange.withValues(alpha: 0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.shopping_bag_rounded,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          orderCount > 0
                              ? 'Continue Order ($orderCount items)'
                              : 'Start Order Now',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration? duration) {
    if (duration == null) return 'No deadline';

    if (duration.inDays > 0) {
      final hours = duration.inHours % 24;
      if (hours > 0) {
        return '${duration.inDays}d ${hours}h';
      }
      return '${duration.inDays}d';
    }

    if (duration.inHours > 0) {
      final minutes = duration.inMinutes % 60;
      if (minutes > 0) {
        return '${duration.inHours}h ${minutes}m';
      }
      return '${duration.inHours}h';
    }

    return '${duration.inMinutes}m';
  }
}
