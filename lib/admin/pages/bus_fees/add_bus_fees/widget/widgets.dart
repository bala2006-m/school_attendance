import 'package:flutter/material.dart';

Widget existingFeeContainer({
  required List<dynamic> busFees,
  required bool isMobile,
  required Function(Map<String, dynamic> item) editStructure,
  required Function(int id) deleteStructure,
  required Function(int id, bool newStatus) toggleStatus,
}) {
  // Group by term
  final Map<String, List<Map<String, dynamic>>> groupedByTerm = {};
  for (var fee in busFees) {
    final term = fee['term'] ?? 'Unknown Term';
    groupedByTerm
        .putIfAbsent(term, () => [])
        .add(Map<String, dynamic>.from(fee));
  }

  final termList = groupedByTerm.keys.toList();

  return DefaultTabController(
    length: termList.length,
    child: _TermTabs(
      groupedByTerm: groupedByTerm,
      termList: termList,
      isMobile: isMobile,
      editStructure: editStructure,
      deleteStructure: deleteStructure,
      toggleStatus: toggleStatus,
    ),
  );
}

class _TermTabs extends StatefulWidget {
  final Map<String, List<Map<String, dynamic>>> groupedByTerm;
  final List<String> termList;
  final bool isMobile;
  final Function(Map<String, dynamic>) editStructure;
  final Function(int id) deleteStructure;
  final Function(int id, bool newStatus) toggleStatus;

  const _TermTabs({
    required this.groupedByTerm,
    required this.termList,
    required this.isMobile,
    required this.editStructure,
    required this.deleteStructure,
    required this.toggleStatus,
  });

  @override
  State<_TermTabs> createState() => _TermTabsState();
}

class _TermTabsState extends State<_TermTabs> {
  final Map<String, TextEditingController> searchControllers = {};

  @override
  void initState() {
    super.initState();
    for (var t in widget.termList) {
      searchControllers[t] = TextEditingController();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.isMobile ? double.infinity : 900,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            "Bus Fee Structures",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Color(0xFF3B5FBC),
            ),
          ),
          const SizedBox(height: 18),

          // ---------- TAB BAR ----------
          TabBar(
            isScrollable: true,
            labelColor: Colors.white,
            unselectedLabelColor: Color(0xFF3B5FBC),
            indicator: BoxDecoration(
              color: Color(0xFF3B5FBC),
              borderRadius: BorderRadius.circular(10),
            ),
            tabs:
                widget.termList
                    .map(
                      (t) => Tab(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            t,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    )
                    .toList(),
          ),

          const SizedBox(height: 16),

          // ---------- TAB CONTENT ----------
          Expanded(
            child: TabBarView(
              children:
                  widget.termList.map((term) {
                    final fees = widget.groupedByTerm[term]!;

                    // Count active items
                    final activeCount =
                        fees.where((e) => e['status'] == "active").length;
                    final bool allActive = activeCount == fees.length;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ---------- TAB-WIDE TOGGLE ----------
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "$term Fees",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF3B5FBC),
                              ),
                            ),
                            Row(
                              children: [
                                Text(
                                  allActive ? "Active" : "Inactive",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color:
                                        allActive ? Colors.green : Colors.grey,
                                  ),
                                ),
                                Switch(
                                  value: allActive,
                                  activeColor: Colors.green,
                                  onChanged: (value) {
                                    for (var f in fees) {
                                      widget.toggleStatus(f['id'], value);
                                    }
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // ---------- SEARCH BAR ----------
                        TextField(
                          controller: searchControllers[term],
                          onChanged: (v) => setState(() {}),
                          decoration: InputDecoration(
                            hintText: "Search by Route...",
                            prefixIcon: const Icon(Icons.search),
                            filled: true,
                            fillColor: Colors.grey[100],
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Filter by search input
                        Expanded(
                          child: _buildFeeList(
                            term: term,
                            fees:
                                fees.where((f) {
                                  final query =
                                      searchControllers[term]!.text
                                          .toLowerCase();
                                  if (query.isEmpty) return true;
                                  final route = f['route']?.toLowerCase() ?? "";
                                  return route.contains(query);
                                }).toList(),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeeList({
    required String term,
    required List<Map<String, dynamic>> fees,
  }) {
    if (fees.isEmpty) {
      return Center(
        child: Text(
          "No Routes Found",
          style: TextStyle(color: Colors.grey[700]),
        ),
      );
    }

    return ListView.separated(
      itemCount: fees.length,
      separatorBuilder: (_, __) => Divider(color: Colors.grey[300]),
      itemBuilder: (context, index) {
        final fee = fees[index];
        final bool isActive = fee['status'] == "active";

        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ICON
                Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B5FBC),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.directions_bus_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),

                // DETAILS
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fee['route'] ?? 'Unknown Route',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF24262A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.payments_rounded,
                            size: 16,
                            color: Colors.indigo,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "Total ₹${fee['total_amount']}",
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ACTION BUTTONS
                Column(
                  children: [
                    Transform.scale(
                      scale: 0.8,
                      child: Switch(
                        value: isActive,
                        activeColor: Colors.green,
                        onChanged:
                            (value) => widget.toggleStatus(fee['id'], value),
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.edit_rounded,
                            color: Colors.blue[600],
                          ),
                          onPressed: () => widget.editStructure(fee),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.delete_outline_rounded,
                            color: Colors.red[700],
                          ),
                          onPressed: () => widget.deleteStructure(fee['id']),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Widget _infoRow({
//   required IconData icon,
//   required String text,
//   required Color color,
// }) {
//   return Row(
//     mainAxisSize: MainAxisSize.min,
//     crossAxisAlignment: CrossAxisAlignment.start,
//     children: [
//       Icon(icon, color: color, size: 16),
//       const SizedBox(width: 4),
//       Text(text, style: TextStyle(fontSize: 13, color: color)),
//     ],
//   );
// }
