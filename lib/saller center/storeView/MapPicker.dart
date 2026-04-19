import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';

class MapPickerScreen extends StatefulWidget {
  const MapPickerScreen({super.key});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {

  LatLng selected = LatLng(31.5204, 74.3587);
  String address = "";

  Future<void> _getAddress(LatLng pos) async {
    try {
      List<Placemark> place =
      await placemarkFromCoordinates(pos.latitude, pos.longitude);

      final p = place.first;

      setState(() {
        address = "${p.street}, ${p.locality}, ${p.country}";
      });
    } catch (e) {
      address = "Address not found";
    }
  }

  void _confirm() {
    Navigator.pop(context, {
      "lat": selected.latitude,
      "lng": selected.longitude,
      "address": address
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Pick Location")),

      body: Stack(
        children: [

          FlutterMap(
            options: MapOptions(
              initialCenter: selected,
              initialZoom: 14,
              onTap: (tapPosition, point) {
                setState(() {
                  selected = point;
                });
                _getAddress(point);
              },
            ),

            children: [

              TileLayer(
                urlTemplate:
                "https://basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png",
                userAgentPackageName: "com.example.zrai_mart",
              ),

              MarkerLayer(
                markers: [
                  Marker(
                    point: selected,
                    width: 50,
                    height: 50,
                    child: const Icon(
                      Icons.location_pin,
                      color: Colors.red,
                      size: 40,
                    ),
                  )
                ],
              ),

            ],
          ),

          if (address.isNotEmpty)
            Positioned(
              bottom: 90,
              left: 15,
              right: 15,
              child: Container(
                padding: const EdgeInsets.all(12),
                color: Colors.white,
                child: Text(address),
              ),
            ),

          Positioned(
            bottom: 20,
            left: 15,
            right: 15,
            child: ElevatedButton(
              onPressed: _confirm,
              child: const Text("Confirm Location"),
            ),
          )

        ],
      ),
    );
  }
}