import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:http/http.dart' as http;

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/api_keys.dart';
import '../../../../core/data/destination_model.dart';

class MapScreen extends StatefulWidget {
  final DestinationModel destination;

  const MapScreen({super.key, required this.destination});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? mapController;
  Position? currentPosition;
  Map<PolylineId, Polyline> polylines = {};
  
  String distanceText = '';
  String durationText = '';
  bool isLoading = true;
  String errorMsg = '';

  late double destLat;
  late double destLng;

  @override
  void initState() {
    super.initState();
    destLat = widget.destination.latitude ?? 10.772596;
    destLng = widget.destination.longitude ?? 106.698020;
    _initMapAndRoute();
  }

  Future<void> _initMapAndRoute() async {
    try {
      await _checkLocationPermission();
      currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (currentPosition != null) {
        await _getRouteToDestination();
      }
    } catch (e) {
      setState(() {
        errorMsg = e.toString();
      });
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _checkLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw 'Dịch vụ vị trí đang bị tắt.';
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw 'Quyền truy cập vị trí bị từ chối.';
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw 'Quyền vị trí bị từ chối vĩnh viễn, không thể lấy vị trí.';
    }
  }

  Future<void> _getRouteToDestination() async {
    if (ApiKeys.googleMapsApiKey.contains('PASTE_YOUR')) {
      setState(() {
        distanceText = 'Vui lòng điền API Key';
        durationText = 'Lỗi kết nối';
      });
      return;
    }

    final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/directions/json?origin=${currentPosition!.latitude},${currentPosition!.longitude}&destination=$destLat,$destLng&key=${ApiKeys.googleMapsApiKey}');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          final route = data['routes'][0];
          final leg = route['legs'][0];
          
          setState(() {
            distanceText = leg['distance']['text'];
            durationText = leg['duration']['text'];
          });

          // Giải mã Polyline
          final String encodedPolyline = route['overview_polyline']['points'];
          PolylinePoints polylinePoints = PolylinePoints(apiKey: '');
          List<PointLatLng> decodedPoints = PolylinePoints.decodePolyline(encodedPolyline);

          List<LatLng> polylineCoordinates = decodedPoints
              .map((point) => LatLng(point.latitude, point.longitude))
              .toList();

          PolylineId id = const PolylineId('route');
          Polyline polyline = Polyline(
            polylineId: id,
            color: AppColors.primary,
            points: polylineCoordinates,
            width: 5,
            geodesic: true,
          );

          setState(() {
            polylines[id] = polyline;
          });

          _animateToFitRoute();
        } else {
          debugPrint('Directions API Error: ${data['error_message'] ?? data['status']}');
        }
      }
    } catch (e) {
      debugPrint('Error fetch directions: $e');
    }
  }

  void _animateToFitRoute() {
    if (mapController == null || currentPosition == null) return;
    
    double minLat = currentPosition!.latitude < destLat ? currentPosition!.latitude : destLat;
    double maxLat = currentPosition!.latitude > destLat ? currentPosition!.latitude : destLat;
    double minLng = currentPosition!.longitude < destLng ? currentPosition!.longitude : destLng;
    double maxLng = currentPosition!.longitude > destLng ? currentPosition!.longitude : destLng;

    LatLngBounds bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 80));
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    if (polylines.isNotEmpty) {
      _animateToFitRoute();
    }
  }

  @override
  Widget build(BuildContext context) {
    Set<Marker> markers = {
      Marker(
        markerId: MarkerId(widget.destination.id.toString()),
        position: LatLng(destLat, destLng),
        infoWindow: InfoWindow(
          title: widget.destination.title,
          snippet: widget.destination.region,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      )
    };

    if (currentPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: LatLng(currentPosition!.latitude, currentPosition!.longitude),
          infoWindow: const InfoWindow(title: 'Bạn đang ở đây'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        )
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          widget.destination.title,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        backgroundColor: Colors.white.withValues(alpha: 0.9),
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: Stack(
        children: [
          if (!isLoading)
            GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: LatLng(destLat, destLng),
                zoom: 15.0,
              ),
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              markers: markers,
              polylines: Set<Polyline>.of(polylines.values),
            ),
            
          if (isLoading)
            const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
            
          if (errorMsg.isNotEmpty)
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.symmetric(horizontal: 32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.orange, size: 48),
                    const SizedBox(height: 16),
                    Text(errorMsg, textAlign: TextAlign.center),
                  ],
                ),
              ),
            ),

          if (!isLoading && distanceText.isNotEmpty && durationText.isNotEmpty)
            Positioned(
              left: 20,
              right: 20,
              bottom: 40,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    )
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.directions_car, color: AppColors.primary),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            durationText,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Khoảng cách: $distanceText',
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.my_location, color: AppColors.primary),
                      onPressed: _animateToFitRoute,
                      iconSize: 28,
                    )
                  ],
                ),
              ),
            ),
            
        ],
      ),
    );
  }
}
