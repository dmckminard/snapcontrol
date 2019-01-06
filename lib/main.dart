import 'package:flutter/material.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:snapcontrol/globalwidgets.dart';
import 'package:snapcontrol/models/snapcast.dart' as sc;
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(SnapControlApp());

class SnapControlApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SnapControl',
      theme: ThemeData(
        primarySwatch: Colors.grey,
      ),
      home: MainPage(
        title: 'SnapControl',
        model: sc.Snapcast(),
      ),
    );
  }
}

class MainPage extends StatefulWidget {
  MainPage({Key key, this.title, @required this.model}) : super(key: key);
  final String title;
  final sc.Snapcast model;

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  String _host = "";
  int _port = sc.SNAPCAST_CONTROL_PORT;
  TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.text = _port.toString();
  }

  Future<String> _showSettingsDialog(BuildContext context) async {
    String host = "";
    String port = _controller.text;
    return showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Settings'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                autofocus: true,
                keyboardType: TextInputType.url,
                onChanged: (value) {
                  host = value;
                },
                decoration:
                    InputDecoration(hintText: 'IP Address', labelText: 'Host'),
              ),
              TextField(
                  controller: _controller,
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    port = value;
                  },
                  decoration: InputDecoration(hintText: '', labelText: 'Port')),
            ],
          ),
          actions: <Widget>[
            FlatButton(
              child: Text('CANCEL'),
              onPressed: () {
                _storeSettings("");
                Navigator.of(context).pop("");
              },
            ),
            FlatButton(
              child: Text('OK'),
              onPressed: () {
                String config = "$host:$port";
                _storeSettings(config);
                Navigator.of(context).pop(config);
              },
            ),
          ],
        );
      },
    );
  }

  _storeSettings(String config) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('config', config);
  }

  Future<String> _getSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('config') ?? "";
  }

  @override
  Widget build(BuildContext context) {
    return new ScopedModel<sc.Snapcast>(
      model: widget.model,
      child:
          Center(
            child: ScopedModelDescendant<sc.Snapcast>(builder: (context, child, model) {
        return Scaffold(
            appBar: AppBar(
              title: Text(widget.title),
              actions: <Widget>[
                IconButton(
                  icon: Icon(Icons.settings),
                  onPressed: () {
                    _showSettingsDialog(context).then((config) {
                      if (config == null) {
                        config = "";
                      }
                      var values = config.split(":");
                      if (values.length == 2) {
                        print(values);
                        if ("".compareTo(values[0]) != 0) {
                          _host = values[0];
                          if ("".compareTo(values[1]) == 0) {
                            _port = sc.SNAPCAST_CONTROL_PORT;
                          } else {
                            _port = int.parse(values[1]);
                          }
                          model.setup(_host, _port);
                        }
                      }
                    });
                  },
                ),
              ],
            ),
            body: FutureBuilder<String>(
              future: _getSettings(),
              builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
                switch (snapshot.connectionState) {
                  case ConnectionState.none:
                  case ConnectionState.active:
                  case ConnectionState.waiting:
                    return LoadingIndicator();
                  case ConnectionState.done:
                    if (snapshot.hasError || snapshot.data.compareTo("") == 0) {
                      print("Error: ${snapshot.error}");
                      return Center(
                          child:
                              Text("Go to the settings to set the Snapserver"));
                    }
                    if (!model.isSet) {
                      var values = snapshot.data.split(":");
                      if (values.length == 2) {
                        print(values);
                        if ("".compareTo(values[0]) != 0) {
                          _host = values[0];
                          if ("".compareTo(values[1]) == 0) {
                            _port = sc.SNAPCAST_CONTROL_PORT;
                          } else {
                            _port = int.parse(values[1]);
                          }
                          model.setup(_host, _port);
                        }
                      }
                      return Center(
                          child:
                              Text("Connecting to Snapserver..."));
                    }
                    return ListView.builder(
                        shrinkWrap: true,
                        itemCount: model.status.groups.length,
                        itemBuilder: (context, groupIndex) {
                          sc.SnapGroup group =
                              model.status.groups.elementAt(groupIndex);
                          return Padding(
                          padding: EdgeInsets.all(20),
                              child: Card(
                            elevation: 10,
                            child: Padding(
                                padding: EdgeInsets.all(10),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text("${group.stream}"),
                                    Padding(
                                      padding: EdgeInsets.all(10)
                                      ,child:Container(
                                        child: ListView.builder(
                                      shrinkWrap: true,
                                      itemCount: model.status.groups
                                          .elementAt(groupIndex)
                                          .clients
                                          .length,
                                      itemBuilder: (content, clientIndex) {
                                        sc.SnapClient client = model.status.groups
                                            .elementAt(groupIndex)
                                            .clients
                                            .elementAt(clientIndex);
                                        Icon volumeState = client.muted
                                            ? Icon(Icons.volume_off)
                                            : Icon(Icons.volume_up);
                                        return Opacity(
                                            opacity: client.connected ? 1.0 : 0.5,
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: <Widget>[
                                                Text("${client.name}"),
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  mainAxisSize: MainAxisSize.max,
                                                  children: <Widget>[
                                                    Slider(
                                                        value: client.volume / 100.0,
                                                        onChanged: (value) {}),
                                                    IconButton(icon: volumeState, onPressed: () {}),
                                                  ],
                                                ),
                                              ],
                                            ));
                                      },
                                    ))),
                                  ],
                                )),
                          ));
                        });
                }
                return null; // unreachable
              },
            ),
        );
      }),
          ),
    );
  }
}
