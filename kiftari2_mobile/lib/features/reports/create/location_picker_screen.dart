import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
  });

  final double? initialLatitude;
  final double? initialLongitude;

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  GoogleMapController? _mapController;
  LatLng? _currentLocation;
  LatLng? _selectedLocation;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final current = LatLng(position.latitude, position.longitude);
      final initial = (widget.initialLatitude != null &&
              widget.initialLongitude != null)
          ? LatLng(widget.initialLatitude!, widget.initialLongitude!)
          : current;

      setState(() {
        _currentLocation = current;
        _selectedLocation = initial;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  void _resetToCurrent() {
    if (_currentLocation == null || _mapController == null) return;
    setState(() => _selectedLocation = _currentLocation);
    _mapController!.animateCamera(
      CameraUpdate.newLatLng(_currentLocation!),
    );
  }

  void _confirmLocation() {
    if (_selectedLocation == null) return;
    Navigator.pop(context, {
      "latitude": _selectedLocation!.latitude,
      "longitude": _selectedLocation!.longitude,
    });
  }

  Future<void> _showLocationSearch() async {
    final scheme = Theme.of(context).colorScheme;
    final controller = TextEditingController();

    final query = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Search location"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: "Enter a place or address",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(
              context,
              controller.text.trim(),
            ),
            child: Text(
              "Search",
              style: TextStyle(color: scheme.primary),
            ),
          ),
        ],
      ),
    );

    if (query != null && query.isNotEmpty) {
      await _searchLocation(query);
    }
  }

  Future<void> _searchLocation(String query) async {
    try {
      final uri = Uri.parse(
        "https://nominatim.openstreetmap.org/search?format=json&limit=1&countrycodes=lb&q=${Uri.encodeComponent(query)}",
      );
      final response = await http.get(
        uri,
        headers: const {
          "User-Agent": "KifTari2-Mobile/1.0"
        },
      );
      if (response.statusCode != 200) {
        if (!mounted) return;
        _showSearchError("Search failed. Try again.");
        return;
      }
      final results = jsonDecode(response.body);
      if (results is! List || results.isEmpty) {
        if (!mounted) return;
        _showSearchError("No results found.");
        return;
      }
      final first = results.first;
      final lat = double.tryParse(first["lat"]?.toString() ?? "");
      final lon = double.tryParse(first["lon"]?.toString() ?? "");
      if (lat == null || lon == null) {
        if (!mounted) return;
        _showSearchError("No coordinates found.");
        return;
      }
      final target = LatLng(lat, lon);
      setState(() => _selectedLocation = target);
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(target, 16));
    } catch (_) {
      if (!mounted) return;
      _showSearchError("Search failed. Try again.");
    }
  }

  void _showSearchError(String message) {
    final scheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: scheme.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        backgroundColor: scheme.primary,
        title: Text(
          "Select Location",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: scheme.onPrimary,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _selectedLocation ?? const LatLng(0, 0),
                    zoom: 16,
                  ),
                  onMapCreated: (controller) {
                    _mapController = controller;
                  },
                  zoomControlsEnabled: true,
                  myLocationButtonEnabled: false,
                  onTap: (point) {
                    setState(() => _selectedLocation = point);
                  },
                  markers: _selectedLocation == null
                      ? {}
                      : {
                          Marker(
                            markerId: const MarkerId("selected"),
                            position: _selectedLocation!,
                          ),
                        },
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  top: 16,
                  child: Material(
                    borderRadius: BorderRadius.circular(14),
                    color: scheme.surface,
                    elevation: 2,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: _showLocationSearch,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.search, color: scheme.primary),
                            const SizedBox(width: 10),
                            Text(
                              "Search a location",
                              style: TextStyle(color: scheme.primary),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 20,
                  child: Column(
                    children: [
                      OutlinedButton(
                        onPressed: _resetToCurrent,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: scheme.primary),
                          backgroundColor: scheme.surface,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(
                          "Reset to my location",
                          style: TextStyle(color: scheme.primary),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _confirmLocation,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: scheme.primary,
                          ),
                          child: Text(
                            "Confirm Location",
                            style: TextStyle(
                              color: scheme.onPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
