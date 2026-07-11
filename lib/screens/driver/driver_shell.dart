import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/driver_provider.dart';
import '../profile_screen.dart';
import '../../widgets/squishy_button.dart';

class DriverShell extends StatefulWidget {
  const DriverShell({super.key});

  @override
  State<DriverShell> createState() => _DriverShellState();
}

class _DriverShellState extends State<DriverShell> {
  final MapController _mapController = MapController();
  bool _centeredOnce = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final driver = context.read<DriverProvider>();
      final auth = context.read<AuthProvider>();
      driver.initGps();
      await driver.loadRoutes(auth.currentUser!.id);
      await driver.resumeActiveTrip(auth.currentUser!.id);
      if (driver.resumed && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Trip restored — app was closed while trip was active',
            ),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final driver = context.watch<DriverProvider>();

    if (driver.currentLat != null && !_centeredOnce) {
      _centeredOnce = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapController.move(LatLng(driver.currentLat!, driver.currentLng!), 16);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(driver.selectedRouteName ?? 'Driver Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ProfileScreen(),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Map
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: LatLng(
                      driver.currentLat ?? 6.9271,
                      driver.currentLng ?? 79.8612,
                    ),
                    initialZoom: 15,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://a.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
                      retinaMode: true,
                    ),
                    if (driver.currentLat != null && driver.currentLng != null)
                      MarkerLayer(
                        markers: [
                          // Driver bus marker
                          Marker(
                            point: LatLng(
                              driver.currentLat!,
                              driver.currentLng!,
                            ),
                            width: 40,
                            height: 40,
                            child: Icon(
                              Icons.directions_bus,
                              color: Theme.of(context).colorScheme.primary,
                              size: 36,
                            ),
                          ),
                          // Halt markers
                          for (final halt in driver.halts)
                            if (halt.latitude != null && halt.longitude != null)
                              Marker(
                                point: LatLng(halt.latitude!, halt.longitude!),
                                width: 36,
                                height: 44,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            driver.completedHalts.contains(
                                              halt.id,
                                            )
                                            ? const Color(0xFF4CAF50)
                                            : const Color(0xFF1E1E1E),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '${halt.stopOrder + 1}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const Icon(
                                      Icons.location_on,
                                      color: Color(0xFFFF5252),
                                      size: 20,
                                    ),
                                  ],
                                ),
                              ),
                        ],
                      ),
                  ],
                ),
                // GPS status badge
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: driver.tripActive
                          ? const Color(0xFF4CAF50)
                          : Colors.black54,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.gps_fixed,
                          size: 14,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          driver.tripActive ? 'LIVE' : 'GPS',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (driver.lastPing != null)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Last: ${driver.lastPing!.hour.toString().padLeft(2, '0')}:${driver.lastPing!.minute.toString().padLeft(2, '0')}:${driver.lastPing!.second.toString().padLeft(2, '0')}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Bottom panel
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (driver.routes.isEmpty)
                    const Text('No route assigned yet.')
                  else ...[
                    if (driver.routes.length > 1)
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Select route',
                        ),
                        items: driver.routes
                            .map(
                              (r) => DropdownMenuItem(
                                value: r['id'] as String,
                                child: Text(r['name'] as String),
                              ),
                            )
                            .toList(),
                        onChanged: driver.tripActive
                            ? null
                            : (v) {
                                if (v != null) driver.selectRoute(v);
                              },
                      ),
                    if (driver.halts.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Expanded(
                        child: ListView(
                          children: driver.halts.map((halt) {
                            final done = driver.completedHalts.contains(
                              halt.id,
                            );
                            return Card(
                              child: ListTile(
                                dense: true,
                                leading: CircleAvatar(
                                  radius: 14,
                                  backgroundColor: done
                                      ? const Color(0xFF4CAF50)
                                      : const Color(
                                          0xFFFFD700,
                                        ).withValues(alpha: 0.3),
                                  child: Text(
                                    '${halt.stopOrder + 1}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: done ? Colors.white : null,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  halt.name,
                                  style: const TextStyle(fontSize: 14),
                                ),
                                subtitle: Text(
                                  'Arrival: ${halt.arrivalTime}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                trailing: done
                                    ? const Icon(
                                        Icons.check_circle,
                                        color: Color(0xFF4CAF50),
                                        size: 20,
                                      )
                                    : IconButton(
                                        icon: const Icon(
                                          Icons.check_circle_outline,
                                          size: 20,
                                        ),
                                        onPressed: () =>
                                            driver.toggleHalt(halt.id),
                                      ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ],
                  const SizedBox(height: 8),
                  if (!driver.gpsReady && !driver.tripActive)
                    const Text(
                      'Enable GPS to start a trip',
                      style: TextStyle(color: Color(0xFFFF5252), fontSize: 12),
                    ),
                  SquishyButton(
                    label: driver.tripActive ? 'STOP TRIP' : 'START TRIP',
                    backgroundColor: driver.tripActive
                        ? const Color(0xFFFF5252)
                        : const Color(0xFFFFD700),
                    foregroundColor: const Color(0xFF1E1E1E),
                    onTap: driver.selectedRouteId == null || !driver.gpsReady
                        ? null
                        : () {
                            if (driver.tripActive) {
                              driver.stopTrip();
                            } else {
                              driver.startTrip(
                                context.read<AuthProvider>().currentUser!.id,
                              );
                            }
                          },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
