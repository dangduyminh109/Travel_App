import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/api_keys.dart';
import '../../../../core/constants/app_colors.dart';
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

  double? destLat;
  double? destLng;

  bool get _hasDestinationCoordinates => destLat != null && destLng != null;

  bool get _hasRoute =>
      distanceText.isNotEmpty &&
      durationText.isNotEmpty &&
      polylines.isNotEmpty;

  @override
  void initState() {
    super.initState();
    destLat = widget.destination.latitude;
    destLng = widget.destination.longitude;
    _initMapAndRoute();
  }

  Future<void> _initMapAndRoute() async {
    if (!_hasDestinationCoordinates) {
      setState(() {
        isLoading = false;
        errorMsg = 'Địa điểm này chưa có tọa độ nên chưa thể hiển thị bản đồ.';
      });
      return;
    }

    try {
      await _checkLocationPermission();
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      );
      if (!mounted) return;
      setState(() {
        currentPosition = position;
        errorMsg = '';
      });
      await _getRouteToDestination();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorMsg = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _checkLocationPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw 'Dịch vụ vị trí đang bị tắt. Bạn vẫn có thể xem vị trí địa điểm trên bản đồ.';
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw 'Quyền truy cập vị trí bị từ chối. Hãy cấp quyền vị trí để vẽ tuyến đường từ chỗ bạn.';
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw 'Quyền vị trí bị từ chối vĩnh viễn. Hãy mở cài đặt ứng dụng để cấp quyền lại.';
    }
  }

  Future<void> _getRouteToDestination() async {
    if (!_hasDestinationCoordinates || currentPosition == null) return;

    final apiKey = ApiKeys.googleWebServicesApiKey.trim();
    if (apiKey.isEmpty || apiKey.contains('PASTE_YOUR')) {
      setState(() {
        errorMsg = 'Vui lòng cấu hình Google Web Services API key.';
      });
      return;
    }

    final url = Uri.https('maps.googleapis.com', '/maps/api/directions/json', {
      'origin': '${currentPosition!.latitude},${currentPosition!.longitude}',
      'destination': '$destLat,$destLng',
      'mode': 'driving',
      'language': 'vi',
      'region': 'vn',
      'key': apiKey,
    });

    try {
      final response = await http.get(url);
      if (!mounted) return;

      if (response.statusCode != 200) {
        setState(() {
          errorMsg =
              'Không thể kết nối Directions API. Mã lỗi HTTP: ${response.statusCode}.';
        });
        return;
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
      final status = data['status'] as String? ?? 'UNKNOWN_ERROR';
      if (status != 'OK') {
        final googleMessage = data['error_message'] as String?;
        setState(() {
          errorMsg = _directionsErrorMessage(status, googleMessage);
        });
        return;
      }

      final routes = data['routes'];
      if (routes is! List || routes.isEmpty) {
        setState(() {
          errorMsg = 'Google Maps không trả về tuyến đường phù hợp.';
        });
        return;
      }

      final route = routes.first as Map<String, dynamic>;
      final legs = route['legs'];
      if (legs is! List || legs.isEmpty) {
        setState(() {
          errorMsg = 'Không đọc được thông tin khoảng cách từ Directions API.';
        });
        return;
      }

      final leg = legs.first as Map<String, dynamic>;
      final encodedPolyline =
          (route['overview_polyline'] as Map<String, dynamic>?)?['points']
              as String?;
      if (encodedPolyline == null || encodedPolyline.isEmpty) {
        setState(() {
          errorMsg = 'Không đọc được đường đi từ Directions API.';
        });
        return;
      }

      final decodedPoints = PolylinePoints.decodePolyline(encodedPolyline);
      final polylineCoordinates = decodedPoints
          .map((point) => LatLng(point.latitude, point.longitude))
          .toList();

      const id = PolylineId('route');
      final polyline = Polyline(
        polylineId: id,
        color: AppColors.primary,
        points: polylineCoordinates,
        width: 5,
        geodesic: true,
      );

      setState(() {
        distanceText =
            (leg['distance'] as Map<String, dynamic>?)?['text'] as String? ??
            '';
        durationText =
            (leg['duration'] as Map<String, dynamic>?)?['text'] as String? ??
            '';
        errorMsg = '';
        polylines[id] = polyline;
      });

      _animateToFitRoute();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        errorMsg =
            'Không thể tải tuyến đường. Kiểm tra mạng hoặc cấu hình Google API key.';
      });
    }
  }

  String _directionsErrorMessage(String status, String? googleMessage) {
    final normalizedMessage = googleMessage?.toLowerCase() ?? '';
    if (normalizedMessage.contains('enable billing')) {
      return 'Directions API key đã đúng, nhưng project chứa key này chưa bật hoặc chưa liên kết Billing. Hãy bật Billing cho đúng Google Cloud project của Directions key.';
    }
    if (normalizedMessage.contains('not authorized')) {
      return 'Directions API key chưa được phép gọi request này. Hãy kiểm tra Application restrictions và API restrictions của Directions key.';
    }

    return switch (status) {
      'REQUEST_DENIED' =>
        'Directions API đang từ chối request. Hãy kiểm tra billing, API restrictions và application restriction của Web Service key.',
      'OVER_QUERY_LIMIT' =>
        'Google Maps API đã vượt hạn mức. Hãy kiểm tra quota hoặc billing.',
      'ZERO_RESULTS' => 'Không tìm thấy tuyến đường phù hợp đến địa điểm này.',
      'NOT_FOUND' =>
        'Không tìm thấy điểm xuất phát hoặc điểm đến trên Google Maps.',
      'INVALID_REQUEST' =>
        'Request Directions API chưa hợp lệ. Hãy kiểm tra tọa độ địa điểm.',
      _ =>
        googleMessage?.isNotEmpty == true
            ? googleMessage!
            : 'Không thể lấy tuyến đường từ Google Maps. Mã lỗi: $status.',
    };
  }

  void _animateToFitRoute() {
    if (mapController == null ||
        currentPosition == null ||
        !_hasDestinationCoordinates) {
      return;
    }

    double minLat = currentPosition!.latitude < destLat!
        ? currentPosition!.latitude
        : destLat!;
    double maxLat = currentPosition!.latitude > destLat!
        ? currentPosition!.latitude
        : destLat!;
    double minLng = currentPosition!.longitude < destLng!
        ? currentPosition!.longitude
        : destLng!;
    double maxLng = currentPosition!.longitude > destLng!
        ? currentPosition!.longitude
        : destLng!;

    if (minLat == maxLat) {
      minLat -= 0.005;
      maxLat += 0.005;
    }
    if (minLng == maxLng) {
      minLng -= 0.005;
      maxLng += 0.005;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    mapController!
        .animateCamera(CameraUpdate.newLatLngBounds(bounds, 80))
        .catchError((_) {});
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    if (polylines.isNotEmpty) {
      // Wait for the Android map view to get a size before fitting bounds.
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _animateToFitRoute();
        }
      });
    }
  }

  Future<void> _openExternalDirections() async {
    if (!_hasDestinationCoordinates) return;

    final queryParameters = <String, String>{
      'api': '1',
      'destination': '$destLat,$destLng',
      'travelmode': 'driving',
    };
    if (currentPosition != null) {
      queryParameters['origin'] =
          '${currentPosition!.latitude},${currentPosition!.longitude}';
    }

    final uri = Uri.https('www.google.com', '/maps/dir/', queryParameters);
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể mở Google Maps.')),
      );
    }
  }

  Set<Marker> _buildMarkers() {
    if (!_hasDestinationCoordinates) return {};

    final markers = <Marker>{
      Marker(
        markerId: MarkerId(widget.destination.id.toString()),
        position: LatLng(destLat!, destLng!),
        infoWindow: InfoWindow(
          title: widget.destination.title,
          snippet: widget.destination.region,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    };

    if (currentPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: LatLng(
            currentPosition!.latitude,
            currentPosition!.longitude,
          ),
          infoWindow: const InfoWindow(title: 'Bạn đang ở đây'),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
        ),
      );
    }

    return markers;
  }

  @override
  Widget build(BuildContext context) {
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
          if (!_hasDestinationCoordinates)
            _buildMapUnavailableState()
          else if (!isLoading)
            GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: LatLng(destLat!, destLng!),
                zoom: 15.0,
              ),
              myLocationEnabled: currentPosition != null,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              markers: _buildMarkers(),
              polylines: Set<Polyline>.of(polylines.values),
            ),
          if (isLoading)
            const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          if (!isLoading && _hasDestinationCoordinates)
            Positioned(
              left: 20,
              right: 20,
              bottom: 32,
              child: _hasRoute ? _buildRouteCard() : _buildMapStatusCard(),
            ),
        ],
      ),
    );
  }

  Widget _buildMapUnavailableState() {
    return Container(
      color: AppColors.background,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(24),
      child: _buildMessagePanel(
        icon: Icons.location_off_outlined,
        title: 'Chưa có tọa độ',
        message: errorMsg,
        action: null,
      ),
    );
  }

  Widget _buildMapStatusCard() {
    final message = errorMsg.isNotEmpty
        ? errorMsg
        : 'Chưa thể vẽ tuyến đường. Bạn vẫn có thể mở Google Maps để xem đường đi.';

    return _buildMessagePanel(
      icon: Icons.route_outlined,
      title: 'Chưa có tuyến đường',
      message: message,
      action: OutlinedButton.icon(
        onPressed: _openExternalDirections,
        icon: const Icon(Icons.open_in_new, size: 18),
        label: const Text('Mở Google Maps'),
      ),
    );
  }

  Widget _buildRouteCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: _floatingPanelDecoration(),
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
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
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
            tooltip: 'Canh lại tuyến đường',
            icon: const Icon(Icons.my_location, color: AppColors.primary),
            onPressed: _animateToFitRoute,
          ),
          IconButton(
            tooltip: 'Mở Google Maps',
            icon: const Icon(Icons.open_in_new, color: AppColors.primary),
            onPressed: _openExternalDirections,
          ),
        ],
      ),
    );
  }

  Widget _buildMessagePanel({
    required IconData icon,
    required String title,
    required String message,
    required Widget? action,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _floatingPanelDecoration(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.secondaryDark, size: 36),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              height: 1.4,
              color: AppColors.textSecondary,
            ),
          ),
          if (action != null) ...[const SizedBox(height: 12), action],
        ],
      ),
    );
  }

  BoxDecoration _floatingPanelDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.12),
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }
}
