import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class FieldOperatorMapScreen extends StatelessWidget {
  final double latitude;
  final double longitude;

  const FieldOperatorMapScreen({
    super.key,
    required this.latitude,
    required this.longitude,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final location = LatLng(latitude, longitude);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Report Location"),
        centerTitle: true,
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: location,
          zoom: 16,
        ),
        markers: {
          Marker(
            markerId: const MarkerId("report_location"),
            position: location,
          ),
        },
        myLocationButtonEnabled: false,
        zoomControlsEnabled: true,
        mapToolbarEnabled: false,
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        color: scheme.surface,
        child: Text(
          "Lat $latitude, Lng $longitude",
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}
