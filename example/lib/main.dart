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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: const Text("Standort-Abfrage"),
          backgroundColor: Colors.green[700],
        ),
        body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Center(
            child: locationRequested
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
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey[600],
                              ),
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
        ),
      ),
    );
  }
}