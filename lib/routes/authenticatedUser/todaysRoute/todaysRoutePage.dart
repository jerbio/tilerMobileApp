import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/routes/authenticatedUser/editTile/editTile.dart';
import 'package:tiler_app/theme/tile_theme_extension.dart';
import 'package:tiler_app/theme/tile_colors.dart';
import 'package:url_launcher/url_launcher.dart';

/// A stop in the day's route with its associated tile
class RouteStop {
  final int order;
  final SubCalendarEvent tile;
  final LatLng? location;
  final String label;
  final Duration? travelTimeFromPrevious;
  final String? travelMode; // 'drive', 'walk', 'transit'

  RouteStop({
    required this.order,
    required this.tile,
    this.location,
    required this.label,
    this.travelTimeFromPrevious,
    this.travelMode,
  });
}

/// Page showing today's route on a map with all tile locations
class TodaysRoutePage extends StatefulWidget {
  final List<SubCalendarEvent> tiles;
  final String? optimizationMessage;
  final Duration? timeSaved;

  const TodaysRoutePage({
    Key? key,
    required this.tiles,
    this.optimizationMessage,
    this.timeSaved,
  }) : super(key: key);

  @override
  State<TodaysRoutePage> createState() => _TodaysRoutePageState();
}

class _TodaysRoutePageState extends State<TodaysRoutePage> {
  GoogleMapController? _mapController;
  List<RouteStop> _routeStops = [];
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  bool _isLoading = true;
  bool _isInitialized = false;
  int? _selectedStopIndex;
  LatLng? _initialPosition;
  double _initialZoom = 13.0;
  LatLngBounds? _routeBounds;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Only process once after context is available
    if (!_isInitialized) {
      _isInitialized = true;
      _processRouteStops();
    }
  }

  void _processRouteStops() {
    // Filter tiles with valid locations and sort by start time
    final tilesWithLocations = widget.tiles
        .where((tile) => _getLatLngFromTile(tile) != null)
        .toList()
      ..sort((a, b) => (a.start ?? 0).compareTo(b.start ?? 0));

    // Create route stops
    _routeStops = [];
    for (int i = 0; i < tilesWithLocations.length; i++) {
      final tile = tilesWithLocations[i];
      final latLng = _getLatLngFromTile(tile);

      Duration? travelTime;
      String? travelMode;

      // Get travel time from tile's travel detail if available
      if (tile.travelTimeBefore != null && tile.travelTimeBefore! > 0) {
        travelTime = Duration(minutes: tile.travelTimeBefore!.toInt());
        travelMode = 'drive'; // Default assumption
      }

      _routeStops.add(RouteStop(
        order: i + 1,
        tile: tile,
        location: latLng,
        label:
            tile.name ?? AppLocalizations.of(context)?.untitledTile ?? 'Tile',
        travelTimeFromPrevious: travelTime,
        travelMode: travelMode,
      ));
    }

    // Set initial position and calculate bounds
    _calculateInitialCameraPosition();

    // Build markers and polylines
    _buildMarkersAndPolylines();

    setState(() {
      _isLoading = false;
    });
  }

  /// Calculate initial camera position and zoom to fit all locations
  void _calculateInitialCameraPosition() {
    final locations = _routeStops
        .where((s) => s.location != null)
        .map((s) => s.location!)
        .toList();

    if (locations.isEmpty) {
      _initialPosition = const LatLng(37.7749, -122.4194); // Default SF
      _initialZoom = 13.0;
      return;
    }

    if (locations.length == 1) {
      _initialPosition = locations.first;
      _initialZoom = 15.0; // Closer zoom for single location
      return;
    }

    // Calculate bounds
    double minLat = locations.first.latitude;
    double maxLat = locations.first.latitude;
    double minLng = locations.first.longitude;
    double maxLng = locations.first.longitude;

    for (final loc in locations) {
      if (loc.latitude < minLat) minLat = loc.latitude;
      if (loc.latitude > maxLat) maxLat = loc.latitude;
      if (loc.longitude < minLng) minLng = loc.longitude;
      if (loc.longitude > maxLng) maxLng = loc.longitude;
    }

    // Store bounds for later use
    _routeBounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    // Calculate center point
    _initialPosition = LatLng(
      (minLat + maxLat) / 2,
      (minLng + maxLng) / 2,
    );

    // Calculate appropriate zoom level based on the span
    final latSpan = maxLat - minLat;
    final lngSpan = maxLng - minLng;
    final maxSpan = latSpan > lngSpan ? latSpan : lngSpan;

    // Approximate zoom calculation
    // At zoom 0, the world is ~360 degrees wide
    // Each zoom level halves the viewable area
    // We add padding factor to ensure markers are visible
    if (maxSpan <= 0.001) {
      _initialZoom = 17.0; // Very close locations
    } else if (maxSpan <= 0.005) {
      _initialZoom = 16.0;
    } else if (maxSpan <= 0.01) {
      _initialZoom = 15.0;
    } else if (maxSpan <= 0.02) {
      _initialZoom = 14.0;
    } else if (maxSpan <= 0.05) {
      _initialZoom = 13.0;
    } else if (maxSpan <= 0.1) {
      _initialZoom = 12.0;
    } else if (maxSpan <= 0.2) {
      _initialZoom = 11.0;
    } else if (maxSpan <= 0.5) {
      _initialZoom = 10.0;
    } else if (maxSpan <= 1.0) {
      _initialZoom = 9.0;
    } else if (maxSpan <= 2.0) {
      _initialZoom = 8.0;
    } else {
      _initialZoom = 7.0;
    }

    // Reduce zoom slightly to add padding
    _initialZoom = _initialZoom - 0.5;
  }

  LatLng? _getLatLngFromTile(SubCalendarEvent tile) {
    // Try to get location from tile's location object
    if (tile.location != null) {
      final loc = tile.location!;
      if (loc.latitude != null &&
          loc.longitude != null &&
          loc.isNotNullAndNotDefault) {
        return LatLng(loc.latitude!, loc.longitude!);
      }
    }

    // Try endLocation from travel detail's before data
    if (tile.travelDetail?.before?.endLocation != null) {
      final endLoc = tile.travelDetail!.before!.endLocation!;
      if (endLoc.latitude != null &&
          endLoc.longitude != null &&
          endLoc.isNotNullAndNotDefault) {
        return LatLng(endLoc.latitude!, endLoc.longitude!);
      }
    }

    return null;
  }

  void _buildMarkersAndPolylines() {
    _markers = {};
    _polylines = {};

    // Create markers for each stop
    for (int i = 0; i < _routeStops.length; i++) {
      final stop = _routeStops[i];
      if (stop.location == null) continue;

      // Get tile color for marker
      final tile = stop.tile;
      final tileColor = Color.fromRGBO(
        tile.colorRed ?? 127,
        tile.colorGreen ?? 127,
        tile.colorBlue ?? 127,
        1,
      );

      _markers.add(Marker(
        markerId: MarkerId('stop_${stop.order}'),
        position: stop.location!,
        infoWindow: InfoWindow(
          title: '${stop.order}. ${stop.label}',
          snippet: _formatTimeRange(tile),
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          _colorToHue(tileColor),
        ),
        onTap: () {
          setState(() {
            _selectedStopIndex = i;
          });
        },
      ));
    }

    // Create polylines connecting stops
    if (_routeStops.length > 1) {
      List<LatLng> routePoints = _routeStops
          .where((s) => s.location != null)
          .map((s) => s.location!)
          .toList();

      if (routePoints.length > 1) {
        _polylines.add(Polyline(
          polylineId: const PolylineId('main_route'),
          points: routePoints,
          width: 4,
          color: TileColors.bluePolyline,
          patterns: [PatternItem.dash(20), PatternItem.gap(10)],
        ));
      }
    }
  }

  double _colorToHue(Color color) {
    final hsl = HSLColor.fromColor(color);
    return hsl.hue;
  }

  String _formatTimeRange(SubCalendarEvent tile) {
    final startTime = tile.startTime;
    final endTime = tile.endTime;
    final start = TimeOfDay.fromDateTime(startTime);
    final end = TimeOfDay.fromDateTime(endTime);
    return '${start.format(context)} - ${end.format(context)}';
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      final minutes = duration.inMinutes.remainder(60);
      if (minutes > 0) {
        return '${duration.inHours}h ${minutes}m';
      }
      return '${duration.inHours}h';
    }
    return '${duration.inMinutes} min';
  }

  /// Check if the selected stop has a valid navigable location
  bool _hasValidNavigableLocation(RouteStop? stop) {
    if (stop == null) return false;

    // Check if we have valid coordinates
    if (stop.location != null) return true;

    // Check if we have an address to navigate to
    final tile = stop.tile;
    if (tile.addressDescription != null && tile.addressDescription!.isNotEmpty)
      return true;
    if (tile.address != null && tile.address!.isNotEmpty) return true;

    return false;
  }

  Future<void> _startNavigation() async {
    if (_selectedStopIndex == null || _routeStops.isEmpty) return;

    final stop = _routeStops[_selectedStopIndex!];
    final tile = stop.tile;

    Uri? url;

    // Try coordinates first
    if (stop.location != null) {
      final lat = stop.location!.latitude;
      final lng = stop.location!.longitude;
      url = Uri.parse(
          'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving');
    }
    // Fall back to address
    else if (tile.addressDescription != null &&
        tile.addressDescription!.isNotEmpty) {
      final encodedAddress = Uri.encodeComponent(tile.addressDescription!);
      url = Uri.parse(
          'https://www.google.com/maps/dir/?api=1&destination=$encodedAddress&travelmode=driving');
    } else if (tile.address != null && tile.address!.isNotEmpty) {
      final encodedAddress = Uri.encodeComponent(tile.address!);
      url = Uri.parse(
          'https://www.google.com/maps/dir/?api=1&destination=$encodedAddress&travelmode=driving');
    }

    if (url == null) {
      // Show snackbar that navigation is not available
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n?.noLocationAvailable ??
                'No location available for navigation'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  void _fitMapToRoute() {
    if (_mapController == null || _routeStops.isEmpty) return;

    final locations =
        _routeStops.where((s) => s.location != null).map((s) => s.location!);
    if (locations.isEmpty) return;

    double minLat = locations.first.latitude;
    double maxLat = locations.first.latitude;
    double minLng = locations.first.longitude;
    double maxLng = locations.first.longitude;

    for (final loc in locations) {
      if (loc.latitude < minLat) minLat = loc.latitude;
      if (loc.latitude > maxLat) maxLat = loc.latitude;
      if (loc.longitude < minLng) minLng = loc.longitude;
      if (loc.longitude > maxLng) maxLng = loc.longitude;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 80),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _routeStops.isEmpty
              ? _buildEmptyState(l10n, colorScheme)
              : _buildRouteView(colorScheme, l10n),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n, ColorScheme colorScheme) {
    return SafeArea(
      child: Column(
        children: [
          _buildHeader(colorScheme, l10n),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.location_off_rounded,
                    size: 64,
                    color: colorScheme.onSurface.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.noLocationsToday,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.addLocationsToSeeTodaysRoute,
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurface.withOpacity(0.4),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteView(ColorScheme colorScheme, AppLocalizations l10n) {
    return Stack(
      children: [
        // Map
        GoogleMap(
          style: Theme.of(context).extension<TileThemeExtension>()?.mapStyle,
          initialCameraPosition: CameraPosition(
            target: _initialPosition ?? const LatLng(37.7749, -122.4194),
            zoom: _initialZoom,
          ),
          markers: _markers,
          polylines: _polylines,
          onMapCreated: (controller) {
            _mapController = controller;
            // Fit map to show all stops after a brief delay
            Future.delayed(const Duration(milliseconds: 500), _fitMapToRoute);
          },
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
            Factory<OneSequenceGestureRecognizer>(
              () => EagerGestureRecognizer(),
            ),
          },
        ),

        // Header overlay
        SafeArea(
          child: Column(
            children: [
              _buildHeader(colorScheme, l10n),

              // Optimization message banner
              if (widget.optimizationMessage != null ||
                  widget.timeSaved != null)
                _buildOptimizationBanner(colorScheme, l10n),
            ],
          ),
        ),

        // Bottom card showing selected stop or next stop
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _buildBottomCard(colorScheme, l10n),
        ),

        // Fit to route button
        Positioned(
          right: 16,
          bottom: 200,
          child: FloatingActionButton.small(
            heroTag: 'fit_route',
            onPressed: _fitMapToRoute,
            backgroundColor: colorScheme.surface,
            child: Icon(
              Icons.fit_screen_rounded,
              color: colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(ColorScheme colorScheme, AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l10n.todaysRoute,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          // Stop count badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              l10n.countStops(_routeStops.length),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptimizationBanner(
      ColorScheme colorScheme, AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.teal.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.teal.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.teal.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.auto_awesome,
              color: Colors.teal.shade700,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.optimizationMessage ?? l10n.routeOptimized,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.teal.shade800,
                  ),
                ),
                if (widget.timeSaved != null)
                  Text(
                    l10n.savedTravelTime(_formatDuration(widget.timeSaved!)),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.teal.shade600,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomCard(ColorScheme colorScheme, AppLocalizations l10n) {
    final selectedStop = _selectedStopIndex != null
        ? _routeStops[_selectedStopIndex!]
        : _routeStops.isNotEmpty
            ? _routeStops.first
            : null;

    if (selectedStop == null) return const SizedBox.shrink();

    final tile = selectedStop.tile;
    final tileColor = Color.fromRGBO(
      tile.colorRed ?? 127,
      tile.colorGreen ?? 127,
      tile.colorBlue ?? 127,
      1,
    );

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.onSurface.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Stop indicator row
            if (_routeStops.length > 1)
              Container(
                height: 60,
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _routeStops.length,
                  itemBuilder: (context, index) {
                    final stop = _routeStops[index];
                    final isSelected = index == (_selectedStopIndex ?? 0);
                    final stopTileColor = Color.fromRGBO(
                      stop.tile.colorRed ?? 127,
                      stop.tile.colorGreen ?? 127,
                      stop.tile.colorBlue ?? 127,
                      1,
                    );
                    final startTime =
                        TimeOfDay.fromDateTime(stop.tile.startTime);
                    final timeStr = startTime.format(context);

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedStopIndex = index;
                        });
                        if (stop.location != null) {
                          _mapController?.animateCamera(
                            CameraUpdate.newLatLngZoom(stop.location!, 15),
                          );
                        }
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? stopTileColor
                              : stopTileColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: stopTileColor,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${stop.order}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: isSelected
                                        ? _getContrastColor(stopTileColor)
                                        : stopTileColor,
                                  ),
                                ),
                                if (index < _routeStops.length - 1) ...[
                                  const SizedBox(width: 6),
                                  Icon(
                                    Icons.arrow_forward,
                                    size: 12,
                                    color: isSelected
                                        ? _getContrastColor(stopTileColor)
                                        : stopTileColor.withOpacity(0.5),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              timeStr,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: isSelected
                                    ? _getContrastColor(stopTileColor)
                                        .withOpacity(0.8)
                                    : stopTileColor.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

            // Selected stop details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Next label
                  Text(
                    _selectedStopIndex == 0
                        ? l10n.firstStop
                        : '${l10n.stop} ${selectedStop.order}',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Stop name
                  Text(
                    '${selectedStop.order}. ${selectedStop.label}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Address
                  if (tile.addressDescription != null ||
                      tile.address != null) ...[
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 16,
                          color: colorScheme.onSurface.withOpacity(0.5),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            tile.addressDescription ?? tile.address ?? '',
                            style: TextStyle(
                              fontSize: 14,
                              color: colorScheme.onSurface.withOpacity(0.7),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                  ],

                  // Arrival time
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 16,
                        color: colorScheme.onSurface.withOpacity(0.5),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        l10n.arriveBy(TimeOfDay.fromDateTime(tile.startTime)
                            .format(context)),
                        style: TextStyle(
                          fontSize: 14,
                          color: colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),

                  // Travel time from previous
                  if (selectedStop.travelTimeFromPrevious != null &&
                      _selectedStopIndex != 0) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          selectedStop.travelMode == 'walk'
                              ? Icons.directions_walk
                              : Icons.directions_car,
                          size: 16,
                          color: Colors.teal,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDuration(selectedStop.travelTimeFromPrevious!),
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.teal,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          ' ${l10n.fromPreviousStop}',
                          style: TextStyle(
                            fontSize: 14,
                            color: colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Action buttons
                  Row(
                    children: [
                      // Edit/View tile button
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EditTile(
                                  tileId: (tile.isFromTiler
                                          ? tile.id
                                          : tile.thirdpartyId) ??
                                      "",
                                  tileSource: tile.thirdpartyType,
                                  thirdPartyUserId: tile.thirdPartyUserId,
                                ),
                              ),
                            );
                          },
                          icon: Icon(
                            (tile.isReadOnly ?? true)
                                ? Icons.visibility_outlined
                                : Icons.edit_outlined,
                            size: 18,
                          ),
                          label: Text(
                            (tile.isReadOnly ?? true)
                                ? l10n.viewTile
                                : l10n.editTile,
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: tileColor,
                            side: BorderSide(color: tileColor),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Start navigation button
                      Expanded(
                        flex: 2,
                        child: Builder(
                          builder: (context) {
                            final canNavigate =
                                _hasValidNavigableLocation(selectedStop);
                            return ElevatedButton.icon(
                              onPressed: canNavigate ? _startNavigation : null,
                              icon: Icon(
                                canNavigate
                                    ? Icons.navigation_rounded
                                    : Icons.location_off_rounded,
                                size: 18,
                              ),
                              label: Text(
                                canNavigate
                                    ? l10n.startNavigation
                                    : l10n.noLocationAvailable,
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: canNavigate
                                    ? Colors.teal
                                    : Colors.grey.shade400,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getContrastColor(Color color) {
    final hsl = HSLColor.fromColor(color);
    return hsl.lightness > 0.6 ? Colors.black87 : Colors.white;
  }
}
