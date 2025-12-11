import 'dart:async';
import 'dart:convert';
import 'package:hikingapp/utils/snackbar_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:get/get.dart';
import 'package:hikingapp/presentation/pages/map/offline/offline_area_picker_page.dart';
import 'package:hikingapp/core/constants/env.dart';
import 'package:hikingapp/providers/map_provider.dart';
import 'package:hikingapp/providers/auth_provider.dart';
import 'package:hikingapp/presentation/widgets/common_header.dart';
import 'package:hikingapp/presentation/styles/colors.dart';
import 'package:hikingapp/presentation/pages/dashboard/dashboard_controller.dart';
import 'package:hikingapp/services/checkin_service.dart';
import 'package:hikingapp/services/trail_services.dart';
import 'package:hikingapp/providers/dashboard_provider.dart';
import 'main_map/widgets/location_display.dart';
import 'main_map/widgets/trail_slide_card.dart';
import 'package:hikingapp/presentation/styles/app_styles.dart';
import 'main_map/widgets/main_map_widget.dart';
import 'main_map/widgets/trail_popup_card.dart';
import 'package:hikingapp/services/saved_trail_service.dart';

final String googleMapsApiKey = Env.googleMapsApiKey;

class Place {
  final String name;
  final double lat;
  final double lon;
  final double? rating;
  final String? photoReference;
  final String placeId;
  final List<String> types;
  double? routeKm;

  Place({
    required this.name,
    required this.lat,
    required this.lon,
    this.rating,
    this.photoReference,
    required this.placeId,
    required this.types,
    this.routeKm,
  });

  String? get photoUrl => photoReference == null
      ? null
      : 'https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photo_reference=$photoReference&key=$googleMapsApiKey';
}

/// Improved MapPage with better structure, debounce search, safer lifecycle handling,
/// improved bottom sheet and UX polish.
class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> with SingleTickerProviderStateMixin {
  late final MapController _mapController;
  late final DashboardController _dashboardController;
  late final TrailServices _trailService;

  final TextEditingController _searchController = TextEditingController();
  final PageController _pageController = PageController(viewportFraction: 0.88);

  List<Place> _places = [];
  bool _isLoading = false;
  bool _hasFetchedForLocation = false;
  bool _initialCentered = false;
  String? _errorMessage;

  LatLng _mapCenter = const LatLng(3.1390, 101.6869);

  // debounce for search
  Timer? _debounceTimer;

  // invitation state (kept from your original code)
  late AuthProvider _authProvider;
  String? _lastInviteId;
  final Map<String, double> _routeDistances = {};
  final Set<String> _routeRequested = {};

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _dashboardController = DashboardController(CheckInService());
    _trailService = TrailServices();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _authProvider = Provider.of<AuthProvider>(context, listen: false);

      final mapProvider = Provider.of<MapProvider>(context, listen: false);
      mapProvider.addListener(_onMapProviderChanged);

      // fetch immediate if provider already has location
      if (mapProvider.currentLocation != null) {
        _maybeCenterAndFetch(mapProvider.currentLocation!);
      }
    });

    _searchController.addListener(_onSearchChanged);
  }

  void _onMapProviderChanged() {
    final mapProvider = Provider.of<MapProvider>(context, listen: false);
    final loc = mapProvider.currentLocation;
    if (loc != null) {
      _maybeCenterAndFetch(loc);
    }
  }

  void _maybeCenterAndFetch(Map<String, double> loc) {
    if (!_initialCentered) {
      _initialCentered = true;
      final firstCenter = LatLng(loc['latitude']!, loc['longitude']!);
      _mapCenter = firstCenter;
      // small delay to ensure map is ready
      Future.microtask(() {
        if (mounted) _mapController.move(firstCenter, _mapController.zoom);
      });
    }
    if (!_hasFetchedForLocation) {
      _hasFetchedForLocation = true;
      _fetchNearbyTrails();
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _pageController.dispose();
    _buttonAnimationDisposeSafe();
    // do NOT call provider.dispose() — provider is owned by ancestor
    super.dispose();
  }

  // animation controller optional disposal helper (left safe if you add one)
  void _buttonAnimationDisposeSafe() {
    // placeholder if you later add controllers
  }

  // debounced search
  void _onSearchChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 550), () {
      // perform client-side filter OR re-run fetch with keyword
      final q = _searchController.text.trim();
      if (q.isEmpty) {
        // clear filters (show all fetched)
        if (mounted) setState(() => _errorMessage = null);
      } else {
        // try client-side filter for responsiveness
        _applyLocalFilter(q);
      }
    });
  }

  void _applyLocalFilter(String q) {
    final lower = q.toLowerCase();
    final filtered = _places
        .where((p) => p.name.toLowerCase().contains(lower))
        .toList();
    if (mounted) {
      setState(() {
        _errorMessage = null;
        // temporarily set _placesShown or reuse _places — here we'll replace displayed list
        _places = filtered;
      });
    }
  }

  Future<void> _fetchNearbyTrails({String? keyword}) async {
    final mapProvider = Provider.of<MapProvider>(context, listen: false);
    final loc = mapProvider.currentLocation;

    final online = Provider.of<DashboardProvider>(
      context,
      listen: false,
    ).isOnline;
    if (!online) {
      if (mounted) {
        setState(() {
          _errorMessage = _places.isNotEmpty
              ? null
              : 'Offline: nearby trails unavailable.';
          _isLoading = false;
        });
      }
      return;
    }

    if (loc == null) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Unable to get current location.';
        });
      }
      return;
    }

    // basic guard
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final lat = loc['latitude']!;
      final lon = loc['longitude']!;
      // Use Google Places Nearby Search for "park" and keyword fallback like your original strategy.
      final params = <String, String>{
        'location': '$lat,$lon',
        'radius': '15000',
        'type': 'park',
        'key': googleMapsApiKey,
      };
      if (keyword != null && keyword.trim().isNotEmpty) {
        params['keyword'] = keyword;
      } else {
        // default keywords to prefer hills / bukit etc
        params['keyword'] = 'bukit OR hill OR forest';
      }

      final uri = Uri.https(
        'maps.googleapis.com',
        '/maps/api/place/nearbysearch/json',
        params,
      );

      final resp = await http.get(uri).timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) {
        throw Exception('Places API returned ${resp.statusCode}');
      }

      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      if (data['status'] == 'ZERO_RESULTS' ||
          (data['results'] as List).isEmpty) {
        // No results — set empty
        if (mounted) {
          setState(() {
            _places = [];
            _errorMessage = 'No hiking spots found nearby.';
          });
        }
      } else {
        final List results = (data['results'] ?? []) as List;
        final items = results
            .map<Place?>((e) {
              try {
                final name = (e['name'] ?? '').toString();
                final rating = (e['rating'] as num?)?.toDouble();
                final photos = e['photos'] as List?;
                final photoRef = photos != null && photos.isNotEmpty
                    ? photos.first['photo_reference']?.toString()
                    : null;
                final placeId = (e['place_id'] ?? '').toString();
                final types =
                    (e['types'] as List?)?.map((t) => t.toString()).toList() ??
                    <String>[];
                final locObj =
                    e['geometry']?['location'] as Map<String, dynamic>?;
                final tlat = (locObj?['lat'] as num?)?.toDouble() ?? 0.0;
                final tlon = (locObj?['lng'] as num?)?.toDouble() ?? 0.0;
                if (name.isEmpty) return null;
                return Place(
                  name: name,
                  lat: tlat,
                  lon: tlon,
                  rating: rating,
                  photoReference: photoRef,
                  placeId: placeId,
                  types: types,
                );
              } catch (_) {
                return null;
              }
            })
            .whereType<Place>()
            .toList();

        if (mounted) {
          setState(() {
            _places = items;
          });
        }
      }

      // Optionally: Check invitations like your original code (kept)
      final userId = _authProvider.userId;
      if (userId != null) {
        final invitation = await _dashboardController.checkForInvitation(
          trailService: _trailService,
          userId: userId,
        );
        if (invitation != null) {
          final groupId = invitation['groupId'] ?? '';
          if (mounted) {
            setState(() {
              _lastInviteId = groupId.isNotEmpty ? groupId : _lastInviteId;
            });
          }
          await _dashboardController.notifyInvitationIfNew(
            lastInviteId: _lastInviteId,
            invitation: invitation,
          );
        }
      }
    } on TimeoutException {
      if (mounted) {
        setState(() => _errorMessage = 'Request timed out. Try again.');
      }
    } catch (e, st) {
      // keep friendly error log for dev & user
      debugPrint('Error fetching places: $e\n$st');
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to fetch nearby trails.';
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _onRefresh() async {
    // Attempt to re-initialize location tracking in case it failed or wasn't ready
    final mapProvider = Provider.of<MapProvider>(context, listen: false);
    await mapProvider.initLocationTracking();

    // clear search and re-fetch
    _searchController.clear();
    await _fetchNearbyTrails();
  }

  void _moveToLatLng(LatLng pos, {double zoom = 15}) {
    _mapCenter = pos;
    _mapController.move(pos, zoom);
  }

  Future<void> _openTrailSheet(Place t) async {
    final mapProvider = Provider.of<MapProvider>(context, listen: false);
    final loc = mapProvider.currentLocation;
    double km = 0;
    if (loc != null) {
      final cached = _routeDistances[t.placeId];
      if (cached != null) {
        km = cached;
      } else {
        km =
            Geolocator.distanceBetween(
              loc['latitude']!,
              loc['longitude']!,
              t.lat,
              t.lon,
            ) /
            1000.0;
        try {
          final rk = await _getRouteDistanceKm(
            loc['latitude']!,
            loc['longitude']!,
            t.lat,
            t.lon,
          );
          if (rk != null) {
            km = rk;
            _routeDistances[t.placeId] = rk;
          }
        } catch (_) {}
      }
    }
    bool isSaved = false;
    bool isSaving = false;
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final userId = auth.userId;
      if (userId != null) {
        final items = await SavedTrailService().fetchSavedTrails(userId);
        isSaved = items.any((e) => (e['placeId'] ?? '') == t.placeId);
      }
    } catch (_) {}

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: StatefulBuilder(
              builder: (ctx2, setState) {
                return TrailPopupCard(
                  name: t.name,
                  photoUrl: t.photoUrl,
                  rating: t.rating,
                  distanceKm: km,
                  isSaved: isSaved,
                  isSaving: isSaving,
                  onSave: () async {
                    final auth = Provider.of<AuthProvider>(
                      context,
                      listen: false,
                    );
                    final userId = auth.userId;
                    if (userId == null) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please log in to save trail'),
                          ),
                        );
                      }
                      return;
                    }
                    setState(() {
                      isSaving = true;
                    });
                    if (isSaved) {
                      await SavedTrailService().deleteSavedTrail(
                        userId,
                        t.placeId,
                      );
                      setState(() {
                        isSaved = false;
                      });
                    } else {
                      await _saveTrail(t);
                      setState(() {
                        isSaved = true;
                      });
                    }
                    setState(() {
                      isSaving = false;
                    });
                  },
                  onNavigate: () {
                    Navigator.of(ctx).pop();
                    _startHikeNavigation(t.lat, t.lon);
                  },
                  onOfflineMap: () {
                    Navigator.of(ctx).pop();
                    Get.to(
                      () => OfflineAreaPickerPage(
                        initialCenter: LatLng(t.lat, t.lon),
                        initialZoom: 13,
                        initialName: t.name,
                        areaRadiusKm: 2.0,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _saveTrail(Place t) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final userId = auth.userId;
    if (userId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to save trail')),
        );
      }
      return;
    }
    final payload = {
      'placeId': t.placeId,
      'name': t.name,
      'lat': t.lat,
      'lon': t.lon,
      'rating': t.rating,
      'photoReference': t.photoReference,
      'photoUrl': t.photoUrl,
      'types': t.types,
    };
    await SavedTrailService().saveTrail(userId, payload);
  }

  Future<void> _startHikeNavigation(double lat, double lon) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lon&travelmode=drive',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to open navigation.')),
        );
      }
    }
  }

  // compute human distance from current location (safe)
  String _distanceFromUserText(Place p) {
    final mapProvider = Provider.of<MapProvider>(context, listen: false);
    final loc = mapProvider.currentLocation;
    if (loc == null) return '- km';
    final cached = _routeDistances[p.placeId];
    if (cached != null) return '${cached.toStringAsFixed(2)} km';
    final meters = Geolocator.distanceBetween(
      loc['latitude']!,
      loc['longitude']!,
      p.lat,
      p.lon,
    );
    final km = meters / 1000.0;
    if (!_routeRequested.contains(p.placeId)) {
      _routeRequested.add(p.placeId);
      _getRouteDistanceKm(loc['latitude']!, loc['longitude']!, p.lat, p.lon)
          .then((rk) {
            if (rk != null) {
              _routeDistances[p.placeId] = rk;
              if (mounted) setState(() {});
            }
          })
          .catchError((_) {});
    }
    return '${km.toStringAsFixed(2)} km';
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
      'https://maps.googleapis.com/maps/api/directions/json?origin=$oLat,$oLon&destination=$dLat,$dLon&mode=driving&key=$key',
    );
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

  @override
  Widget build(BuildContext context) {
    final mapProvider = Provider.of<MapProvider>(context);
    final isOnline = Provider.of<DashboardProvider>(context).isOnline;
    final media = MediaQuery.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const AnimatedBackground(),
          // Saved Trails entry moved into the first pager card (_SwipeHintCard)
          SafeArea(
            child: RefreshIndicator(
              onRefresh: _onRefresh,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(child: CommonHeader(title: 'Explorer')),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: media.size.height * 0.62,
                      child: Column(
                        children: [
                          // const SizedBox(height: 8),
                          // const MapQuickActions(),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: LocationDisplay(
                              location:
                                  mapProvider.currentLocation ??
                                  {
                                    'latitude': 0.0,
                                    'longitude': 0.0,
                                    'altitude': 0.0,
                                    'accuracy': 0.0,
                                  },
                            ),
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  decoration: isOnline
                                      ? BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: kDeepTeal.withOpacity(
                                                0.08,
                                              ),
                                              blurRadius: 18,
                                              offset: const Offset(0, 8),
                                            ),
                                          ],
                                        )
                                      : BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              kSoftMint.withOpacity(0.3),
                                              Colors.white.withOpacity(0.4),
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          border: Border.all(
                                            color: Colors.white.withOpacity(
                                              0.6,
                                            ),
                                            width: 1.5,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: kDeepForest.withOpacity(
                                                0.08,
                                              ),
                                              blurRadius: 25,
                                              offset: const Offset(0, 10),
                                            ),
                                          ],
                                        ),
                                  child: isOnline
                                      ? MainMapWidget(
                                          mapController: _mapController,
                                          mapCenter: _mapCenter,
                                          trailMarkers: _places
                                              .map(
                                                (t) => Marker(
                                                  width: 36,
                                                  height: 36,
                                                  point: LatLng(t.lat, t.lon),
                                                  builder: (ctx) =>
                                                      GestureDetector(
                                                        onTap: () =>
                                                            _openTrailSheet(t),
                                                        child: const Icon(
                                                          Icons.terrain,
                                                          color: Colors.green,
                                                          size: 24,
                                                        ),
                                                      ),
                                                ),
                                              )
                                              .toList(),
                                          isLoading: _isLoading,
                                          searchController: _searchController,
                                          onSearchButtonTap: () {
                                            FocusScope.of(context).unfocus();
                                            _fetchNearbyTrails(
                                              keyword: _searchController.text,
                                            );
                                          },
                                          onSearchSubmit: (v) =>
                                              _fetchNearbyTrails(keyword: v),
                                          onClearSearch: () {
                                            _searchController.clear();
                                            _onRefresh();
                                          },
                                          onMyLocation: _moveToMyLocation,
                                        )
                                      : Center(
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 20,
                                              vertical: 16,
                                            ),
                                            margin: const EdgeInsets.symmetric(
                                              horizontal: 24,
                                            ),
                                            decoration: const BoxDecoration(
                                              color: Colors.transparent,
                                            ),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 14,
                                                        vertical: 10,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white
                                                        .withOpacity(0.6),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          24,
                                                        ),
                                                    border: Border.all(
                                                      color: Colors.white,
                                                      width: 1.5,
                                                    ),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: kDeepTeal
                                                            .withOpacity(0.06),
                                                        blurRadius: 12,
                                                        offset: const Offset(
                                                          0,
                                                          6,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: const [
                                                      Icon(
                                                        Icons.wifi_off_rounded,
                                                        color: kDeepForest,
                                                        size: 24,
                                                      ),
                                                      SizedBox(width: 10),
                                                      Text(
                                                        'No Connection',
                                                        style: TextStyle(
                                                          color: kDeepForest,
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.w800,
                                                          letterSpacing: -0.2,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(height: 10),
                                                const Padding(
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: 24,
                                                  ),
                                                  child: Text(
                                                    'Please try again later.',
                                                    style: TextStyle(
                                                      color: kDeepForest,
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // below map: card list / pager (show even when offline to allow cached items)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 0,
                        vertical: 14,
                      ),
                      child: _buildCardPager(mapProvider),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardPager(MapProvider mapProvider) {
    final isOnline = Provider.of<DashboardProvider>(context).isOnline;
    return TrailCardPager(
      controller: _pageController,
      itemCount: _places.length,
      isLoading: _isLoading,
      errorMessage: _errorMessage,
      onFirstCardShown: _moveToMyLocation,
      onPageChanged: (i) {
        final t = _places[i];
        _moveToLatLng(LatLng(t.lat, t.lon), zoom: 15);
      },
      itemBuilder: (ctx, i) {
        final t = _places[i];
        return TrailSlideCard(
          title: t.name,
          photoUrl: t.photoUrl,
          heroTag: t.placeId,
          rating: t.rating,
          distanceText: _distanceFromUserText(t),
          onTap: () => _openTrailSheet(t),
        );
      },
      showOnlyFirstCard: !isOnline,
    );
  }

  void _moveToMyLocation() {
    final mapProvider = Provider.of<MapProvider>(context, listen: false);
    final loc = mapProvider.currentLocation;
    if (loc == null) {
      SnackbarHelper.showError(
        'Location Error',
        'Current location not available.',
      );
      return;
    }
    final me = LatLng(loc['latitude']!, loc['longitude']!);
    _moveToLatLng(me, zoom: 16);
  }
}
