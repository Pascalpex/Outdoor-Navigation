import 'package:flutter/material.dart';
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
      home: Scaffold(
        body: Center(
          child:
              locationRequested
                  ? FutureBuilder(
                    future: outdoorNavigation.getLocation(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        HHNLocation location = snapshot.data!;
                        return Text(location.toString());
                      } else {
                        return CircularProgressIndicator();
                      }
                    },
                  )
                  : ElevatedButton(
                    onPressed: () {
                      setState(() {
                        locationRequested = true;
                      });
                    },
                    child: Text("Get Location"),
                  ),
        ),
      ),
    );
  }
}
