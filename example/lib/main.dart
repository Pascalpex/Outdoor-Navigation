import 'dart:async';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:outdoor_navigation/outdoor_navigation.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  OutdoorNavigation outdoorNavigation = OutdoorNavigationProvider.getOutdoorNavigation();

  bool locationRequested = false;
  final RtklibBindings _bindings = RtklibBindings();
  StreamSubscription<List<GnssSatelite>>? _gnssStreamSubscription;

  void _subToGnssStream() {
    _gnssStreamSubscription = outdoorNavigation.getGnssStream().listen((List<GnssSatelite> gnssSatellites) async {
      // Handle the GNSS data here
      print("Received GNSS data: $gnssSatellites");
    });
  }

  @override
  Widget build(BuildContext context) {
    outdoorNavigation.getGnssStream();
    _bindings.initServer();
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(title: const Text("Standort-Abfrage"), backgroundColor: Colors.green[700]),
        body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              TextButton(onPressed: () => _bindings.startServer(), child: Text("start Server")),
              TextButton(onPressed: () => _bindings.stopServer(), child: Text("stop Server")),
              Center(
                child: StreamBuilder<List<GnssSatelite>>(
                  stream: outdoorNavigation.getGnssStream(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    } else if (snapshot.hasError) {
                      return const Text("Fehler beim Abrufen der GNSS-Daten.");
                    } else if (snapshot.hasData) {
                      final gnssSatellites = snapshot.data!;
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.satellite, size: 60, color: Colors.blue),
                          const SizedBox(height: 20),
                          Text("Anzahl der Satelliten: ${gnssSatellites.length}", style: const TextStyle(fontSize: 18)),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: () {
                              _subToGnssStream();
                            },
                            child: const Text("GNSS-Daten abonnieren"),
                          ),
                        ],
                      );
                    } else {
                      return const Text("Keine GNSS-Daten verfügbar.");
                    }
                  },
                ),
              ),
              Center(
                child:
                    locationRequested
                        ? FutureBuilder<LatLng?>(
                          future: outdoorNavigation.getLocation(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const CircularProgressIndicator();
                            } else if (snapshot.hasError) {
                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.error, color: Colors.red, size: 60),
                                  const SizedBox(height: 20),
                                  const Text("Fehler beim Abrufen des Standorts."),
                                  const SizedBox(height: 20),
                                  ElevatedButton(
                                    onPressed: () {
                                      setState(() {
                                        locationRequested = false;
                                      });
                                    },
                                    child: const Text("Zurück"),
                                  ),
                                ],
                              );
                            } else if (snapshot.hasData && snapshot.data != null) {
                              final location = snapshot.data!;
                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.location_on, size: 60, color: Colors.green),
                                  const SizedBox(height: 20),
                                  Text("Breitengrad: ${location.latitude}", style: const TextStyle(fontSize: 18)),
                                  Text("Längengrad: ${location.longitude}", style: const TextStyle(fontSize: 18)),
                                  const SizedBox(height: 20),
                                  ElevatedButton(
                                    onPressed: () {
                                      setState(() {});
                                    },
                                    child: const Text("Standort erneut abrufen"),
                                  ),
                                  const SizedBox(height: 10),
                                  ElevatedButton(
                                    onPressed: () {
                                      setState(() {
                                        locationRequested = false;
                                      });
                                    },
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[600]),
                                    child: const Text("Zurück"),
                                  ),
                                ],
                              );
                            } else {
                              return const Text("Keine Standortdaten verfügbar.");
                            }
                          },
                        )
                        : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text("Drücke den Button, um deinen Standort abzurufen."),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  locationRequested = true;
                                });
                              },
                              child: const Text("Standort abrufen"),
                            ),
                          ],
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
