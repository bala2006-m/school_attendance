import 'package:flutter/material.dart';
import 'package:school_attendance/teacher/services/teacher_api_service.dart';

import '../../../student/services/student_api_services.dart';
import '../../appbar/admin_appbar_desktop.dart';
import '../../appbar/admin_appbar_mobile.dart';
import '../../services/admin_api_service.dart';
import '../dashboard/admin_dashboard.dart';

class TeacherAccess extends StatefulWidget {
  const TeacherAccess({
    super.key,
    required this.schoolId,
    required this.username,
  });
  final String schoolId;
  final String username;
  @override
  State<TeacherAccess> createState() => _TeacherAccessState();
}

class _TeacherAccessState extends State<TeacherAccess>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> staff = [];
  List<Map<String, dynamic>> filteredStaff = [];
  String? selectedUsername;
  final TextEditingController _searchController = TextEditingController();
  String? expandedUsername;
  Map<String, List<Map<String, dynamic>>> staffClassesMap = {};
  bool isLoadingClasses = false;
  List<Map<String, dynamic>> allClasses = [];
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Premium color palette
  static const Color _primaryBlue = Color(0xFF2563EB);
  static const Color _primaryPink = Color(0xFFEC4899);
  static const Color _maleGradientStart = Color(0xFF3B82F6);
  static const Color _maleGradientEnd = Color(0xFF1D4ED8);
  static const Color _femaleGradientStart = Color(0xFFF472B6);
  static const Color _femaleGradientEnd = Color(0xFFDB2777);
  static const Color _cardShadow = Color(0x1A000000);
  static const Color _surfaceColor = Color(0xFFF8FAFC);
  static const Color _borderColor = Color(0xFFE2E8F0);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _initStaff();
    fetchAllClasses();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initStaff() async {
    staff = await AdminApiService.fetchStaffData(widget.schoolId);

    staff.sort((a, b) {
      final genderA = a['gender'] ?? '';
      final genderB = b['gender'] ?? '';

      if (genderA == 'M' && genderB != 'M') return -1;
      if (genderA != 'M' && genderB == 'M') return 1;

      // If same gender, sort by username case-insensitive
      final userA = (a['username'] ?? '').toString().toLowerCase();
      final userB = (b['username'] ?? '').toString().toLowerCase();
      return userA.compareTo(userB);
    });

    setState(() {
      filteredStaff = staff;
    });
  }

  Future<Map<String, dynamic>?> fetchClass(String classId) {
    return StudentApiServices.fetchClassDatas(widget.schoolId, classId);
  }

  void _filterStaff(String query) {
    setState(() {
      filteredStaff =
          query.isEmpty
              ? staff
              : staff.where((member) {
                final name = (member['name'] ?? '').toString().toLowerCase();
                final mobile =
                    (member['mobile'] ?? '').toString().toLowerCase();
                final search = query.toLowerCase();
                return name.contains(search) || mobile.contains(search);
              }).toList();
    });
  }

  Future<bool> _onWillPop() async {
    AdminDashboardState.selectedIndex = 2;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => AdminDashboard(
              schoolId: widget.schoolId,
              username: widget.username,
            ),
      ),
    );
    return false;
  }

  List<Map<String, dynamic>> groupAndSortStaffByGender(
    List<Map<String, dynamic>> staff,
  ) {
    List<Map<String, dynamic>> males =
        staff
            .where((data) => (data['gender'] ?? '').toUpperCase() == 'M')
            .toList();
    List<Map<String, dynamic>> females =
        staff
            .where((data) => (data['gender'] ?? '').toUpperCase() == 'F')
            .toList();

    int nameComparator(a, b) => (a['name'] ?? '')
        .toString()
        .toLowerCase()
        .compareTo((b['name'] ?? '').toString().toLowerCase());

    males.sort(nameComparator);
    females.sort(nameComparator);

    return [...males, ...females];
  }

  Future<void> _showStaffClasses(Map<String, dynamic> staffMember) async {
    final username = staffMember['username'];

    // Toggle if already expanded
    if (expandedUsername == username) {
      setState(() {
        expandedUsername = null;
      });
      return;
    }

    setState(() {
      expandedUsername = username;
      isLoadingClasses = true;
    });

    final List<dynamic> classIds = staffMember['class_ids'] ?? [];

    List<Map<String, dynamic>> classDataList = [];

    for (var classId in classIds) {
      final classData = await fetchClass(classId.toString());
      if (classData != null) {
        classDataList.add(classData);
      }
    }

    if (!mounted) return;

    setState(() {
      staffClassesMap[username] = classDataList;
      isLoadingClasses = false;
    });
  }

  Future<void> updateClass(String username, List<int> classIds) async {
    final success = await AdminApiService.updateStaffClassIds(
      username: username,
      schoolId: widget.schoolId,
      classIds: classIds,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              const Text(
                "Updated successfully",
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              const Text(
                "Update failed",
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  Future<void> fetchAllClasses() async {
    allClasses = await TeacherApiServices.fetchClassData(widget.schoolId);
  }

  Future<void> _showAvailableClasses(Map<String, dynamic> member) async {
    final username = member['username'];

    List<int> currentClassIds = List<int>.from(member['class_ids'] ?? []);

    // Filter classes not already assigned
    List<Map<String, dynamic>> availableClasses =
        allClasses.where((classItem) {
          return !currentClassIds.contains(classItem['id']);
        }).toList();

    if (availableClasses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.white),
              const SizedBox(width: 12),
              const Text(
                "All classes already assigned",
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF6366F1),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    final selectedClass = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.6,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [_primaryBlue, Color(0xFF1D4ED8)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.class_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Available Classes",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        Text(
                          "${availableClasses.length} classes available",
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Divider(color: Colors.grey.shade200, height: 1),
              Flexible(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shrinkWrap: true,
                  itemCount: availableClasses.length,
                  itemBuilder: (_, index) {
                    final classItem = availableClasses[index];
                    final className = classItem['class'];
                    final section = classItem['section'];

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => Navigator.pop(context, classItem),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(color: _borderColor),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: _primaryBlue.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.school_rounded,
                                    color: _primaryBlue,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "$className - $section",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15,
                                          color: Color(0xFF1E293B),
                                        ),
                                      ),
                                      Text(
                                        "Tap to assign",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.add_circle_outline_rounded,
                                  color: _primaryBlue,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );

    if (selectedClass == null) return;

    // Add selected class
    currentClassIds.add(selectedClass['id']);

    await updateClass(username, currentClassIds);

    // Update UI immediately
    setState(() {
      member['class_ids'] = currentClassIds;
      staffClassesMap[username] ??= [];
      staffClassesMap[username]!.add(selectedClass);
    });
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _cardShadow,
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(fontSize: 15, color: Color(0xFF1E293B)),
        decoration: InputDecoration(
          hintText: "Search teachers by name or mobile...",
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          prefixIcon: Icon(Icons.search_rounded, color: Colors.grey.shade400),
          suffixIcon:
              _searchController.text.isNotEmpty
                  ? IconButton(
                    icon: Icon(
                      Icons.clear_rounded,
                      color: Colors.grey.shade400,
                    ),
                    onPressed: () {
                      _searchController.clear();
                      _filterStaff('');
                    },
                  )
                  : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
        onChanged: _filterStaff,
      ),
    );
  }

  Widget _buildStatsHeader(int maleCount, int femaleCount) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _primaryBlue.withValues(alpha: 0.08),
            _primaryPink.withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              icon: Icons.male_rounded,
              label: "Male Teachers",
              count: maleCount,
              gradient: const LinearGradient(
                colors: [_maleGradientStart, _maleGradientEnd],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              icon: Icons.female_rounded,
              label: "Female Teachers",
              count: femaleCount,
              gradient: const LinearGradient(
                colors: [_femaleGradientStart, _femaleGradientEnd],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required int count,
    required Gradient gradient,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _cardShadow,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  count.toString(),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeacherCard(Map<String, dynamic> member, int index) {
    final name = member['name'] ?? 'Unknown';
    final username = member['username'] ?? 'Unknown';
    final gender = (member['gender'] ?? '').toString();
    final designation = member['designation'] ?? 'Designation';
    final classCount = (member['class_ids'] as List?)?.length ?? 0;
    final isExpanded = expandedUsername == username;

    final isMale = gender == 'M';
    final gradientColors =
        isMale
            ? [_maleGradientStart, _maleGradientEnd]
            : [_femaleGradientStart, _femaleGradientEnd];
    final lightBg = isMale ? const Color(0xFFEFF6FF) : const Color(0xFFFDF2F8);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          // Main Card
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isExpanded ? gradientColors[0] : _borderColor,
                width: isExpanded ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color:
                      isExpanded
                          ? gradientColors[0].withValues(alpha: 0.15)
                          : _cardShadow,
                  blurRadius: isExpanded ? 20 : 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => _showStaffClasses(member),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Avatar with gradient border
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: gradientColors),
                          shape: BoxShape.circle,
                        ),
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: lightBg,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isMale ? Icons.male_rounded : Icons.female_rounded,
                            color: gradientColors[0],
                            size: 28,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.person_outline_rounded,
                                  size: 14,
                                  color: Colors.grey.shade500,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  username,
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(
                                  Icons.work_outline_rounded,
                                  size: 14,
                                  color: Colors.grey.shade500,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    designation,
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 13,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Class count badge
                      Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: gradientColors),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.class_rounded,
                                  color: Colors.white,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  "$classCount",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          AnimatedRotation(
                            turns: isExpanded ? 0.5 : 0,
                            duration: const Duration(milliseconds: 300),
                            child: Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: Colors.grey.shade400,
                              size: 24,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Expanded Classes Section
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: _buildClassesPanel(member, username, gradientColors),
            crossFadeState:
                isExpanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),
        ],
      ),
    );
  }

  Widget _buildClassesPanel(
    Map<String, dynamic> member,
    String username,
    List<Color> gradientColors,
  ) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor),
      ),
      child:
          isLoadingClasses
              ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
              : (staffClassesMap[username]?.isEmpty ?? true)
              ? _buildEmptyClassesState(member, gradientColors)
              : _buildClassesList(member, username, gradientColors),
    );
  }

  Widget _buildEmptyClassesState(
    Map<String, dynamic> member,
    List<Color> gradientColors,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: gradientColors[0].withValues(alpha: 0.2),
                blurRadius: 20,
              ),
            ],
          ),
          child: Icon(
            Icons.class_outlined,
            size: 40,
            color: Colors.grey.shade400,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          "No Classes Assigned",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "Tap the button below to assign classes",
          style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
        ),
        const SizedBox(height: 20),
        _buildAddClassButton(member, gradientColors),
      ],
    );
  }

  Widget _buildClassesList(
    Map<String, dynamic> member,
    String username,
    List<Color> gradientColors,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.class_rounded, size: 18, color: gradientColors[0]),
            const SizedBox(width: 8),
            Text(
              "Assigned Classes",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: gradientColors[0],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...staffClassesMap[username]!.map((classItem) {
          final className = classItem['class'] ?? 'Unknown';
          final section = classItem['section'] ?? '';
          final id = classItem['id'] ?? '';

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _borderColor),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: gradientColors),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.school_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "$className - $section",
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      Text(
                        "ID: $id",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
                Material(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () async {
                      final confirm = await showDialog(
                        context: context,
                        builder:
                            (_) => AlertDialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              title: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFEE2E2),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.warning_rounded,
                                      color: Color(0xFFEF4444),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    "Remove Class",
                                    style: TextStyle(fontSize: 18),
                                  ),
                                ],
                              ),
                              content: Text(
                                "Are you sure you want to remove $className $section from this teacher?",
                                style: TextStyle(color: Colors.grey.shade700),
                              ),
                              actions: [
                                TextButton(
                                  onPressed:
                                      () => Navigator.pop(context, false),
                                  child: Text(
                                    "Cancel",
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFEF4444),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: const Text("Remove"),
                                ),
                              ],
                            ),
                      );

                      if (confirm != true) return;

                      final classIdToRemove = classItem['id'];
                      List<int> currentClassIds = List<int>.from(
                        member['class_ids'] ?? [],
                      );

                      currentClassIds.remove(classIdToRemove);

                      await updateClass(username, currentClassIds);

                      setState(() {
                        member['class_ids'] = currentClassIds;
                        staffClassesMap[username]!.removeWhere(
                          (c) => c['id'] == classIdToRemove,
                        );
                      });
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(
                        Icons.delete_outline_rounded,
                        color: Color(0xFFEF4444),
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 12),
        _buildAddClassButton(member, gradientColors),
      ],
    );
  }

  Widget _buildAddClassButton(
    Map<String, dynamic> member,
    List<Color> gradientColors,
  ) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showAvailableClasses(member),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: gradientColors),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: gradientColors[0].withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_rounded, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  "Add Class",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final displayedStaff =
        filteredStaff.where((s) => s['faculty'] == 'teaching').toList();
    final groupedStaff = groupAndSortStaffByGender(displayedStaff);

    final maleCount =
        groupedStaff
            .where((s) => (s['gender'] ?? '').toUpperCase() == 'M')
            .length;
    final femaleCount =
        groupedStaff
            .where((s) => (s['gender'] ?? '').toUpperCase() == 'F')
            .length;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, res) {
        if (!didPop) {
          _onWillPop();
        }
      },
      child: Scaffold(
        backgroundColor: _surfaceColor,
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(isMobile ? 190 : 150),
          child:
              isMobile
                  ? AdminAppbarMobile(
                    schoolId: widget.schoolId,
                    username: widget.username,
                    title: 'Teachers Access',
                    enableDrawer: false,
                    enableBack: true,
                    onBack: () {
                      AdminDashboardState.selectedIndex = 2;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => AdminDashboard(
                                schoolId: widget.schoolId,
                                username: widget.username,
                              ),
                        ),
                      );
                    },
                  )
                  : AdminAppbarDesktop(
                    schoolId: widget.schoolId,
                    username: widget.username,
                    title: 'Teachers Access',
                    onBack: () {
                      AdminDashboardState.selectedIndex = 2;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => AdminDashboard(
                                schoolId: widget.schoolId,
                                username: widget.username,
                              ),
                        ),
                      );
                    },
                  ),
        ),
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 16 : 24,
              vertical: 20,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildSearchBar(),
                    const SizedBox(height: 20),
                    _buildStatsHeader(maleCount, femaleCount),
                    const SizedBox(height: 24),

                    // Section Header
                    if (groupedStaff.isNotEmpty) ...[
                      Row(
                        children: [
                          Container(
                            width: 4,
                            height: 24,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [_primaryBlue, _primaryPink],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            "Teaching Staff",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _primaryBlue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              "${groupedStaff.length}",
                              style: const TextStyle(
                                color: _primaryBlue,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Staff List
                    if (groupedStaff.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(40),
                          child: Column(
                            children: [
                              Icon(
                                Icons.person_search_rounded,
                                size: 64,
                                color: Colors.grey.shade300,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "No teachers found",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: groupedStaff.length,
                        itemBuilder: (context, index) {
                          return _buildTeacherCard(groupedStaff[index], index);
                        },
                      ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
