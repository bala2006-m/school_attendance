import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'academic_year_api_service.dart';

class AcademicYearProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _academicYears = [];
  Map<String, dynamic>? _selectedAcademicYear;
  bool _isLoaded = false;
  String? _schoolId;

  List<Map<String, dynamic>> get academicYears => _academicYears;
  Map<String, dynamic>? get selectedAcademicYear => _selectedAcademicYear;
  bool get isLoaded => _isLoaded;

  /// Get the start date of the selected academic year
  DateTime? get startDate {
    if (_selectedAcademicYear == null) return null;
    try {
      return DateTime.parse(_selectedAcademicYear!['start_date'].toString());
    } catch (_) {
      return null;
    }
  }

  /// Get the end date of the selected academic year
  DateTime? get endDate {
    if (_selectedAcademicYear == null) return null;
    try {
      return DateTime.parse(_selectedAcademicYear!['end_date'].toString());
    } catch (_) {
      return null;
    }
  }

  /// Get formatted start date string (yyyy-MM-dd)
  String? get startDateStr {
    final d = startDate;
    return d != null ? DateFormat('yyyy-MM-dd').format(d) : null;
  }

  /// Get formatted end date string (yyyy-MM-dd)
  String? get endDateStr {
    final d = endDate;
    return d != null ? DateFormat('yyyy-MM-dd').format(d) : null;
  }

  /// Get a display label like "2025-2026"
  String get displayLabel {
    if (_selectedAcademicYear == null) return 'Select Year';
    final start = startDate;
    final end = endDate;
    if (start != null && end != null) {
      return '${start.year}-${end.year}';
    }
    return 'Select Year';
  }

  /// Check if a given date falls within the selected academic year
  bool isDateInSelectedYear(DateTime date) {
    final s = startDate;
    final e = endDate;
    if (s == null || e == null) return true; // No filter if no year selected
    return !date.isBefore(s) && !date.isAfter(e);
  }

  /// Check if current academic year is selected (or if it's the is_current one)
  bool get isCurrentYearSelected {
    if (_selectedAcademicYear == null) return true;
    return _selectedAcademicYear!['is_current'] == true ||
        _selectedAcademicYear!['is_current'] == 1;
  }

  /// Fetch all academic years for a school and auto-select the current one
  Future<void> fetchAcademicYears(String schoolId) async {
    // Avoid re-fetching if already loaded for the same school
    if (_isLoaded && _schoolId == schoolId && _academicYears.isNotEmpty) return;

    _schoolId = schoolId;

    try {
      final years = await AcademicYearApiService.fetchAllAcademicYears(schoolId);

      if (years.isNotEmpty) {
        // Sort by start_date descending (newest first)
        years.sort((a, b) {
          try {
            final dateA = DateTime.parse(a['start_date'].toString());
            final dateB = DateTime.parse(b['start_date'].toString());
            return dateB.compareTo(dateA);
          } catch (_) {
            return 0;
          }
        });

        _academicYears = years;

        // Auto-select the current academic year
        final currentYear = years.firstWhere(
          (y) => y['is_current'] == true || y['is_current'] == 1,
          orElse: () => years.first,
        );
        _selectedAcademicYear = currentYear;
        await _persistSelectedYear();
      }

      _isLoaded = true;
      notifyListeners();
    } catch (e) {
      _isLoaded = true;
      notifyListeners();
    }
  }

  /// Set the selected academic year
  Future<void> setSelectedYear(Map<String, dynamic> year) async {
    _selectedAcademicYear = year;
    await _persistSelectedYear();
    notifyListeners();
  }

  Future<void> _persistSelectedYear() async {
    if (_selectedAcademicYear != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('x_academic_start', startDateStr ?? '');
      await prefs.setString('x_academic_end', endDateStr ?? '');
      await prefs.setString('x_academic_id', _selectedAcademicYear!['id'].toString());
    }
  }

  /// Reset the provider (e.g., on logout)
  Future<void> reset() async {
    _academicYears = [];
    _selectedAcademicYear = null;
    _isLoaded = false;
    _schoolId = null;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('x_academic_start');
    await prefs.remove('x_academic_end');
    await prefs.remove('x_academic_id');
    
    notifyListeners();
  }
}
