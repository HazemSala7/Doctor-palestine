import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class GoogleMapScreen extends StatelessWidget {
  final String hospitalName;
  final double lat;
  final double lng;

  const GoogleMapScreen({
    Key? key,
    required this.hospitalName,
    required this.lat,
    required this.lng,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final LatLng hospitalLocation = LatLng(lat, lng);

    return Scaffold(
      appBar: AppBar(title: Text('موقع $hospitalName')),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: hospitalLocation,
          zoom: 15,
        ),
        markers: {
          Marker(
            markerId: MarkerId('hospital'),
            position: hospitalLocation,
            infoWindow: InfoWindow(title: hospitalName),
          ),
        },
      ),
    );
  }
}
