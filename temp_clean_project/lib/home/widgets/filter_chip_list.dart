
import 'package:flutter/material.dart';
import 'package:profile_managemenr/constants/app_colors.dart';

class FilterChipList extends StatelessWidget {
  final List filters;
  final String activeFilter;
  final Function(String) onFilterChanged;

  const FilterChipList({
    Key? key,
    required this.filters,
    required this.activeFilter,
    required this.onFilterChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 55,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final label = filter == 'all' ? 'All' : filter;
          final isActive = activeFilter == filter;

          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isActive
                    ? AppColors.accentColor
                    : AppColors.lightCardBackground,
                foregroundColor:
                    isActive ? Colors.white : AppColors.lightTextColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
              ),
              onPressed: () => onFilterChanged(filter),
              child: Text(label),
            ),
          );
        },
      ),
    );
  }
}