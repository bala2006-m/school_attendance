// import 'package:flutter/material.dart';
// import 'package:flutter_map/flutter_map.dart';
// import 'package:geolocator/geolocator.dart' as geolocator;
// // import 'package:latlong2/latlong.dart';
//
// class LocationMapPage extends StatefulWidget {
//   const LocationMapPage({super.key});
//
//   @override
//   State<LocationMapPage> createState() => _LocationMapPageState();
// }
//
// class _LocationMapPageState extends State<LocationMapPage> {
//   static const double fixedLat = 8.508685075753176;
//   static const double fixedLng = 78.11677785463043;
//   final LatLng fixedPoint = const LatLng(fixedLat, fixedLng);
//
//   geolocator.Position? currentGeoPos;
//   bool isInside = false;
//   double? distanceInMeters;
//
//   MapController mapController = MapController();
//
//   @override
//   void initState() {
//     super.initState();
//     _initLocationTracking();
//   }
//
//   Future<void> _initLocationTracking() async {
//     bool serviceEnabled =
//         await geolocator.Geolocator.isLocationServiceEnabled();
//     if (!serviceEnabled) {
//       await geolocator.Geolocator.openLocationSettings();
//       return;
//     }
//
//     geolocator.LocationPermission perm =
//         await geolocator.Geolocator.checkPermission();
//     if (perm == geolocator.LocationPermission.denied) {
//       perm = await geolocator.Geolocator.requestPermission();
//       if (perm == geolocator.LocationPermission.denied) return;
//     }
//     if (perm == geolocator.LocationPermission.deniedForever) return;
//
//     geolocator.Position pos = await geolocator.Geolocator.getCurrentPosition();
//     _updatePosition(pos);
//
//     geolocator.Geolocator.getPositionStream(
//       locationSettings: const geolocator.LocationSettings(
//         accuracy: geolocator.LocationAccuracy.best,
//         distanceFilter: 1,
//       ),
//     ).listen((pos) {
//       _updatePosition(pos);
//     });
//   }
//
//   void _updatePosition(geolocator.Position geoPos) {
//     final double dist = geolocator.Geolocator.distanceBetween(
//       fixedLat,
//       fixedLng,
//       geoPos.latitude,
//       geoPos.longitude,
//     );
//
//     final bool inside = dist <= 100.0;
//
//     setState(() {
//       currentGeoPos = geoPos;
//       isInside = inside;
//       distanceInMeters = dist;
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Map Location & Radius")),
//       body:
//           currentGeoPos == null
//               ? const Center(child: CircularProgressIndicator())
//               : Stack(
//                 children: [
//                   FlutterMap(
//                     mapController: mapController,
//                     options: MapOptions(
//                       center: fixedPoint,
//                       zoom: 18.0,
//                       maxZoom: 18.0,
//                       minZoom: 0,
//                     ),
//                     children: [
//                       TileLayer(
//                         urlTemplate:
//                             'https://tiles.stadiamaps.com/tiles/alidade_satellite/{z}/{x}/{y}{r}.jpg?api_key=6b97c65d-b9bd-4806-babf-8d875e7e18d1',
//                         userAgentPackageName: 'com.demo.ramchin_smart_school',
//                       ),
//
//                       // Circle (geofence)
//                       CircleLayer(
//                         circles: [
//                           CircleMarker(
//                             point: fixedPoint,
//                             color: Colors.blue.withValues(alpha: 0.2),
//                             borderStrokeWidth: 2.0,
//                             borderColor: Colors.blue,
//                             radius: 100,
//                             useRadiusInMeter: true,
//                           ),
//                         ],
//                       ),
//
//                       // ✅ Line between fixed and current position (color depends on inside/outside)
//                       if (currentGeoPos != null)
//                         PolylineLayer(
//                           polylines: [
//                             Polyline(
//                               points: [
//                                 fixedPoint,
//                                 LatLng(
//                                   currentGeoPos!.latitude,
//                                   currentGeoPos!.longitude,
//                                 ),
//                               ],
//                               strokeWidth: 4.0,
//                               color: isInside ? Colors.green : Colors.red,
//                             ),
//                           ],
//                         ),
//
//                       // Markers
//                       MarkerLayer(
//                         markers: [
//                           Marker(
//                             point: fixedPoint,
//                             width: 40,
//                             height: 40,
//                             builder:
//                                 (_) => const Icon(
//                                   Icons.location_on,
//                                   color: Colors.green,
//                                   size: 40,
//                                 ),
//                           ),
//                           if (currentGeoPos != null)
//                             Marker(
//                               point: LatLng(
//                                 currentGeoPos!.latitude,
//                                 currentGeoPos!.longitude,
//                               ),
//                               width: 40,
//                               height: 40,
//                               builder:
//                                   (_) => Icon(
//                                     Icons.person_pin_circle,
//                                     color: isInside ? Colors.green : Colors.red,
//                                     size: 40,
//                                   ),
//                             ),
//                         ],
//                       ),
//
//                       // const SimpleAttributionWidget(
//                       //   source: Text('© OpenStreetMap contributors'),
//                       // ),
//                     ],
//                   ),
//
//                   // ✅ Distance Display (in km)
//                   if (distanceInMeters != null)
//                     Positioned(
//                       bottom: 20,
//                       left: 20,
//                       right: 20,
//                       child: Container(
//                         padding: const EdgeInsets.all(10),
//                         decoration: BoxDecoration(
//                           color: Colors.black.withValues(alpha: 0.6),
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                         child: Text(
//                           "Distance: ${(distanceInMeters! / 1000).toStringAsFixed(3)} km",
//                           style: const TextStyle(
//                             color: Colors.white,
//                             fontSize: 16,
//                             fontWeight: FontWeight.bold,
//                           ),
//                           textAlign: TextAlign.center,
//                         ),
//                       ),
//                     ),
//                 ],
//               ),
//     );
//   }
// }
