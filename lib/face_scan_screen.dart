// import 'dart:io';
// import 'dart:typed_data';
// import 'dart:ui';
// import 'dart:convert';
// import 'package:camera/camera.dart';
// import 'package:flutter/material.dart';
// import 'package:google_ml_kit/google_ml_kit.dart';
// import 'package:path_provider/path_provider.dart';
//
// class FaceScanScreen extends StatefulWidget {
//   final CameraDescription camera;
//   final Map<String, dynamic> admin;
//
//   const FaceScanScreen({super.key, required this.camera, required this.admin});
//
//   @override
//   State<FaceScanScreen> createState() => _FaceScanScreenState();
// }
//
// class _FaceScanScreenState extends State<FaceScanScreen> {
//   late CameraController _controller;
//   late FaceDetector _faceDetector;
//   late Future<void> _initializeControllerFuture;
//   bool _isDetecting = false;
//   bool _isCapturing = false;
//   int _matchCount = 0;
//   late File _storedImageFile;
//
//   @override
//   void initState() {
//     super.initState();
//     _controller = CameraController(
//       widget.camera,
//       ResolutionPreset.medium,
//     );
//     _faceDetector = GoogleMlKit.vision.faceDetector();
//     _initializeControllerFuture = _initializeCamera();
//   }
//
//   Future<void> _initializeCamera() async {
//     await _controller.initialize();
//     // Prepare stored image
//     List<int> storedBytes = base64Decode(widget.admin['photo']);
//     final tempDir = await getTemporaryDirectory();
//     _storedImageFile = File('${tempDir.path}/stored_face.jpg');
//     await _storedImageFile.writeAsBytes(storedBytes);
//
//     // Start image stream for live detection
//     _controller.startImageStream(_processCameraImage);
//   }
//
//   @override
//   void dispose() {
//     try {
//       _controller.stopImageStream();
//     } catch (e) {
//       // Ignore if not streaming
//     }
//     _controller.dispose();
//     _faceDetector.close();
//     super.dispose();
//   }
//
//   void _processCameraImage(CameraImage image) async {
//     if (_isDetecting) return;
//     _isDetecting = true;
//     try {
//       final inputImage = _inputImageFromCameraImage(image);
//       if (inputImage == null) return;
//       final faces = await _faceDetector.processImage(inputImage);
//
//       if (faces.isNotEmpty && !_isCapturing) {
//         _isCapturing = true;
//         try {
//           final file = await _controller.takePicture();
//           final capturedInputImage = InputImage.fromFilePath(file.path);
//           final capturedFaces = await _faceDetector.processImage(capturedInputImage);
//
//           if (capturedFaces.isNotEmpty) {
//             final capturedFace = capturedFaces[0];
//
//             // Detect in stored image (cached)
//             final storedInputImage = InputImage.fromFilePath(_storedImageFile.path);
//             final storedFaces = await _faceDetector.processImage(storedInputImage);
//
//             if (storedFaces.isNotEmpty) {
//               final storedFace = storedFaces[0];
//
//               bool facesMatch = false;
//
//               final capturedLeftEye = capturedFace.landmarks[FaceLandmarkType.leftEye];
//               final capturedRightEye = capturedFace.landmarks[FaceLandmarkType.rightEye];
//               final storedLeftEye = storedFace.landmarks[FaceLandmarkType.leftEye];
//               final storedRightEye = storedFace.landmarks[FaceLandmarkType.rightEye];
//
//               if (capturedLeftEye != null &&
//                   capturedRightEye != null &&
//                   storedLeftEye != null &&
//                   storedRightEye != null) {
//                 final capturedEyeDistance = _calculateDistance(
//                   capturedLeftEye.position.x.toDouble(),
//                   capturedLeftEye.position.y.toDouble(),
//                   capturedRightEye.position.x.toDouble(),
//                   capturedRightEye.position.y.toDouble(),
//                 );
//                 final storedEyeDistance = _calculateDistance(
//                   storedLeftEye.position.x.toDouble(),
//                   storedLeftEye.position.y.toDouble(),
//                   storedRightEye.position.x.toDouble(),
//                   storedRightEye.position.y.toDouble(),
//                 );
//
//                 final difference = (capturedEyeDistance - storedEyeDistance).abs() / storedEyeDistance;
//                 if (difference <= 0.2) {
//                   facesMatch = true;
//                 }
//               } else {
//                 final capturedNose = capturedFace.landmarks[FaceLandmarkType.noseBase];
//                 final storedNose = storedFace.landmarks[FaceLandmarkType.noseBase];
//
//                 if (capturedNose != null && storedNose != null) {
//                   final capturedBoundingBox = capturedFace.boundingBox;
//                   final storedBoundingBox = storedFace.boundingBox;
//
//                   final capturedNoseX = capturedNose.position.x.toDouble() / capturedBoundingBox.width;
//                   final storedNoseX = storedNose.position.x.toDouble() / storedBoundingBox.width;
//                   final capturedNoseY = capturedNose.position.y.toDouble() / capturedBoundingBox.height;
//                   final storedNoseY = storedNose.position.y.toDouble() / storedBoundingBox.height;
//
//                   final noseDiff = ((capturedNoseX - storedNoseX).abs() + (capturedNoseY - storedNoseY).abs()) / 2;
//                   if (noseDiff <= 0.1) {
//                     facesMatch = true;
//                   }
//                 }
//               }
//
//               if (facesMatch) {
//                 _matchCount++;
//                 if (_matchCount >= 5) {
//                   if (mounted) {
//                     Navigator.of(context).pop(true);
//                   }
//                 }
//               } else {
//                 _matchCount = 0;
//               }
//             }
//           }
//         } catch (e) {
//           print('Error capturing or processing image: $e');
//         } finally {
//           _isCapturing = false;
//         }
//       }
//     } catch (e) {
//       if (!e.toString().contains('InputImageConverterError')) {
//         print('Error processing image: $e');
//       }
//     } finally {
//       _isDetecting = false;
//     }
//   }
//
//   InputImage? _inputImageFromCameraImage(CameraImage image) {
//     try {
//       final camera = widget.camera;
//       final rotation = InputImageRotationValue.fromRawValue(camera.sensorOrientation) ?? InputImageRotation.rotation0deg;
//       final format = InputImageFormatValue.fromRawValue(image.format.raw) ?? InputImageFormat.nv21;
//       final yPlane = image.planes[0];
//       final uvPlane = image.planes[1];
//       final bytes = Uint8List(yPlane.bytes.length + uvPlane.bytes.length);
//       bytes.setRange(0, yPlane.bytes.length, yPlane.bytes);
//       bytes.setRange(yPlane.bytes.length, bytes.length, uvPlane.bytes);
//       return InputImage.fromBytes(
//         bytes: bytes,
//         metadata: InputImageMetadata(
//           size: Size(image.width.toDouble(), image.height.toDouble()),
//           rotation: rotation,
//           format: format,
//           bytesPerRow: image.width.toInt(),
//         ),
//       );
//     } catch (e) {
//       // Skip bad frames
//       return null;
//     }
//   }
//
//   double _calculateDistance(double x1, double y1, double x2, double y2) {
//     return (x1 - x2).abs() + (y1 - y2).abs(); // Manhattan distance for simplicity
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Live Face Scan'),
//         backgroundColor: const Color(0xFF2B7CA8),
//       ),
//       body: FutureBuilder<void>(
//         future: _initializeControllerFuture,
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.done) {
//             return Stack(
//               children: [
//                 CameraPreview(_controller),
//                 Positioned(
//                   top: 50,
//                   left: 20,
//                   right: 20,
//                   child: Container(
//                     padding: const EdgeInsets.all(16),
//                     decoration: BoxDecoration(
//                       color: Colors.black.withOpacity(0.7),
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                     child: Text(
//                       _matchCount > 0 ? 'Face detected! Matching... ($_matchCount/5)' : 'Position your face in the center',
//                       style: const TextStyle(
//                         color: Colors.white,
//                         fontSize: 16,
//                       ),
//                       textAlign: TextAlign.center,
//                     ),
//                   ),
//                 ),
//                 Positioned(
//                   bottom: 20,
//                   left: 20,
//                   right: 20,
//                   child: ElevatedButton(
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.red,
//                       padding: const EdgeInsets.symmetric(vertical: 16),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(30),
//                       ),
//                     ),
//                     onPressed: () {
//                       _controller.stopImageStream();
//                       Navigator.of(context).pop(false);
//                     },
//                     child: const Text(
//                       'Cancel',
//                       style: TextStyle(
//                         color: Colors.white,
//                         fontSize: 18,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             );
//           } else {
//             return const Center(child: CircularProgressIndicator());
//           }
//         },
//       ),
//     );
//   }
// }
