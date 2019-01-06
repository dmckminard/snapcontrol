import 'dart:async';
import 'dart:math';

import 'package:scoped_model/scoped_model.dart';
import 'dart:io';
import 'dart:convert';

// Constants
const String DELIMITER = '\r\n';
const int SNAPCAST_CONTROL_PORT = 1705;
const String SERVER_GETSTATUS = 'Server.GetStatus';
const String SERVER_GETRPCVERSION = 'Server.GetRPCVersion';
const String SERVER_DELETECLIENT = 'Server.DeleteClient';
const String SERVER_ONUPDATE = 'Server.OnUpdate';
const String CLIENT_GETSTATUS = 'Client.GetStatus';
const String CLIENT_SETNAME = 'Client.SetName';
const String CLIENT_SETLATENCY = 'Client.SetLatency';
const String CLIENT_SETSTREAM = 'Client.SetStream';
const String CLIENT_SETVOLUME = 'Client.SetVolume';
const String CLIENT_ONCONNECT = 'Client.OnConnect';
const String CLIENT_ONDISCONNECT = 'Client.OnDisconnect';
const String CLIENT_ONVOLUMECHANGED = 'Client.OnVolumeChanged';
const String CLIENT_ONLATENCYCHANGED = 'Client.OnLatencyChanged';
const String CLIENT_ONNAMECHANGED = 'Client.OnNameChanged';
const String GROUP_GETSTATUS = 'Group.GetStatus';
const String GROUP_SETMUTE = 'Group.SetMute';
const String GROUP_SETSTREAM = 'Group.SetStream';
const String GROUP_SETCLIENTS = 'Group.SetClients';
const String GROUP_ONMUTE = 'Group.OnMute';
const String GROUP_ONSTREAMCHANGED = 'Group.OnStreamChanged';
const String STREAM_ONUPDATE = 'Stream.OnUpdate';

class Snapcast extends Model {
  Socket _socket;
  String response = "";
  SnapStatus status;
  bool isSet = false;
  var rng = new Random();
  int _statusId;

  String _getStatusReq =
      '{"id":?,"jsonrpc":"2.0","method":"Server.GetStatus"}' + DELIMITER;

  void setup(String ip, int port) async {
    if (_socket != null) {
      _socket.destroy();
    }
    _socket = await Socket.connect(ip, port);
    isSet = true;
    _socket.listen(_handleMessage);
    notifyListeners();
    _getStatus();
  }

  void _handleMessage(List<int> data) async {
    String parsedData = String.fromCharCodes(data);
    try {
      var tokens = parsedData.split(DELIMITER);
      String usableMessage = "";
      if (tokens.last.trim().compareTo("") == 0) {
        usableMessage = tokens[min(0, tokens.length - 2)];
      } else {
        usableMessage = tokens.last;
      }

      Map resp = json.decode(usableMessage);
      if (resp['id'] == _statusId) {
        _setStatus(resp);
      }
      notifyListeners();
    } catch (e) {
      print("Unable to parse data, ${e.toString()}");
    }
  }

  int _getRequestID() {
    return rng.nextInt(10000000);
  }

  void _getStatus() async {
    _statusId = _getRequestID();
    String request = _getStatusReq.replaceFirst('?', _statusId.toString());
    _socket.add(request.codeUnits);
  }

  void _setStatus(Map statusData) async {
    status = SnapStatus();
    for (var value in statusData['result']['server']['groups']) {
      SnapGroup g = SnapGroup();
      g.id = value['id'];
      g.muted = value['muted'];
      g.stream = value['stream_id'];
      for (var innerValue in value['clients']) {
        Map clientConfig = innerValue['config'];
        SnapClient c = SnapClient();
        c.id = innerValue['id'];
        c.latency = clientConfig['latency'];
        c.name = clientConfig['name'];
        c.volume = clientConfig['volume']['percent'];
        c.muted = clientConfig['volume']['muted'];
        c.connected = innerValue['connected'];
        g.clients.add(c);
      }
      status.groups.add(g);
    }
    notifyListeners();
  }
}

class SnapStatus {
  List<String> streams;
  List<SnapGroup> groups;
  SnapStatus() {
    streams = List();
    groups = List();
  }
}

class SnapClient {
  String id = "";
  int volume = 0;
  bool muted = true;
  int latency = 0;
  String name = "";
  bool connected = true;
}

class SnapGroup {
  String id = "";
  bool muted = true;
  String stream = "";
  List<SnapClient> clients;
  SnapGroup() {
    clients = List();
  }
}
