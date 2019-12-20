import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audio_recorder/audio_recorder.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io' as io;
import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:permission_handler/permission_handler.dart';

void main() => runApp(new MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => new _MyAppState();

  final LocalFileSystem localFileSystem;
  MyApp({localFileSystem}) : this.localFileSystem = localFileSystem ?? LocalFileSystem();
}

class _MyAppState extends State<MyApp> {
  PermissionStatus _status;
  static const CHANNEL = 'audidudichannel';
  static const platformChannel = const MethodChannel(CHANNEL);
  TextEditingController _controller = new TextEditingController();
  Recording _recording = new Recording();
  bool _isRecording = false;
  Random random = new Random();

  bool _playState = false;
  String _currentWaveform = 'sine';
  String _currentNoteName = 'A';

  List<String> waveForms = [
    'sine',
    'sawTooth',
    'square',
  ];

  List<String> noteNames = [
    'A', 'B', 'C', 'D', 'E', 'F', 'G',
  ];

  // A4 - B5
  List<double> frequencies = [
    440.0, 493.88, 523.25, 587.33, 659.25, 698.46, 783.99,
  ];

  @override
  void initState() {
    super.initState();
    platformChannel.invokeMethod('setFrequency', {'frequency': frequencies[0]});
    PermissionHandler().checkPermissionStatus(PermissionGroup.microphone).then(_updateStatus);
    PermissionHandler().requestPermissions([PermissionGroup.microphone, PermissionGroup.storage]).then(_onStatusRequested);
  }

  void _updateCurrentNote(){
    int pos = noteNames.indexOf(_currentNoteName);
    platformChannel.invokeMethod('setFrequency', {'frequency': frequencies[pos]});
  }

  void _playSound(){
    platformChannel.invokeMethod('play');
    setState(() {
      _playState = true;
    });
  }

  void _stopSound(){
    platformChannel.invokeMethod('stop');
    setState(() {
      _playState = false;
    });
  }

  void _recordOneSec() async{
    bool hasPermissions = await AudioRecorder.hasPermissions;

// Get the state of the recorder
    bool isRecording = await AudioRecorder.isRecording;

// Start recording
    await AudioRecorder.start(path: _controller.text, audioOutputFormat: AudioOutputFormat.AAC);

// Stop recording
    Recording recording = await AudioRecorder.stop();
    print("Path : ${recording.path},  Format : ${recording.audioOutputFormat},  Duration : ${recording.duration},  Extension : ${recording.extension},");
  }


  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      theme: new ThemeData(
        primarySwatch: Colors.cyan,
      ),
      home: new Scaffold(
        backgroundColor: Colors.grey[350],
        appBar: new AppBar(
          title:  SafeArea(child: Text('Flutter, make some noise demo \n permission: $_status')),
        ),
        body: new Center(
          child: new Column(
            children: <Widget>[
              new Spacer(),
              new ClipOval(
                child: Container(
                  color: Colors.blue,
                  child: IconButton(
                      icon: _playState ? Icon(Icons.stop) : Icon(Icons.play_arrow),
                      tooltip: 'play/stop',
                      color: Colors.white,
                      onPressed: () {
                        if(_playState) {
                            _stopSound();
                            _stop();
                        }
                        else {
                          _playSound();
                          _start();
                        }
                      }
                  ),
                ),
              ),
              new Container(
                padding: const EdgeInsets.only(left: 64.0, right: 64.0, top: 32.0),
                child: new ListTile(
                  title: const Text('note name:'),
                  trailing: new DropdownButton<String>(
                    value: _currentNoteName,
                    onChanged: (String newValue) {
                      setState(() {
                        _currentNoteName = newValue;
                        _updateCurrentNote();
                      });
                    },
                    items: noteNames.map((String value) {
                      return new DropdownMenuItem<String>(
                        value: value,
                        child: new Text(value),
                      );
                    }).toList(),
                  ),
                ),
              ),
              new Container(
                padding: const EdgeInsets.only(left: 64.0, right: 64.0),
                child: new ListTile(
                  title: const Text('wave form:'),
                  trailing: new DropdownButton<String>(
                    value: _currentWaveform,
                    onChanged: (String newValue) {
                      setState(() {
                        _currentWaveform = newValue;
                        platformChannel.invokeMethod('setWaveform', {'waveform': newValue});
                      });
                    },
                    items: waveForms.map((String value) {
                      return new DropdownMenuItem<String>(
                        value: value,
                        child: new Text(value),
                      );
                    }).toList(),
                  ),
                ),
              ),
              new Spacer(),
            ],
          ),
        ),
      ),
    );
  }
  _start() async {
    
    try {
      if (await AudioRecorder.hasPermissions) {
        print("sound_check: Start recording.");

        if (_controller.text != null && _controller.text != "") {
          String path = _controller.text;
          if (!_controller.text.contains('/')) {
            io.Directory appDocDirectory =
            await getApplicationDocumentsDirectory();
            path = appDocDirectory.path + '/' + _controller.text;
          }
          print("sound_check: recording path: $path");
          await AudioRecorder.start(
              path: path, audioOutputFormat: AudioOutputFormat.AAC);
        } else {
          print("sound_check: waiting for controller.");
          await AudioRecorder.start();
        }
        bool isRecording = await AudioRecorder.isRecording;
        setState(() {
          _recording = new Recording(duration: new Duration(), path: "");
          _isRecording = isRecording;
        });
      } else {
        print("sound_check: permission needed.");
        Scaffold(
          appBar: AppBar(
            title: Text('SnackBar Playground'),
          ),
          body: Builder(
            builder: (context) =>
                Center(
                  child: RaisedButton(
                    color: Colors.pink,
                    textColor: Colors.white,
                    onPressed: () => _displaySnackBar(context),
                    child: Text('Display SnackBar'),
                  ),
                ),
          ),
        );
      }
    } catch (e) {
      print("sound_check: error in start recording.");
      print(e);
    }
  }

  _displaySnackBar(BuildContext context) {
    final snackBar = SnackBar(content: Text('You must accept permissions'));
    Scaffold.of(context).showSnackBar(snackBar);
  }

  _stop() async {
    var recording = await AudioRecorder.stop();
    print("Stop recording: ${recording.path}");
    bool isRecording = await AudioRecorder.isRecording;
    File file = widget.localFileSystem.file(recording.path);
    print("  File length: ${await file.length()}");
    setState(() {
      _recording = recording;
      _isRecording = isRecording;
    });
    _controller.text = recording.path;
  }


  void _updateStatus(PermissionStatus value) {
    if (value != _status) {
      _status = value;
    }
  }

  void _onStatusRequested(Map<PermissionGroup, PermissionStatus> statuses) {
    final status = statuses[PermissionGroup.microphone];
    _updateStatus(status);
  }
}