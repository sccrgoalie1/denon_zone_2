import 'dart:io';

import 'package:denon_zone_2/basic_info.dart';
import 'package:denon_zone_2/bloc/zone_info_bloc.dart';
import 'package:denon_zone_2/debouncer.dart';
import 'package:denon_zone_2/denon_service.dart';
import 'package:denon_zone_2/globals.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
  final DenonService service = DenonService();
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ZoneInfoBloc>(
          create: (context) => ZoneInfoBloc(service: service),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Denon Simple Zone Control',
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
          primaryColorDark: Colors.black,
          // This makes the visual density adapt to the platform that you run
          // the app on. For desktop platforms, the controls will be smaller and
          // closer together (more dense) than on mobile platforms.
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        darkTheme: ThemeData.dark(),
        home: MyHomePage(title: 'Denon Simple Zone Control'),
      ),

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

class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {
  final DenonService service = new DenonService();
  ZoneInfoBloc _zoneInfoBloc;
  TextEditingController controller = TextEditingController(text: '');
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state.index) {
      case 0: //resume
        setState(() {});
        break;
      case 1: // inactive

        break;
      case 2: // paused

        break;
    }
  }

  @override
  void initState() {
    _zoneInfoBloc = BlocProvider.of<ZoneInfoBloc>(context);
    _zoneInfoBloc.add(ZoneInfoRefreshEvent());
    super.initState();
  }

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
          _zoneInfoBloc.add(ZoneInfoRefreshEvent());
        },
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: BlocBuilder<ZoneInfoBloc, ZoneInfoState>(
              bloc: BlocProvider.of<ZoneInfoBloc>(context),
              builder: (BuildContext context, ZoneInfoState zoneState) {
                if (zoneState is ZoneInfoStateLoading)
                  return PageLoadProgress();
                if (zoneState is ZoneInfoBlocStateError)
                  return Text(zoneState.error);
                if (zoneState is ZoneInfoBlocStateSuccess) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      VolumeSlider(zoneState.info.zone1Info, service, '1'),
                      Divider(),
                      VolumeSlider(zoneState.info.zone2Info, service, '2'),
                    ],
                  );
                }
                return Container();
              }),
        ),
      ),
      drawer: SafeArea(
        top: true,
        child: Drawer(
            child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: FutureBuilder(
              future: service.ipAddress(),
              builder: (context, AsyncSnapshot<List<String>> snapshot) {
                if (snapshot.connectionState != ConnectionState.done)
                  return Container();
                return Column(
                  children: [
                    TextFormField(
                      controller: controller,
                      decoration:
                          InputDecoration(labelText: "Enter a new IP Address"),
                    ),
                    RaisedButton(
                        child: Text('Add'),
                        onPressed: () async {
                          await service.saveIpAddress(controller.text);
                          setState(() {
                            controller.text = '';
                          });
                        }),
                    Expanded(
                      child: ListView.builder(
                          itemCount: snapshot.data?.length ?? 0,
                          itemBuilder: (BuildContext context, int index) {
                            return ListTile(
                              title: Text(snapshot.data[index]),
                              onTap: () async {
                                Globals.api_address = snapshot.data[index];
                                await service
                                    .setCurrentIpAddress(snapshot.data[index]);
                              },
                            );
                          }),
                    )
                  ],
                );
              }),
        )),
      ),
    );
  }
}

class VolumeSlider extends StatefulWidget {
  final BasicInfo info;
  final DenonService service;
  final String zoneNumber;
  VolumeSlider(this.info, this.service, this.zoneNumber);
  @override
  _VolumeSliderState createState() => _VolumeSliderState();
}

class _VolumeSliderState extends State<VolumeSlider> {
  final _debouncer = Debouncer(milliseconds: 500);
  String error = '';
  double _currentSliderValue = 0;

  ZoneInfoBloc _zoneInfoBloc;
  @override
  initState() {
    _zoneInfoBloc = BlocProvider.of<ZoneInfoBloc>(context);
    _currentSliderValue = widget.info.volume;

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Text(
            'Zone ${widget.zoneNumber}',
            style: Theme.of(context).textTheme.headline4,
          ),
          IconButton(
              icon: Icon(
                Icons.power_settings_new_outlined,
                color: widget.info.on ? Colors.green : Colors.red,
              ),
              onPressed: () async {
                if (widget.info.on) {
                  final response =
                      await widget.service.powerOff(widget.zoneNumber);
                } else {
                  final response2 =
                      await widget.service.powerOn(widget.zoneNumber);
                }
                _debouncer.run(() async {
                  _zoneInfoBloc.add(ZoneInfoRefreshEvent());
                });
              }),
          if (widget.info.on) ...[
            Slider(
                value: _currentSliderValue,
                divisions: 100,
                min: 0,
                max: 100,
                label: _currentSliderValue.round().toString(),
                onChanged: (double value) async {
                  try {
                    setState(() {
                      _currentSliderValue = value;
                    });
                    _debouncer.run(() async {
                      final volume = await widget.service
                          .zoneVolume(widget.zoneNumber, value);
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
            Text(
              'Current Volume: ${_currentSliderValue.toStringAsFixed(1)}',
              style: Theme.of(context).textTheme.headline5,
            ),
            Text(
              'Muted: ${widget.info.muted}',
              style: Theme.of(context).textTheme.headline5,
            ),
            DropdownButton<SourceStatus>(
              value: widget.info.sources.firstWhere(
                  (element) => element.name == widget.info.source,
                  orElse: () => null),
              isDense: true,
              onChanged: (SourceStatus t) async {
                await widget.service.changeSource(widget.zoneNumber, t.name);
                _zoneInfoBloc.add(ZoneInfoRefreshEvent());
              },
              items: widget.info.sources.map((value) {
                return DropdownMenuItem<SourceStatus>(
                  value: value,
                  child: Text(value.rename),
                );
              }).toList(),
            ),
          ],
          if (error.isNotEmpty) Text(error)
        ],
      ),
    );
  }
}

class PageLoadProgress extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: CircularProgressIndicator(),
    );
  }
}
