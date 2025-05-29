import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';

class SearchFilterState {
  final String searchQuery;
  final String? selectedType;
  final String? selectedVariant;
  final bool showAvailableOnly;
  final PriceRange? priceRange;

  SearchFilterState({
    this.searchQuery = '',
    this.selectedType,
    this.selectedVariant,
    this.showAvailableOnly = false,
    this.priceRange,
  });

  SearchFilterState copyWith({
    String? searchQuery,
    String? selectedType,
    String? selectedVariant,
    bool? showAvailableOnly,
    PriceRange? priceRange,
  }) {
    return SearchFilterState(
      searchQuery: searchQuery ?? this.searchQuery,
      selectedType: selectedType ?? this.selectedType,
      selectedVariant: selectedVariant ?? this.selectedVariant,
      showAvailableOnly: showAvailableOnly ?? this.showAvailableOnly,
      priceRange: priceRange ?? this.priceRange,
    );
  }
}

class PriceRange {
  final int min;
  final int max;

  const PriceRange({required this.min, required this.max});
}

final searchFilterProvider = StateNotifierProvider<SearchFilterNotifier, SearchFilterState>((ref) {
  return SearchFilterNotifier();
});

class SearchFilterNotifier extends StateNotifier<SearchFilterState> {
  SearchFilterNotifier() : super(SearchFilterState());

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setSelectedType(String? type) {
    state = state.copyWith(selectedType: type);
  }

  void setSelectedVariant(String? variant) {
    state = state.copyWith(selectedVariant: variant);
  }

  void setShowAvailableOnly(bool show) {
    state = state.copyWith(showAvailableOnly: show);
  }

  void setPriceRange(PriceRange range) {
    state = state.copyWith(priceRange: range);
  }

  void resetFilters() {
    state = SearchFilterState();
  }
} 