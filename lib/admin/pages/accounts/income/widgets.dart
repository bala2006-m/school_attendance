import 'package:flutter/material.dart';

import 'income.dart';

String monthName(int m) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return months[m - 1];
}

Widget buildFilterButtonsRow({
  required void Function(IncomeFilter filter) onFilterTap,
  required IncomeFilter? selectedFilter,
  required DateTime? from,
  required DateTime? to,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _filterChip('Day', IncomeFilter.day, selectedFilter, onFilterTap),
          const SizedBox(width: 10),

          _filterChip(
            _monthChipLabel(selectedFilter, from),
            IncomeFilter.month,
            selectedFilter,
            onFilterTap,
          ),
          const SizedBox(width: 10),

          _filterChip(
            _yearChipLabel(selectedFilter, from),
            IncomeFilter.year,
            selectedFilter,
            onFilterTap,
          ),
          const SizedBox(width: 10),

          _filterChip(
            _rangeChipLabel(selectedFilter, from, to),
            IncomeFilter.periodical,
            selectedFilter,
            onFilterTap,
          ),
        ],
      ),
    ),
  );
}

String _monthChipLabel(IncomeFilter? f, DateTime? from) {
  if (f == IncomeFilter.month && from != null) {
    return '${monthName(from.month)} ${from.year}';
  }
  return 'Month';
}

String _yearChipLabel(IncomeFilter? f, DateTime? from) {
  if (f == IncomeFilter.year && from != null) {
    return '${from.year}';
  }
  return 'Year';
}

String _rangeChipLabel(IncomeFilter? f, DateTime? from, DateTime? to) {
  if (f == IncomeFilter.periodical && from != null && to != null) {
    return '${from.day}/${from.month}/${from.year} → ${to.day}/${to.month}/${to.year}';
  }
  return 'Periodical';
}

Widget _filterChip(
  String label,
  IncomeFilter filter,
  IncomeFilter? selectedFilter,
  void Function(IncomeFilter filter) onFilterTap,
) {
  final selected = selectedFilter == filter;

  return GestureDetector(
    onTap: () => onFilterTap(filter),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFE34A4A) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            offset: const Offset(0, 2),
            blurRadius: 5,
          ),
        ],
      ),
      child: Text(
        label,
        style: TextStyle(
          color: selected ? Colors.white : Colors.black87,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}

Widget buildOverallIncomeCard({required Map<String, dynamic> allAccounts}) {
  return _buildIncomeCard('Overall Income', allAccounts);
}

Widget buildFilteredIncomeCard({
  required DateTime from,
  required DateTime to,
  required Map<String, dynamic> periodicalAccounts,
}) {
  return _buildIncomeCard(
    'Filtered Income (${IncomeState.fmtDate(from)} → ${IncomeState.fmtDate(to)})',
    periodicalAccounts,
  );
}

Widget _buildIncomeCard(String title, Map<String, dynamic> accounts) {
  final term = accounts['termFeesTotal'] ?? 0;
  final bus = accounts['busFeeTotal'] ?? 0;
  final rte = accounts['rteFeesTotal'] ?? 0;
  final financeList = accounts['finance'] ?? [];

  final financeTotal = financeList.fold(
    0,
    (sum, entry) => sum + (entry['amount'] ?? 0),
  );

  final grand = term + bus + rte + financeTotal;

  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 16),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          offset: const Offset(0, 3),
          blurRadius: 8,
        ),
      ],
    ),
    child: Column(
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),

        _amountRow('Term Fees', term),
        _amountRow('Bus Fees', bus),
        _amountRow('RTE Fees', rte),

        if (financeList.isNotEmpty) ..._buildFinanceList(financeList),

        const Divider(),
        _amountRow('Grand Total', grand, bold: true),
      ],
    ),
  );
}

List<Widget> _buildFinanceList(List<dynamic> financeList) {
  return financeList.map((entry) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: _amountRow(
        '${entry['reason'] ?? 'Unknown'}',
        '${entry['amount'] ?? 0}',
      ),
    );
  }).toList();
}

Widget _amountRow(String label, dynamic value, {bool bold = false}) {
  final style = TextStyle(
    fontSize: bold ? 15 : 13,
    fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
  );

  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        Expanded(child: Text(label, style: style)),
        Text((value ?? 0).toString(), style: style),
      ],
    ),
  );
}
