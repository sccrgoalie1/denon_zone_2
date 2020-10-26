import 'dart:io';

import 'package:denon_zone_2/debouncer.dart';
import 'package:denon_zone_2/denon_service.dart';
import 'package:flutter/material.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

void main() {
  HttpOverrides.global = MyHttpOverrides();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Denon Simple Zone 2 Control',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
        // This makes the visual density adapt to the platform that you run
        // the app on. For desktop platforms, the controls will be smaller and
        // closer together (more dense) than on mobile platforms.
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'Denon Simple Zone 2 Control'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final DenonService service = new DenonService();
  bool poweredOn = false;
  double _currentSliderValue = 0;
  String error = '';
  final _debouncer = Debouncer(milliseconds: 1000);
  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          this.poweredOn = await service.zone2PoweredOn();
          setState(() {});
        },
        child: FutureBuilder<bool>(
            future: service.zone2PoweredOn(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Text(snapshot.error.toString());
              }
              if (!snapshot.hasData) {
                return Text('Loading');
              }
              poweredOn = snapshot.data;
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      //style: Theme.of(context).elevatedButtonTheme.style.copyWith(foregroundColor: MaterialStateProperty.resolveWith((_) => poweredOn ? Colors.red : Colors.green)),
                        child: Text('Power ${poweredOn ? 'Off' : 'On'}'),
                        onPressed: () async {
                          if (poweredOn) {
                            final response = await service.powerOff();
                          } else {
                            final response2 = await service.powerOn();
                          }
                          setState(() {
                            poweredOn = !poweredOn;
                          });
                        }),
                    Slider(
                        value: _currentSliderValue,
                        min: 0,
                        max: 70,
                        label: _currentSliderValue.round().toString(),
                        onChanged: (double value) async {
                          try {
                            setState(() {
                              _currentSliderValue = value;
                            });
                            _debouncer.run(() async {
                              final volume = await service.zone2Volume(value);
                              setState(() {
                                _currentSliderValue = volume;
                              });
                            });
                          } on Exception catch (e) {
                            setState(() {
                              error = e.toString();
                            });
                          }
                        }),
                    Text(_currentSliderValue.toStringAsFixed(1)),
                    if (error.isNotEmpty) Text(error)
                  ],
                ),
              );
            }),
      ),
    );
  }
}