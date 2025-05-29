import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/search_filter_provider.dart';

class SearchFilterScreen extends ConsumerWidget {
  const SearchFilterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filterState = ref.watch(searchFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search & Filter'),
        actions: [
          TextButton(
            onPressed: () {
              ref.read(searchFilterProvider.notifier).resetFilters();
            },
            child: const Text('Reset'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            decoration: const InputDecoration(
              labelText: 'Search Cakes',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              ref.read(searchFilterProvider.notifier).setSearchQuery(value);
            },
          ),
          const SizedBox(height: 16),
          const Text(
            'Filters',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Show Available Only'),
            value: filterState.showAvailableOnly,
            onChanged: (value) {
              ref.read(searchFilterProvider.notifier).setShowAvailableOnly(value);
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Cake Type',
              border: OutlineInputBorder(),
            ),
            value: filterState.selectedType,
            items: const [
              DropdownMenuItem(value: null, child: Text('All Types')),
              DropdownMenuItem(value: 'Birthday', child: Text('Birthday')),
              DropdownMenuItem(value: 'Wedding', child: Text('Wedding')),
              DropdownMenuItem(value: 'Custom', child: Text('Custom')),
            ],
            onChanged: (value) {
              ref.read(searchFilterProvider.notifier).setSelectedType(value);
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Variant',
              border: OutlineInputBorder(),
            ),
            value: filterState.selectedVariant,
            items: const [
              DropdownMenuItem(value: null, child: Text('All Variants')),
              DropdownMenuItem(value: 'Chocolate', child: Text('Chocolate')),
              DropdownMenuItem(value: 'Vanilla', child: Text('Vanilla')),
              DropdownMenuItem(value: 'Red Velvet', child: Text('Red Velvet')),
            ],
            onChanged: (value) {
              ref.read(searchFilterProvider.notifier).setSelectedVariant(value);
            },
          ),
        ],
      ),
    );
  }
} 