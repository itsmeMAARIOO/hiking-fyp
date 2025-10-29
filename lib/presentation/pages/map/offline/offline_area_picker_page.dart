import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:hikingapp/providers/auth_provider.dart';
import 'package:hikingapp/utils/snackbar_helper.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/widgets.dart' as pw;
import 'package:open_filex/open_filex.dart';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart' as pdf;

class OfflineAreaPickerPage extends StatefulWidget {
  const OfflineAreaPickerPage({super.key});

  @override
  State<OfflineAreaPickerPage> createState() => _OfflineAreaPickerPageState();
}

class _OfflineAreaPickerPageState extends State<OfflineAreaPickerPage> {
  final TextEditingController _nameCtrl = TextEditingController();
  final MapController _mapController = MapController();
  final List<LatLng> _pins = [];
  final double _maxZoom = 14;

  LatLng _center = const LatLng(3.1390, 101.6869); // Kuala Lumpur default

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _addPinAtCenter() {
    setState(() {
      _pins.add(_center);
    });
  }

  void _clearPins() {
    setState(() {
      _pins.clear();
    });
  }

  void _onPositionChanged(MapPosition pos, bool hasGesture) {
    setState(() {
      _center = pos.center ?? _center;
    });
  }

  Future<void> _exportPdf() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final userId = auth.userId;
    if (userId == null || userId.isEmpty) {
      SnackbarHelper.showError(
        'Login Required',
        'Please login before exporting',
      );
      return;
    }

    if (_pins.length < 4) {
      SnackbarHelper.showError('Add Pins', 'Please add 4 pins to define area');
      return;
    }

    final regionName = _nameCtrl.text.trim();
    if (regionName.isEmpty) {
      SnackbarHelper.showError('Region Name', 'Please provide a region name');
      return;
    }

    if (kIsWeb) {
      SnackbarHelper.showError(
        'Unsupported',
        'PDF export is not supported on Web',
      );
      return;
    }

    // Compute bounding box
    double neLat = _pins.map((p) => p.latitude).reduce((a, b) => a > b ? a : b);
    double neLng = _pins
        .map((p) => p.longitude)
        .reduce((a, b) => a > b ? a : b);
    double swLat = _pins.map((p) => p.latitude).reduce((a, b) => a < b ? a : b);
    double swLng = _pins
        .map((p) => p.longitude)
        .reduce((a, b) => a < b ? a : b);

    int lon2tileX(double lon, int z) =>
        ((lon + 180.0) / 360.0 * math.pow(2, z)).floor();
    int lat2tileY(double lat, int z) {
      final rad = lat * math.pi / 180.0;
      return ((1 - math.log(math.tan(rad) + 1 / math.cos(rad)) / math.pi) /
              2 *
              math.pow(2, z))
          .floor();
    }

    final z = _maxZoom.round();
    int xMin = lon2tileX(swLng, z);
    int xMax = lon2tileX(neLng, z);
    int yMin = lat2tileY(neLat, z);
    int yMax = lat2tileY(swLat, z);
    if (xMin > xMax) {
      final t = xMin;
      xMin = xMax;
      xMax = t;
    }
    if (yMin > yMax) {
      final t = yMin;
      yMin = yMax;
      yMax = t;
    }

    final tilesX = xMax - xMin + 1;
    final tilesY = yMax - yMin + 1;
    final totalTiles = tilesX * tilesY;

    if (totalTiles <= 0) {
      SnackbarHelper.showError(
        'Invalid Area',
        'Could not compute tiles for area',
      );
      return;
    }
    if (totalTiles > 400) {
      SnackbarHelper.showError(
        'Too Large',
        'Area too large for PDF at this zoom; reduce max zoom or area',
      );
      return;
    }

    try {
      SnackbarHelper.showSuccess(
        'Export Started',
        'Fetching $totalTiles tiles for PDF...',
      );

      // Collect tiles to compose directly in PDF without image compositing
      final List<Map<String, dynamic>> tiles = [];

      int downloaded = 0;
      for (int xi = 0; xi < tilesX; xi++) {
        final x = xMin + xi;
        for (int yi = 0; yi < tilesY; yi++) {
          final y = yMin + yi;
          final tileUrl = Uri.parse(
            'https://tile.openstreetmap.org/$z/$x/$y.png',
          );
          try {
            final res = await http.get(
              tileUrl,
              headers: {'User-Agent': 'com.example.hikingapp'},
            );
            if (res.statusCode == 200) {
              tiles.add({'x': xi, 'y': yi, 'bytes': res.bodyBytes});
            }
          } catch (_) {
            // continue
          }
          downloaded++;
          if (downloaded % 40 == 0 || downloaded == totalTiles) {
            SnackbarHelper.showSuccess(
              'Progress',
              '$downloaded / $totalTiles tiles',
            );
          }
        }
      }

      final doc = pw.Document();
      doc.addPage(
        pw.Page(
          pageFormat: pdf.PdfPageFormat.a4,
          build: (ctx) {
            final children = tiles
                .map(
                  (t) => pw.Positioned(
                    left: (t['x'] as int) * 256.0,
                    top: (t['y'] as int) * 256.0,
                    child: pw.Image(
                      pw.MemoryImage(t['bytes'] as Uint8List),
                      width: 256,
                      height: 256,
                    ),
                  ),
                )
                .toList();
            return pw.Center(
              child: pw.FittedBox(
                fit: pw.BoxFit.contain,
                child: pw.Container(
                  width: tilesX * 256.0,
                  height: tilesY * 256.0,
                  child: pw.Stack(children: children),
                ),
              ),
            );
          },
        ),
      );

      final external = await getExternalStorageDirectory();
      final base = external ?? await getApplicationDocumentsDirectory();
      final outDir = Directory('${base.path}/offline_pdfs');
      await outDir.create(recursive: true);
      final safeName = regionName.replaceAll(RegExp(r'[^A-Za-z0-9_\-]'), '_');
      final filePath =
          '${outDir.path}/${safeName}_${DateTime.now().toIso8601String().replaceAll(':', '-')}.pdf';
      final outFile = File(filePath);
      await outFile.writeAsBytes(await doc.save());

      SnackbarHelper.showSuccess('PDF Saved', filePath);

      // Try opening the file with the default viewer
      try {
        await OpenFilex.open(filePath);
      } catch (_) {}
    } catch (e) {
      SnackbarHelper.showError('Export Error', e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pick Offline Area')),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    center: _center,
                    zoom: 12,
                    onPositionChanged: _onPositionChanged,
                  ),
                  children: [
                    // Use OSM tiles for selection UI (no token needed)
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.hikingapp',
                    ),
                    MarkerLayer(
                      markers: _pins
                          .map(
                            (p) => Marker(
                              point: p,
                              width: 40,
                              height: 40,
                              anchorPos: AnchorPos.align(AnchorAlign.center),
                              builder: (context) => const Icon(
                                Icons.location_on,
                                color: Colors.red,
                              ),
                            ),
                          )
                          .toList(growable: false),
                    ),
                  ],
                ),
                // Center crosshair
                const IgnorePointer(
                  child: Center(
                    child: Icon(
                      Icons.add_location_alt,
                      size: 32,
                      color: Colors.blueAccent,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Region Name',
                    hintText: 'e.g. Bukit Kiara',
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _addPinAtCenter,
                      icon: const Icon(Icons.add_location),
                      label: const Text('Add Pin'),
                    ),
                    Text('Pins: ${_pins.length}/4'),
                    TextButton.icon(
                      onPressed: _clearPins,
                      icon: const Icon(Icons.clear),
                      label: const Text('Clear'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _exportPdf,
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text('Export PDF'),
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
