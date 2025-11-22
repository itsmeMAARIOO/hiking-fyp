import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:hikingapp/presentation/styles/colors.dart';
import 'package:hikingapp/providers/map_provider.dart';
import '../../compass/compass_page.dart';

class MainMapWidget extends StatelessWidget {
  final MapController mapController;
  final LatLng mapCenter;
  final List<Marker> trailMarkers;
  final bool isLoading;
  final TextEditingController searchController;
  final VoidCallback onSearchButtonTap;
  final void Function(String) onSearchSubmit;
  final VoidCallback onClearSearch;
  final VoidCallback onMyLocation;

  const MainMapWidget({
    super.key,
    required this.mapController,
    required this.mapCenter,
    required this.trailMarkers,
    required this.isLoading,
    required this.searchController,
    required this.onSearchButtonTap,
    required this.onSearchSubmit,
    required this.onClearSearch,
    required this.onMyLocation,
  });

  @override
  Widget build(BuildContext context) {
    final mapProvider = Provider.of<MapProvider>(context);
    return Stack(
      children: [
        FlutterMap(
          mapController: mapController,
          options: MapOptions(
            center: mapCenter,
            zoom: 14,
            maxZoom: 18,
            minZoom: 3,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
              subdomains: const ['a', 'b', 'c'],
            ),
            if (mapProvider.currentLocation != null)
              MarkerLayer(
                markers: [
                  Marker(
                    width: 42,
                    height: 42,
                    point: LatLng(
                      mapProvider.currentLocation!['latitude']!,
                      mapProvider.currentLocation!['longitude']!,
                    ),
                    builder: (ctx) => const Icon(
                      Icons.my_location,
                      color: kFreshRed,
                      size: 28,
                    ),
                  ),
                ],
              ),
            if (trailMarkers.isNotEmpty) MarkerLayer(markers: trailMarkers),
          ],
        ),

        Positioned(
          top: 12,
          left: 12,
          right: 12,
          child: _buildSearchBox(context),
        ),

        if (isLoading)
          Positioned(
            bottom: 12,
            left: 12,
            right: 12,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 12),
                    Text('Finding nearby trails...'),
                  ],
                ),
              ),
            ),
          ),

        Positioned(
          bottom: 20,
          right: 20,
          child: Material(
            color: Colors.transparent,
            child: Ink(
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: kDeepTeal.withOpacity(0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.my_location, color: kFreshRed),
                onPressed: onMyLocation,
              ),
            ),
          ),
        ),

        Positioned(
          bottom: 20,
          left: 20,
          child: Material(
            color: Colors.transparent,
            child: Ink(
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: kDeepTeal.withOpacity(0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.explore_rounded, color: kDeepForest),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CompassPage()),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBox(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.only(left: 10, right: 6),
      decoration: BoxDecoration(
        color: kDeepForest.withOpacity(0.8),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [kDeepForest, kDeepTeal],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onSearchButtonTap,
                child: const Icon(Icons.search, color: Colors.white, size: 24),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: searchController,
              style: const TextStyle(color: kDeepTeal, fontSize: 16),
              textInputAction: TextInputAction.search,
              decoration: const InputDecoration(
                hintText: 'Search trails...',
                hintStyle: TextStyle(color: kDeepTeal),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 6,
                ),
              ),
              onSubmitted: onSearchSubmit,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.clear, size: 20),
            color: Colors.white.withOpacity(0.7),
            tooltip: 'Clear',
            onPressed: onClearSearch,
          ),
        ],
      ),
    );
  }
}
