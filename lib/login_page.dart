import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:school_attendance/admin/pages/dashboard/admin_dashboard.dart';
import 'package:school_attendance/administrator/pages/dashboard.dart';
import 'package:school_attendance/administrator/services/administrator_api_service.dart';
import 'package:school_attendance/services/api_service.dart';
import 'package:school_attendance/student/pages/student_dashboard.dart';
import 'package:school_attendance/teacher/pages/staff_dashboard.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'demo_page.dart';
import 'forgot_password_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _schoolIdController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();

  bool _obscurePassword = true;
  bool isLoading = false;
  bool rememberMe = false;
  bool isBlocked = false;
  String? reason;
  bool _isFormValid = false;

  /// Validate if form is complete and school is not blocked
  void _validateForm() {
    final schoolIdText = _schoolIdController.text.trim();
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    final isFilled =
        schoolIdText.isNotEmpty && username.isNotEmpty && password.isNotEmpty;

    setState(() {
      _isFormValid = isFilled && !isBlocked;
    });
  }

  Future<void> _checkBlocked(int schoolId) async {
    try {
      final result = await AdministratorApiService.isSchoolBlocked(schoolId);

      setState(() {
        isBlocked = result['isBlocked'] ?? false;
        reason = result['reason'];
      });

      if (isBlocked && mounted) {
        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('School Blocked'),
                content: Text(reason ?? "This school is blocked."),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('OK'),
                  ),
                ],
              ),
        );
      }
    } catch (e) {
      setState(() {
        isBlocked = false;
      });
    } finally {
      _validateForm(); // recheck validity after block check
    }
  }

  Future<void> login() async {
    setState(() => isLoading = true);
    SharedPreferences prefs = await SharedPreferences.getInstance();

    final enteredUsername = _usernameController.text.trim();
    final enteredPassword = _passwordController.text.trim();
    final schoolIdText = _schoolIdController.text.trim();

    // Validate inputs
    if (schoolIdText.isEmpty ||
        enteredUsername.isEmpty ||
        enteredPassword.isEmpty) {
      showError("Please fill in all fields");
      setState(() => isLoading = false);
      return;
    }

    final schoolId = int.tryParse(schoolIdText);
    if (schoolId == null) {
      showError("School ID must be a number");
      setState(() => isLoading = false);
      return;
    }

    try {
      final loginResult = await ApiService.login(
        username: enteredUsername,
        password: enteredPassword,
        schoolId: schoolId,
      );

      if (loginResult['status'] != 'success') {
        showError(loginResult['message'] ?? "Invalid user Id or password");
        setState(() => isLoading = false);
        return;
      }

      final user = loginResult['user'];
      final foundRole = user['role'];

      // Save login info
      await prefs.setString('role', foundRole);
      await prefs.setBool('rememberMe', rememberMe);
      await prefs.setString('username', user['username']);
      await prefs.setString('schoolId', '$schoolId');

      // Trigger sync after successful login (only for admin and staff)
      if (foundRole == 'admin' || foundRole == 'staff') {
        try {
          await ApiService.triggerInitialSync(
            schoolId: schoolId,
            userId: user['username'].toString(),
          );
        } catch (e) {
          // Log error but don't block login
          debugPrint('Sync trigger failed: $e');
        }
      }

      // Navigate by role
      switch (foundRole) {
        case 'student':
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder:
                    (_) => StudentDashboard(
                      username: user?['username'],
                      schoolId: schoolId,
                    ),
              ),
            );
          }
          break;
        case 'staff':
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (_) => StaffDashboard(
                      username: user!['username'].toString(),
                      schoolId: '$schoolId',
                    ),
              ),
            );
          }
          break;
        case 'admin':
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (_) => AdminDashboard(
                      username: user?['username'],
                      schoolId: '${user?['school_id']}',
                    ),
              ),
            );
          }
          break;
        case 'administrator':
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (_) => AdministratorDashboard(userName: user?['username']),
              ),
            );
          }
          break;
      }
    } catch (e) {
      showError("Login failed. Please try again. $e");
      print("Login failed. Please try again. $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  void showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  // Future<void> _processFaceLogin(int schoolId, XFile capturedImage) async {
  //   setState(() => isLoading = true);
  //
  //   try {
  //     // Detect face in captured image
  //     final faceDetector = GoogleMlKit.vision.faceDetector();
  //     final inputImage = InputImage.fromFilePath(capturedImage.path);
  //     final faces = await faceDetector.processImage(inputImage);
  //
  //     if (faces.isEmpty) {
  //       showError('No face detected. Please try again.');
  //       setState(() => isLoading = false);
  //       return;
  //     }
  //
  //     print('Captured faces: ${faces.length}');
  //     final capturedFace = faces[0];
  //     print(
  //       'Captured left eye: ${capturedFace.landmarks[FaceLandmarkType.leftEye]?.position}',
  //     );
  //     print(
  //       'Captured right eye: ${capturedFace.landmarks[FaceLandmarkType.rightEye]?.position}',
  //     );
  //     print(
  //       'Captured nose: ${capturedFace.landmarks[FaceLandmarkType.noseBase]?.position}',
  //     );
  //
  //     // Fetch admin data for the school
  //     final adminData = await AdminApiService.fetchAllAdminPic(
  //       schoolId: schoolId.toString(),
  //     );
  //     print(adminData);
  //
  //     if (adminData.isEmpty) {
  //       showError('No admin data found for the school');
  //       setState(() => isLoading = false);
  //       return;
  //     }
  //
  //     // For simplicity, take the first admin
  //     final admin = adminData[0];
  //     if (admin['photo'] == null || admin['photo'].isEmpty) {
  //       showError('No admin photo found for face matching');
  //       setState(() => isLoading = false);
  //       return;
  //     }
  //
  //     // Detect face in stored photo
  //     final storedBytes = List<int>.from(admin['photo'].values);
  //     final tempDir = await getTemporaryDirectory();
  //     final tempFile = File('${tempDir.path}/stored_face.jpg');
  //     await tempFile.writeAsBytes(storedBytes);
  //     final storedInputImage = InputImage.fromFilePath(tempFile.path);
  //     final storedFaces = await faceDetector.processImage(storedInputImage);
  //
  //     if (storedFaces.isEmpty) {
  //       showError('No face found in stored admin photo');
  //       setState(() => isLoading = false);
  //       return;
  //     }
  //
  //     print('Stored faces: ${storedFaces.length}');
  //     final storedFace = storedFaces[0];
  //     print(
  //       'Stored left eye: ${storedFace.landmarks[FaceLandmarkType.leftEye]?.position}',
  //     );
  //     print(
  //       'Stored right eye: ${storedFace.landmarks[FaceLandmarkType.rightEye]?.position}',
  //     );
  //     print(
  //       'Stored nose: ${storedFace.landmarks[FaceLandmarkType.noseBase]?.position}',
  //     );
  //
  //     // Compare faces
  //     bool facesMatch = false;
  //     final capturedLeftEye = capturedFace.landmarks[FaceLandmarkType.leftEye];
  //     final capturedRightEye =
  //         capturedFace.landmarks[FaceLandmarkType.rightEye];
  //     final storedLeftEye = storedFace.landmarks[FaceLandmarkType.leftEye];
  //     final storedRightEye = storedFace.landmarks[FaceLandmarkType.rightEye];
  //
  //     final capturedNose = capturedFace.landmarks[FaceLandmarkType.noseBase];
  //     final storedNose = storedFace.landmarks[FaceLandmarkType.noseBase];
  //
  //     if (capturedLeftEye != null &&
  //         capturedRightEye != null &&
  //         storedLeftEye != null &&
  //         storedRightEye != null) {
  //       // Compare eye distances
  //       final capturedEyeDistance = _calculateDistance(
  //         capturedLeftEye.position,
  //         capturedRightEye.position,
  //       );
  //       final storedEyeDistance = _calculateDistance(
  //         storedLeftEye.position,
  //         storedRightEye.position,
  //       );
  //
  //       // If eye distances are similar (within 20% difference), consider match
  //       final difference =
  //           (capturedEyeDistance - storedEyeDistance).abs() / storedEyeDistance;
  //       if (difference <= 0.2) {
  //         facesMatch = true;
  //       }
  //     } else if (capturedNose != null && storedNose != null) {
  //       // Fallback: compare relative nose position in bounding box
  //       final capturedBox = capturedFace.boundingBox;
  //       final storedBox = storedFace.boundingBox;
  //
  //       final capturedNoseRelX =
  //           (capturedNose.position.x - capturedBox.left) / capturedBox.width;
  //       final capturedNoseRelY =
  //           (capturedNose.position.y - capturedBox.top) / capturedBox.height;
  //
  //       final storedNoseRelX =
  //           (storedNose.position.x - storedBox.left) / storedBox.width;
  //       final storedNoseRelY =
  //           (storedNose.position.y - storedBox.top) / storedBox.height;
  //
  //       print('Captured nose rel: $capturedNoseRelX, $capturedNoseRelY');
  //       print('Stored nose rel: $storedNoseRelX, $storedNoseRelY');
  //
  //       final noseDiffX = (capturedNoseRelX - storedNoseRelX).abs();
  //       final noseDiffY = (capturedNoseRelY - storedNoseRelY).abs();
  //
  //       if (noseDiffX <= 0.1 && noseDiffY <= 0.1) {
  //         // Within 10% relative difference
  //         facesMatch = true;
  //       }
  //     } else {
  //       // No reliable landmarks detected, do not match
  //       facesMatch = false;
  //     }
  //
  //     if (!facesMatch) {
  //       showError('Face does not match stored admin photo');
  //       setState(() => isLoading = false);
  //       return;
  //     }
  //
  //     // Faces match
  //     final username = admin['username'] ?? 'admin';
  //
  //     // Save login info
  //     final prefs = await SharedPreferences.getInstance();
  //     await prefs.setString('role', 'admin');
  //     await prefs.setBool('rememberMe', false); // Face ID doesn't remember
  //     await prefs.setString('username', username);
  //     await prefs.setInt('schoolId', schoolId);
  //
  //     // Trigger sync
  //     try {
  //       await ApiService.triggerInitialSync(
  //         schoolId: schoolId,
  //         userId: username,
  //       );
  //     } catch (e) {
  //       debugPrint('Sync trigger failed: $e');
  //     }
  //
  //     // Navigate to admin dashboard
  //     if (mounted) {
  //       Navigator.push(
  //         context,
  //         MaterialPageRoute(
  //           builder:
  //               (_) => AdminDashboard(
  //                 username: username,
  //                 schoolId: schoolId.toString(),
  //               ),
  //         ),
  //       );
  //     }
  //   } catch (e) {
  //     showError('Face recognition failed: $e');
  //     print('Face recognition failed: $e');
  //   } finally {
  //     setState(() => isLoading = false);
  //   }
  // }
  //
  // void _handleFaceIdLogin() async {
  //   // Show dialog to enter school ID
  //   final schoolIdController = TextEditingController();
  //   String? schoolId = await showDialog<String>(
  //     context: context,
  //     builder:
  //         (context) => AlertDialog(
  //           title: const Text('Enter School ID'),
  //           content: TextField(
  //             controller: schoolIdController,
  //             keyboardType: TextInputType.number,
  //             decoration: const InputDecoration(hintText: 'School ID'),
  //           ),
  //           actions: [
  //             TextButton(
  //               onPressed: () => Navigator.of(context).pop(),
  //               child: const Text('Cancel'),
  //             ),
  //             TextButton(
  //               onPressed:
  //                   () => Navigator.of(context).pop(schoolIdController.text),
  //               child: const Text('Next'),
  //             ),
  //           ],
  //         ),
  //   );
  //
  //   if (schoolId == null || schoolId.isEmpty) return;
  //
  //   final schoolIdInt = int.tryParse(schoolId);
  //   if (schoolIdInt == null) {
  //     showError('Invalid School ID');
  //     return;
  //   }
  //
  //   // Open camera to scan face
  //   try {
  //     // Request camera permission
  //     final status = await Permission.camera.request();
  //     if (status != PermissionStatus.granted) {
  //       showError(
  //         'Camera permission denied. Please grant permission for face scanning.',
  //       );
  //       return;
  //     }
  //
  //     final cameras = await availableCameras();
  //     if (cameras.isEmpty) {
  //       showError('No camera available');
  //       return;
  //     }
  //
  //     final frontCamera = cameras.firstWhere(
  //       (camera) => camera.lensDirection == CameraLensDirection.front,
  //       orElse: () => cameras.first,
  //     );
  //
  //     // Fetch admin data for the school
  //     final adminData = await AdminApiService.fetchAllAdminPic(
  //       schoolId: schoolId.toString(),
  //     );
  //
  //     if (adminData.isEmpty) {
  //       showError('No admin data found for the school');
  //       return;
  //     }
  //
  //     // For simplicity, take the first admin
  //     final admin = adminData[0];
  //     if (admin['photo'] == null || admin['photo'].isEmpty) {
  //       showError('No admin photo found for face matching');
  //       return;
  //     }
  //
  //     // Navigate to camera screen for live scan
  //     final result = await Navigator.push(
  //       context,
  //       MaterialPageRoute(
  //         builder: (_) => FaceScanScreen(camera: frontCamera, admin: admin),
  //       ),
  //     );
  //
  //     if (result == true) {
  //       // Login successful
  //       final username = admin['username'] ?? 'admin';
  //
  //       // Save login info
  //       final prefs = await SharedPreferences.getInstance();
  //       await prefs.setString('role', 'admin');
  //       await prefs.setBool('rememberMe', false);
  //       await prefs.setString('username', username);
  //       await prefs.setInt('schoolId', schoolIdInt);
  //
  //       // Trigger sync
  //       try {
  //         await ApiService.triggerInitialSync(
  //           schoolId: schoolIdInt,
  //           userId: username,
  //         );
  //       } catch (e) {
  //         debugPrint('Sync trigger failed: $e');
  //       }
  //
  //       // Navigate to admin dashboard
  //       if (mounted) {
  //         Navigator.push(
  //           context,
  //           MaterialPageRoute(
  //             builder:
  //                 (_) => AdminDashboard(
  //                   username: username,
  //                   schoolId: schoolIdInt.toString(),
  //                 ),
  //           ),
  //         );
  //       }
  //     }
  //   } catch (e) {
  //     showError('Camera error: $e');
  //     print('Camera error: $e');
  //   }
  // }
  //
  //     if (faces.isEmpty) {
  //       showError('No face detected. Please try again.');
  //       setState(() => isLoading = false);
  //       return;
  //     }
  //
  //     // Fetch admin data for the school
  //     final adminData = await ApiService.fetchAdminAndSchoolData(
  //       username: '', // We don't have username, so fetch all admins
  //       schoolId: schoolId.toString(),
  //     );
  //
  //     if (adminData['status'] != 'success') {
  //       showError('Failed to fetch admin data');
  //       setState(() => isLoading = false);
  //       return;
  //     }
  //
  //     final data = adminData['data'];
  //     final admin = data?['adminData'];
  //
  //     if (admin == null || admin['photo'] == null || admin['photo'].isEmpty) {
  //       showError('No admin photo found for face matching');
  //       setState(() => isLoading = false);
  //       return;
  //     }
  //
  //     // For simplicity, since full face matching requires advanced ML,
  //     // we'll check if face is detected in captured image and admin has photo
  //     // In a real app, you'd compare face embeddings
  //
  //     // Placeholder: assume match if face detected and admin photo exists
  //     final username = admin['name'] ?? 'admin';
  //
  //     // Save login info
  //     final prefs = await SharedPreferences.getInstance();
  //     await prefs.setString('role', 'admin');
  //     await prefs.setBool('rememberMe', false); // Face ID doesn't remember
  //     await prefs.setString('username', username);
  //     await prefs.setInt('schoolId', schoolId);
  //
  //     // Trigger sync
  //     try {
  //       await ApiService.triggerInitialSync(
  //         schoolId: schoolId,
  //         userId: username,
  //       );
  //     } catch (e) {
  //       debugPrint('Sync trigger failed: $e');
  //     }
  //
  //     // Navigate to admin dashboard
  //     if (mounted) {
  //       Navigator.push(
  //         context,
  //         MaterialPageRoute(
  //           builder:
  //               (_) => AdminDashboard(
  //                 username: username,
  //                 schoolId: schoolId.toString(),
  //               ),
  //         ),
  //       );
  //     }
  //   } catch (e) {
  //     showError('Face recognition failed: $e');
  //   } finally {
  //     setState(() => isLoading = false);
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF2B7CA8), Color(0xFF4FAFD6)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight:
                    MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top -
                    MediaQuery.of(context).padding.bottom,
              ),
              child: IntrinsicHeight(
                child: Column(
                  mainAxisAlignment:
                      MainAxisAlignment.center, // 👈 Centers vertically
                  children: [
                    // 🏫 Logo
                    AnimatedOpacity(
                      duration: const Duration(seconds: 1),
                      opacity: 1.0,
                      child: Column(
                        children: [
                          // const SizedBox(height: 12),
                          // Image.asset(
                          //   'assets/favicon.png',
                          //   height: 100,
                          //   fit: BoxFit.contain,
                          // ),
                          const SizedBox(height: 12),
                          SizedBox(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Text(
                                textAlign: TextAlign.center,
                                softWrap: true,
                                'Smart School App',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Good Times',
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 👇 Centered Login Box
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.lock_outline,
                            size: 80,
                            color: Color(0xFF2B7CA8),
                          ),
                          SizedBox(height: 10),
                          const Text(
                            "Welcome",
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 20),
                          _buildInputField(
                            controller: _schoolIdController,
                            hint: "School ID",
                            icon: Icons.school,
                            inputType: TextInputType.number,
                          ),
                          const SizedBox(height: 16),
                          _buildInputField(
                            controller: _usernameController,
                            hint: "User ID",
                            icon: Icons.person,
                          ),
                          const SizedBox(height: 16),
                          _buildInputField(
                            controller: _passwordController,
                            hint: "Password",
                            icon: Icons.lock,
                            obscure: _obscurePassword,
                            suffix: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: const Color(0xFF2B7CA8),
                              ),
                              onPressed:
                                  () => setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  }),
                            ),
                          ),
                          const SizedBox(height: 20),

                          Row(
                            children: [
                              Checkbox(
                                value: rememberMe,
                                onChanged: (value) {
                                  setState(() {
                                    rememberMe = value ?? false;
                                  });
                                },
                                activeColor: const Color(0xFF2B7CA8),
                              ),
                              const Text(
                                'Remember Me',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),

                          Row(
                            children: [
                              const Spacer(),
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (_) => const ForgotPasswordPage(),
                                    ),
                                  );
                                },
                                child: const Text(
                                  "Forgot Password?",
                                  style: TextStyle(color: Color(0xFF2B7CA8)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    _isFormValid
                                        ? const Color(0xFF2B7CA8)
                                        : Colors.grey,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              onPressed:
                                  (_isFormValid && !isLoading) ? login : null,
                              child:
                                  isLoading
                                      ? const SpinKitThreeBounce(
                                        color: Colors.white,
                                        size: 20,
                                      )
                                      : Text(
                                        'Login',
                                        style: TextStyle(
                                          color:
                                              _isFormValid
                                                  ? Colors.white
                                                  : Colors.grey,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                            ),
                          ),
                          const SizedBox(height: 10),

                          Row(
                            children: [
                              Spacer(),
                              TextButton.icon(
                                icon: Icon(
                                  Icons.arrow_forward,
                                  color: Color(0xFF2B7CA8),
                                  size: 20,
                                  weight: 3,
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const DemoIdsPage(),
                                    ),
                                  );
                                },
                                label: Text(
                                  'Explore Demo',
                                  style: TextStyle(
                                    color: Color(0xFF2B7CA8),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                iconAlignment: IconAlignment.end,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Face ID Button
                    // SizedBox(
                    //   width: double.infinity,
                    //   height: 50,
                    //   child: OutlinedButton.icon(
                    //     icon: const Icon(Icons.face, color: Colors.white),
                    //     label: const Text(
                    //       'Face ID Login',
                    //       style: TextStyle(
                    //         color: Colors.white,
                    //         fontSize: 16,
                    //         fontWeight: FontWeight.bold,
                    //       ),
                    //     ),
                    //     style: OutlinedButton.styleFrom(
                    //       side: const BorderSide(color: Colors.white),
                    //       shape: RoundedRectangleBorder(
                    //         borderRadius: BorderRadius.circular(30),
                    //       ),
                    //     ),
                    //     onPressed: _handleFaceIdLogin,
                    //   ),
                    // ),
                    // const SizedBox(height: 20),
                    Text(
                      '© ${DateTime.now().year.toString()} Ramchin Technologies Pvt. Ltd.',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // double _calculateDistance(Point<int> p1, Point<int> p2) {
  //   return sqrt(pow(p1.x - p2.x, 2) + pow(p1.y - p2.y, 2));
  // }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType inputType = TextInputType.text,
    bool obscure = false,
    Widget? suffix,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black),
        borderRadius: BorderRadius.circular(20),
      ),
      child: TextField(
        onChanged: (val) async {
          if (hint == "School ID") {
            final schoolId = int.tryParse(val);
            if (schoolId != null) {
              await _checkBlocked(schoolId);
            }
          }
          _validateForm();
        },
        controller: controller,
        obscureText: obscure,
        keyboardType: inputType,
        style: const TextStyle(color: Colors.black),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: const Color(0xFF2B7CA8)),
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.black),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 20,
          ),
          suffixIcon: suffix,
        ),
      ),
    );
  }
}
