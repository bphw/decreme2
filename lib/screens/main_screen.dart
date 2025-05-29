import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'catalog/cake_catalog_screen.dart';
import 'cart/cart_screen.dart';
import 'profile/profile_screen.dart';
import '../providers/cart_provider.dart';
import '../screens/settings/settings_screen.dart';
import 'orders/orders_screen.dart';

final selectedIndexProvider = StateProvider<int>((ref) => 0);

class MainScreen extends ConsumerWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(selectedIndexProvider);
    final cartItemCount = ref.watch(cartProvider).items.length;

    final screens = [
      const CakeCatalogScreen(),
      const OrdersScreen(),
      const ProfileScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: selectedIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: (int index) {
          ref.read(selectedIndexProvider.notifier).state = index;
        },
        selectedIndex: selectedIndex,
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 3,
        shadowColor: Theme.of(context).colorScheme.shadow,
        indicatorColor: Theme.of(context).colorScheme.primaryContainer,
        destinations: <NavigationDestination>[
          NavigationDestination(
            icon: Icon(Icons.cake_outlined, 
              color: selectedIndex == 0 ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurfaceVariant),
            label: 'Catalog',
          ),
          NavigationDestination(
            icon: Stack(
              children: [
                Icon(Icons.receipt_long_outlined,
                  color: selectedIndex == 1 ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurfaceVariant),
                if (cartItemCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(1),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 12,
                        minHeight: 12,
                      ),
                      child: Text(
                        cartItemCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            label: 'Orders',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline,
              color: selectedIndex == 2 ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurfaceVariant),
            label: 'Profile',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined,
              color: selectedIndex == 3 ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurfaceVariant),
            label: 'Settings',
          ),
        ],
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
    );
  }
} 