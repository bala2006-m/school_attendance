import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../services/academic_year_provider.dart';

class AcademicYearDropdown extends StatelessWidget {
  final String schoolId;

  const AcademicYearDropdown({super.key, required this.schoolId});

  String _formatYearLabel(Map<String, dynamic> year) {
    try {
      final start = DateTime.parse(year['start_date'].toString());
      final end = DateTime.parse(year['end_date'].toString());
      return '${DateFormat('MMM yyyy').format(start)} - ${DateFormat('MMM yyyy').format(end)}';
    } catch (_) {
      return 'Unknown';
    }
  }

  String _shortLabel(Map<String, dynamic> year) {
    try {
      final start = DateTime.parse(year['start_date'].toString());
      final end = DateTime.parse(year['end_date'].toString());
      return '${start.year}-${end.year}';
    } catch (_) {
      return '----';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AcademicYearProvider>(
      builder: (context, provider, _) {
        if (!provider.isLoaded) {
          // Trigger fetch if not yet loaded
          WidgetsBinding.instance.addPostFrameCallback((_) {
            provider.fetchAcademicYears(schoolId);
          });
          return const SizedBox(
            width: 90,
            height: 32,
            child: Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            ),
          );
        }

        if (provider.academicYears.isEmpty) {
          return const SizedBox.shrink();
        }

        final selected = provider.selectedAcademicYear;

        return GestureDetector(
          onTap: () => _showYearPicker(context, provider),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 14,
                  color: const Color(0xFF2B7CA8),
                ),
                const SizedBox(width: 6),
                Text(
                  selected != null ? _shortLabel(selected) : 'Year',
                  style: const TextStyle(
                    color: Color(0xFF2B7CA8),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_drop_down,
                  size: 18,
                  color: const Color(0xFF2B7CA8),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showYearPicker(BuildContext context, AcademicYearProvider provider) {
    final selected = provider.selectedAcademicYear;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                'Select Academic Year',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2B7CA8),
                ),
              ),
              const SizedBox(height: 12),
              ...provider.academicYears.map((year) {
                final isSelected = selected != null &&
                    selected['id'] == year['id'];
                final isCurrent =
                    year['is_current'] == true || year['is_current'] == 1;
                return ListTile(
                  leading: Icon(
                    isSelected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: isSelected
                        ? const Color(0xFF2B7CA8)
                        : Colors.grey,
                  ),
                  title: Text(
                    _formatYearLabel(year),
                    style: TextStyle(
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected
                          ? const Color(0xFF2B7CA8)
                          : Colors.black87,
                    ),
                  ),
                  trailing: isCurrent
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Current',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.green,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                      : null,
                  onTap: () {
                    provider.setSelectedYear(year);
                    Navigator.pop(ctx);
                  },
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}
