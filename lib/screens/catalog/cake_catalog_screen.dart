import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:decimal/decimal.dart';
import '../../providers/cake_provider.dart';
import '../../providers/cart_provider.dart';
import 'cake_detail_screen.dart';
import '../cart/cart_screen.dart';
import '../../models/models.dart';
import '../../providers/search_filter_provider.dart';
import 'search_filter_screen.dart';
import 'package:intl/intl.dart';

class CakeCatalogScreen extends ConsumerWidget {
  const CakeCatalogScreen({super.key});

  String formatPrice(Decimal price) {
    final formatter = NumberFormat('#,###', 'id_ID');
    return formatter.format(price.toDouble());
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cakesAsync = ref.watch(cakesProvider);
    final filterState = ref.watch(searchFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cake Catalog'),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CartScreen(),
                    ),
                  );
                },
              ),
              Consumer(
                builder: (context, ref, _) {
                  final cartItemCount = ref.watch(cartProvider).items.length;
                  if (cartItemCount == 0) return const SizedBox.shrink();
                  
                  return Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 20,
                        minHeight: 20,
                      ),
                      child: Text(
                        cartItemCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SearchFilterScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: cakesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error: ${error.toString()}'),
        ),
        data: (cakes) {
          var availableCakes = cakes.where((cake) => cake.isAvailable ?? false).toList();
          
          var filteredCakes = availableCakes.where((cake) {
            if (filterState.selectedType != null &&
                cake.cakeTypes != filterState.selectedType) {
              return false;
            }
            if (filterState.selectedVariant != null &&
                cake.variant != filterState.selectedVariant) {
              return false;
            }
            if (filterState.searchQuery.isNotEmpty &&
                !cake.name
                    .toLowerCase()
                    .contains(filterState.searchQuery.toLowerCase())) {
              return false;
            }
            return true;
          }).toList();

          return filteredCakes.isEmpty
              ? const Center(child: Text('No cakes found'))
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.7,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: filteredCakes.length,
                  itemBuilder: (context, index) {
                    final cake = filteredCakes[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CakeDetailScreen(cake: cake),
                          ),
                        );
                      },
                      child: Card(
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: Image.network(
                                cake.images ?? '',
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                  color: Colors.grey[200],
                                  child: const Icon(Icons.cake),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      cake.name,
                                      style: Theme.of(context).textTheme.titleMedium,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      cake.variant,
                                      style: Theme.of(context).textTheme.bodySmall,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Rp ${formatPrice(cake.price)}',
                                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                            color: Theme.of(context).primaryColor,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
        },
      ),
    );
  }
} 