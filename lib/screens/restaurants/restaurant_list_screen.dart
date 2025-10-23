import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/restaurant_provider.dart';
import '../../models/restaurant.dart';
import 'menu_screen.dart';

class RestaurantListScreen extends StatelessWidget {
  const RestaurantListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Restaurant'),
        elevation: 0,
      ),
      body: Consumer<RestaurantProvider>(
        builder: (context, restaurantProvider, child) {
          final restaurants = restaurantProvider.restaurants;

          if (restaurants.isEmpty) {
            return const Center(
              child: Text('No restaurants available'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: restaurants.length,
            itemBuilder: (context, index) {
              final restaurant = restaurants[index];
              return _RestaurantCard(
                restaurant: restaurant,
                onTap: () => _selectRestaurant(context, restaurant),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _selectRestaurant(BuildContext context, Restaurant restaurant) async {
    final restaurantProvider = Provider.of<RestaurantProvider>(context, listen: false);

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading menu...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      await restaurantProvider.selectRestaurant(restaurant);

      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog

        if (restaurantProvider.error == null) {
          // Navigate to menu screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const MenuScreen(),
            ),
          );
        } else {
          // Show error
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${restaurantProvider.error}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _RestaurantCard extends StatelessWidget {
  final Restaurant restaurant;
  final VoidCallback onTap;

  const _RestaurantCard({
    required this.restaurant,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (restaurant.imageUrl != null)
              Image.network(
                restaurant.imageUrl!,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200,
                    color: Colors.grey[300],
                    child: const Icon(
                      Icons.restaurant,
                      size: 64,
                      color: Colors.grey,
                    ),
                  );
                },
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    restaurant.name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  if (restaurant.description != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      restaurant.description!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Spacer(),
                      TextButton.icon(
                        onPressed: onTap,
                        icon: const Icon(Icons.restaurant_menu),
                        label: const Text('View Menu'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
