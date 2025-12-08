import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:latlong2/latlong.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

// Project Imports
import 'package:hikingapp/providers/auth_provider.dart';
import 'package:hikingapp/providers/map_provider.dart';
import 'package:hikingapp/services/saved_trail_service.dart';
import 'package:hikingapp/presentation/styles/colors.dart';
import 'package:hikingapp/core/constants/env.dart';
import 'package:hikingapp/presentation/pages/map/offline/offline_area_picker_page.dart';
import 'package:hikingapp/presentation/pages/map/main_map/widgets/trail_popup_card.dart';

class SavedTrailsPage extends StatefulWidget {
  const SavedTrailsPage({super.key});

  @override
  State<SavedTrailsPage> createState() => _SavedTrailsPageState();
}

class _SavedTrailsPageState extends State<SavedTrailsPage> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _error;
  final Map<String, double> _routeDistances = {};
  final Set<String> _routeRequested = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final userId = auth.userId;
    if (userId == null) {
      setState(() {
        _items = [];
        _loading = false;
        _error = 'Not logged in';
      });
      return;
    }
    try {
      final items = await SavedTrailService().fetchSavedTrails(userId);
      setState(() {
        _items = items;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Failed to load';
      });
    }
  }

  Future<void> _deleteTrail(int index, String placeId) async {
    // Optimistically remove from UI
    final deletedItem = _items[index];
    setState(() {
      _items.removeAt(index);
    });

    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.userId != null) {
      await SavedTrailService().deleteSavedTrail(auth.userId!, placeId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: kLightCream,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: kLightCream,

        // Floating Back Button (Bottom Left)
        floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 16, left: 8),
          child: FloatingActionButton(
            onPressed: () => Navigator.pop(context),
            backgroundColor: Colors.white,
            foregroundColor: kDeepForest,
            elevation: 4,
            shape: const CircleBorder(),
            child: const Icon(Icons.arrow_back_rounded),
          ),
        ),

        body: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // --- 1. HEADER ---
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(24, 30, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Your Collection",
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          color: kDeepForest,
                          letterSpacing: -1.0,
                          height: 1.1,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "Swipe left to remove items",
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // --- 2. CONTENT ---
              _buildContentSliver(),

              // Padding for FAB
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContentSliver() {
    if (_loading) {
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator(color: kDeepTeal)),
      );
    }
    if (_error != null) {
      return SliverFillRemaining(
        child: Center(
          child: Text(_error!, style: const TextStyle(color: Colors.grey)),
        ),
      );
    }
    if (_items.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.landscape_outlined, size: 80, color: Colors.grey[300]),
              const SizedBox(height: 16),
              Text(
                'Your collection is empty',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Save trails to see them here',
                style: TextStyle(color: Colors.grey[400], fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    // --- 3. CINEMATIC LIST (SliverList) ---
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final item = _items[index];
          final placeId = (item['placeId'] ?? '').toString();

          return Padding(
            padding: const EdgeInsets.only(bottom: 20), // Spacing between cards
            child: _buildSwipeableCard(item, index, placeId),
          );
        }, childCount: _items.length),
      ),
    );
  }

  Widget _buildSwipeableCard(
    Map<String, dynamic> t,
    int index,
    String placeId,
  ) {
    return Dismissible(
      key: Key(placeId),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) => _deleteTrail(index, placeId),
      background: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFFEBEB), // Soft Red bg
          borderRadius: BorderRadius.circular(24),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 30),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_outline_rounded, color: Colors.red, size: 30),
            SizedBox(height: 4),
            Text(
              "Delete",
              style: TextStyle(
                color: Colors.red,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      child: _buildCinematicCard(t),
    );
  }

  Widget _buildCinematicCard(Map<String, dynamic> t) {
    // --- Data Prep ---
    final name = (t['name'] ?? 'Unnamed Trail').toString();
    final ratingRaw = t['rating'];
    final rating = ratingRaw is num ? ratingRaw.toDouble() : null;

    final photoRef = (t['photoReference'] ?? '').toString();
    final img = (t['imageUrl'] ?? '').toString();
    String? photoUrl;
    if (img.isNotEmpty)
      photoUrl = img;
    else if (photoRef.isNotEmpty) {
      photoUrl =
          'https://maps.googleapis.com/maps/api/place/photo?maxwidth=600&photo_reference=$photoRef&key=${Env.googleMapsApiKey}';
    }

    // Calculate Distance
    double km = 0.0;
    final lat = (t['lat'] as num? ?? 0.0).toDouble();
    final lon = (t['lon'] as num? ?? 0.0).toDouble();
    final placeId = (t['placeId'] ?? '').toString();
    final mp = Provider.of<MapProvider>(context, listen: false);
    if (mp.currentLocation != null) {
      final cached = _routeDistances[placeId];
      if (cached != null) {
        km = cached;
      } else {
        km =
            Geolocator.distanceBetween(
              mp.currentLocation!['latitude']!,
              mp.currentLocation!['longitude']!,
              lat,
              lon,
            ) /
            1000.0;
        if (!_routeRequested.contains(placeId)) {
          _routeRequested.add(placeId);
          _getRouteDistanceKm(
            mp.currentLocation!['latitude']!,
            mp.currentLocation!['longitude']!,
            lat,
            lon,
          ).then((rk) {
            if (rk != null) {
              _routeDistances[placeId] = rk;
              if (mounted) setState(() {});
            }
          }).catchError((_) {});
        }
      }
    }

    return GestureDetector(
      onTap: () => _handleTap(t, name, rating, photoUrl, km, lat, lon),
      child: Container(
        height: 220, // Big, immersive height
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // 1. Background Image
              Positioned.fill(
                child: photoUrl != null
                    ? Image.network(
                        photoUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildFallbackGradient(),
                      )
                    : _buildFallbackGradient(),
              ),

              // 2. Gradient Overlay (For text readability)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.1),
                        Colors.black.withOpacity(0.8),
                      ],
                      stops: const [0.4, 0.6, 1.0],
                    ),
                  ),
                ),
              ),

              // 3. Top Right Badge (Rating)
              if (rating != null)
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: Colors.amber,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          rating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: kDeepTeal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // 4. Bottom Content
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(
                                  Icons.directions_walk,
                                  color: Colors.white70,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${km.toStringAsFixed(1)} km away',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Action Button (Navigate Icon)
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: kDeepTeal,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: kDeepTeal.withOpacity(0.4),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.near_me_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackGradient() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFE66465), // Matching previous design theme
            Color(0xFF9198E5),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.landscape_rounded,
          color: Colors.white.withOpacity(0.5),
          size: 60,
        ),
      ),
    );
  }

  void _handleTap(
    Map<String, dynamic> t,
    String name,
    double? rating,
    String? photoUrl,
    double km,
    double lat,
    double lon,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => TrailPopupCard(
        name: name,
        photoUrl: photoUrl,
        rating: rating,
        distanceKm: km,
        onNavigate: () => _launchMaps(lat, lon),
        onOfflineMap: () {
          Navigator.pop(ctx);
          Get.to(
            () => OfflineAreaPickerPage(
              initialCenter: LatLng(lat, lon),
              initialZoom: 13,
              initialName: name,
              areaRadiusKm: 2.0,
            ),
          );
        },
      ),
    );
  }

  Future<double?> _getRouteDistanceKm(
    double oLat,
    double oLon,
    double dLat,
    double dLon,
  ) async {
    final key = Env.googleMapsApiKey;
    if (key.isEmpty) return null;
    final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/directions/json?origin=$oLat,$oLon&destination=$dLat,$dLon&mode=driving&key=$key');
    final resp = await http.get(url).timeout(const Duration(seconds: 10));
    if (resp.statusCode != 200) return null;
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final routes = data['routes'] as List?;
    if (routes == null || routes.isEmpty) return null;
    final legs = routes.first['legs'] as List?;
    if (legs == null || legs.isEmpty) return null;
    final dist = (legs.first['distance']?['value']) as num?;
    if (dist == null) return null;
    return dist.toDouble() / 1000.0;
  }

  Future<void> _launchMaps(double lat, double lon) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lon&travelmode=drive',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
