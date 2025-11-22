import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:hikingapp/providers/auth_provider.dart';
import 'package:hikingapp/utils/snackbar_helper.dart';
import 'package:hikingapp/presentation/styles/colors.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/widgets.dart' as pw;
import 'package:open_filex/open_filex.dart';
import 'dart:io' if (dart.library.html) 'package:hikingapp/utils/io_stub.dart';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart' as pdf;

class OfflineAreaPickerPage extends StatefulWidget {
  final LatLng? initialCenter;
  final double? initialZoom;
  final String? initialName;
  final double? areaRadiusKm;
  const OfflineAreaPickerPage({
    super.key,
    this.initialCenter,
    this.initialZoom,
    this.initialName,
    this.areaRadiusKm,
  });

  @override
  State<OfflineAreaPickerPage> createState() => _OfflineAreaPickerPageState();
}

class _OfflineAreaPickerPageState extends State<OfflineAreaPickerPage> {
  final TextEditingController _nameCtrl = TextEditingController();
  final MapController _mapController = MapController();
  final GlobalKey _mapKey = GlobalKey();
  double _zoom = 12.0;
  double _radiusKm = 2.0;
  LatLng _center = const LatLng(3.1390, 101.6869);
  bool _isExporting = false; // Added loading state for UX

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialCenter != null) {
      _center = widget.initialCenter!;
    }
    if (widget.initialZoom != null) {
      _zoom = widget.initialZoom!;
    }
    if (widget.initialName != null && widget.initialName!.isNotEmpty) {
      _nameCtrl.text = widget.initialName!;
    }
    if (widget.areaRadiusKm != null && widget.areaRadiusKm! > 0) {
      _radiusKm = widget.areaRadiusKm!;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _adjustZoomForTargetArea();
    });
  }

  void _adjustZoomForTargetArea() {
    final box = _mapKey.currentContext?.findRenderObject() as RenderBox?;
    final size = box?.size;
    if (size == null) {
      _mapController.move(_center, _zoom);
      return;
    }
    final widthPx = size.width;
    final targetWidthMeters = _radiusKm * 2 * 1000.0;
    final metersPerPixelTarget = targetWidthMeters / widthPx;
    final phi = _center.latitude * math.pi / 180.0;
    final earthCircumference = 2 * math.pi * 6378137.0;
    final zoomDouble =
        math.log(
          (math.cos(phi) * earthCircumference) / (256.0 * metersPerPixelTarget),
        ) /
        math.ln2;
    _zoom = zoomDouble.clamp(0.0, 19.0);
    _mapController.move(_center, _zoom);
  }

  void _onPositionChanged(MapPosition pos, bool hasGesture) {
    final c = pos.center;
    final z = pos.zoom;
    if (c != null || z != null) {
      setState(() {
        if (c != null) _center = c;
        if (z != null) _zoom = z;
      });
    }
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

    final box = _mapKey.currentContext?.findRenderObject() as RenderBox?;
    final size = box?.size;
    if (size == null) {
      SnackbarHelper.showError('Export Error', 'Map size unavailable');
      return;
    }

    setState(() => _isExporting = true); // Start loading UI

    final z = _zoom.round().clamp(0, 19);
    double world(int zoom) => 256.0 * math.pow(2, zoom).toDouble();
    double lon2x(double lon, int zoom) => (lon + 180.0) / 360.0 * world(zoom);
    double lat2y(double lat, int zoom) {
      final rad = lat * math.pi / 180.0;
      return (1 - math.log(math.tan(rad) + 1 / math.cos(rad)) / math.pi) /
          2 *
          world(zoom);
    }

    final cx = lon2x(_center.longitude, z);
    final cy = lat2y(_center.latitude, z);
    final halfW = size.width / 2.0;
    final halfH = size.height / 2.0;
    final leftPx = cx - halfW;
    final rightPx = cx + halfW;
    final topPx = cy - halfH;
    final bottomPx = cy + halfH;

    final leftTile = (leftPx / 256.0).floor();
    final rightTile = ((rightPx - 1) / 256.0).floor();
    final topTile = (topPx / 256.0).floor();
    final bottomTile = ((bottomPx - 1) / 256.0).floor();

    final offsetX = -(leftPx - leftTile * 256.0);
    final offsetY = -(topPx - topTile * 256.0);

    final tilesX = rightTile - leftTile + 1;
    final tilesY = bottomTile - topTile + 1;
    final totalTiles = tilesX * tilesY;

    if (totalTiles <= 0) {
      SnackbarHelper.showError(
        'Invalid Area',
        'Could not compute tiles for area',
      );
      setState(() => _isExporting = false);
      return;
    }
    if (totalTiles > 400) {
      SnackbarHelper.showError(
        'Too Large',
        'Area too large for PDF at this zoom; reduce max zoom or area',
      );
      setState(() => _isExporting = false);
      return;
    }

    try {
      // Collect tiles
      final List<Map<String, dynamic>> tiles = [];
      int downloaded = 0;

      for (int xi = 0; xi < tilesX; xi++) {
        final x = leftTile + xi;
        for (int yi = 0; yi < tilesY; yi++) {
          final y = topTile + yi;
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
          } catch (_) {}
          downloaded++;
        }
      }

      final doc = pw.Document();
      doc.addPage(
        pw.Page(
          pageFormat: pdf.PdfPageFormat(size.width, size.height, marginAll: 0),
          build: (ctx) {
            final children = tiles
                .map(
                  (t) => pw.Positioned(
                    left: offsetX + (t['x'] as int) * 256.0,
                    top: offsetY + (t['y'] as int) * 256.0,
                    child: pw.Image(
                      pw.MemoryImage(t['bytes'] as Uint8List),
                      width: 256,
                      height: 256,
                    ),
                  ),
                )
                .toList();
            return pw.Container(
              width: size.width,
              height: size.height,
              child: pw.Stack(children: children),
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

      SnackbarHelper.showSuccess(
        'PDF Saved',
        'Saved to Documents/offline_pdfs',
      );
      try {
        await OpenFilex.open(filePath);
      } catch (_) {}
    } catch (e) {
      SnackbarHelper.showError('Export Error', e.toString());
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Improved Map Style (CartoDB for cleaner look)

    return Scaffold(
      backgroundColor: kLightCream,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          statusBarColor: kLightCream,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
        child: SafeArea(
          child: Column(
            children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: kLightCream,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: kDeepTeal.withOpacity(0.12),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: FlutterMap(
                        key: _mapKey,
                        mapController: _mapController,
                        options: MapOptions(
                          center: _center,
                          zoom: _zoom,
                          onPositionChanged: _onPositionChanged,
                          interactiveFlags: InteractiveFlag.pinchZoom |
                              InteractiveFlag.drag |
                              InteractiveFlag.doubleTapZoom,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.example.hikingapp',
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      top: 10,
                      left: 10,
                      child: CircleAvatar(
                        backgroundColor: Colors.white,
                        radius: 22,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back, color: kDeepTeal),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Save Offline Map",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _nameCtrl.text.isNotEmpty
                          ? _nameCtrl.text
                          : 'Selected Area',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: kDeepTeal,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isExporting ? null : _exportPdf,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kDeepTeal,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: _isExporting
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.download_rounded,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    "Download PDF Map",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
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
          ],
          ),
        ),
      ),
    );
  }
}
