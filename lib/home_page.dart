import 'dart:async';
import 'dart:io';

import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
// ignore: depend_on_referenced_packages
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String name = "";
  List<String> _fileName = [];
  List<String> _filePath = [];
  List<Duration> _duration = [];

  final Record _record = Record();
  AudioPlayer audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  late Duration _position = const Duration(seconds: 0);
  bool _isRunning = false;
  late String recordingPath;
  int _seconds = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadAudioFiles();
  }

  void _startRecording() async {
    final PermissionStatus status = await Permission.storage.request();
    if (!status.isGranted) {
      throw Exception('Permission not granted');
    }
    if (await _record.hasPermission()) {
      final String dirPath = '${(await getExternalStorageDirectory())?.path}';
      final String now = DateTime.now().toString().replaceAll(" ", "_");

      if (!await Directory(dirPath).exists()) {
        await Directory(dirPath).create(recursive: true);
      }

      recordingPath = '$dirPath/Rec_$now.mp3';
      // Start recording
      await _record.start(
        path: recordingPath,
        encoder: AudioEncoder.aacLc, // by default
        bitRate: 128000, // by default
        samplingRate: 44100, // by default
      );
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _seconds++;
        });
      });
    } else {
      final PermissionStatus status = await Permission.storage.request();
      if (!status.isGranted) {
        throw Exception('Permission not granted');
      }
    }
  }

  void _stopRecording() async {
    if (await _record.isRecording()) {
      await _record.stop();
      // ignore: use_build_context_synchronously
      showDialog(
        context: context,
        builder: (BuildContext context) {
          final controller = TextEditingController();

          return AlertDialog(
            title: const Text('Enter Recording Name'),
            content: TextField(
              controller: controller,
              onSubmitted: (value) async {
                final name = controller.text.trim();
                if (name.isNotEmpty) {
                  final newName = p.join(p.dirname(recordingPath), '$name.mp3');
                  await File(recordingPath).rename(newName);
                  recordingPath = newName;
                  _loadAudioFiles();
                  // ignore: use_build_context_synchronously
                  Navigator.of(context).pop();
                } else {
                  // ignore: non_constant_identifier_names
                  var Name = "rec-no-${_fileName.length + 1}";
                  print(Name);
                  final newName = p.join(p.dirname(recordingPath), '$Name.mp3');
                  await File(recordingPath).rename(newName);
                  recordingPath = newName;
                  _loadAudioFiles();
                  // ignore: use_build_context_synchronously
                  Navigator.of(context).pop();
                }
              },
            ),
            actions: [
              ElevatedButton(
                onPressed: () async {
                  final name = controller.text.trim();
                  if (name.isNotEmpty) {
                    final newName =
                        p.join(p.dirname(recordingPath), '$name.mp3');
                    await File(recordingPath).rename(newName);
                    recordingPath = newName;
                    _loadAudioFiles();
                    // ignore: use_build_context_synchronously
                    Navigator.of(context).pop();
                  } else {
                    // ignore: non_constant_identifier_names
                    String Name = "rec-no-${_fileName.length + 1}";
                    final newName =
                        p.join(p.dirname(recordingPath), '$Name.mp3');
                    await File(recordingPath).rename(newName);
                    recordingPath = newName;
                    _loadAudioFiles();
                    // ignore: use_build_context_synchronously
                    Navigator.of(context).pop();
                  }
                },
                child: const Text('OK'),
              ),
              ElevatedButton(
                onPressed: () async {
                  await File(recordingPath).delete();
                  _loadAudioFiles();
                  // ignore: use_build_context_synchronously
                  Navigator.of(context).pop();
                },
                child: const Text('Delete'),
              ),
            ],
          );
        },
      );
    }
  }

  Future<void> _shareRecording(String filePath) async {
    // ignore: deprecated_member_use
    await Share.shareFiles([filePath]);
  }

  Future<void> _renameFile(String filePath) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final controller = TextEditingController();

        return AlertDialog(
          title: const Text('Enter Recording Name'),
          content: TextField(
            controller: controller,
            onSubmitted: (value) async {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                final newName = p.join(p.dirname(filePath), '$name.mp3');
                await File(filePath).rename(newName);
                filePath = newName;
                _loadAudioFiles();
                // ignore: use_build_context_synchronously
                Navigator.of(context).pop();
              } else {
                Navigator.of(context).pop();
              }
            },
          ),
          actions: [
            ElevatedButton(
              onPressed: () async {
                final name = controller.text.trim();
                if (name.isNotEmpty) {
                  final newName = p.join(p.dirname(filePath), '$name.mp3');
                  await File(filePath).rename(newName);
                  filePath = newName;
                  _loadAudioFiles();
                  // ignore: use_build_context_synchronously
                  Navigator.of(context).pop();
                } else {
                  Navigator.of(context).pop();
                }
              },
              child: const Text('OK'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteRecording(String filePath) async {
    try {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text("Want to delete?"),
            actions: [
              ElevatedButton(
                  onPressed: () async {
                    await File(filePath).delete();
                    _loadAudioFiles();

                    // ignore: use_build_context_synchronously
                    Navigator.of(context).pop();
                  },
                  child: const Text("Delete")),
              ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text("Cancel"))
            ],
          );
        },
      );
    } catch (e) {
      // Show an error message if the file couldn't be deleted
    }
  }

  void _playRecording(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      setState(() {
        _isPlaying = true;
      });
      await audioPlayer.play(
        filePath,
        position: _position,
      );
    }

    audioPlayer.onAudioPositionChanged.listen((Duration position) {
      setState(() {
        _position = position;
      });
    });

    audioPlayer.onPlayerCompletion.listen((event) {
      setState(() {
        _isPlaying = false;
        _position = Duration.zero;
      });
    });
  }

  void _stopPlaying() async {
    if (_isPlaying) {
      await audioPlayer.pause();
      setState(() {
        _isPlaying = false;
      });
    }
  }

  Future<void> _loadAudioFiles() async {
    _fileName.clear();
    _filePath.clear();
    _duration.clear();

    List<String> fileName = [];
    List<String> filePath = [];
    List<Duration> duration = [];

    AudioPlayer audio = AudioPlayer();

    String? externalStorageDirectory =
        (await getExternalStorageDirectory())?.path;
    Directory externalDirectory = Directory(externalStorageDirectory!);
    List<FileSystemEntity> files = externalDirectory.listSync();
    List<FileSystemEntity> audioFiles = files
        .where(
            (file) => file.path.endsWith('.mp3') || file.path.endsWith('.wav'))
        .toList();
    for (var element in audioFiles) {
      String name = (element.toString().split('/files/')[1]);
      name = name.substring(0, name.length - 1);
      fileName.add(name);
      String path = element.toString().split("File: '")[1];
      path = (path.substring(0, path.length - 1));
      filePath.add(path);
      await audio.setUrl(path);
      Duration dur = await audio.onDurationChanged.first;
      duration.add(dur);
    }
    setState(() {
      _fileName = fileName;
      _filePath = filePath;
      _duration = duration;
    });
  }

  void _toggleTimer() {
    setState(() {
      if (_isRunning) {
        _isRunning = false;
        _seconds = 0;
        _timer?.cancel();
        _stopRecording();
      } else {
        _startRecording();
        _isRunning = true;
      }
    });
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(primarySwatch: Colors.deepPurple),
      home: Scaffold(
          appBar: AppBar(
            title: const Text("Audio Rec"),
          ),
          bottomNavigationBar: const BottomAppBar(
            color: Color(0xFF673AB7),
            height: 30,
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _toggleTimer,
            backgroundColor: Colors.white,
            foregroundColor: Colors.deepPurple,
            label: Text(_isRunning ? _formatTime(_seconds) : ""),
            extendedPadding: const EdgeInsets.all(5),
            icon: const Icon(Icons.mic, size: 40),
            extendedIconLabelSpacing: 0.0,
          ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerDocked,
          body: ListView.builder(
            itemCount: _filePath.length,
            itemBuilder: (BuildContext context, int index) {
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      border: Border.all(color: Colors.deepPurple),
                      borderRadius:
                          const BorderRadius.all(Radius.circular(20))),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          // ignore: sort_child_properties_last
                          children: [
                            Text(_fileName[index]),
                            Row(
                              children: [
                                IconButton(
                                  onPressed: () async {
                                    name = _fileName[index];
                                    if (_isPlaying) {
                                      _stopPlaying();
                                    } else {
                                      _playRecording(_filePath[index]);
                                    }
                                  },
                                  icon: Icon((name == _fileName[index])
                                      ? (_isPlaying
                                          ? Icons.stop
                                          : Icons.play_arrow)
                                      : Icons.play_arrow),
                                ),
                                Expanded(
                                  child: SizedBox(
                                    width:
                                        MediaQuery.of(context).size.width * 0.7,
                                    child: ProgressBar(
                                      progress: ((name == _fileName[index])
                                          ? _position
                                          : const Duration(seconds: 0)),
                                      total: _duration[index],
                                      onSeek: (duration) async {
                                        audioPlayer.seek(duration);
                                        if (_isPlaying) {
                                          _stopPlaying();
                                        }
                                      },
                                      onDragUpdate: (dragEndDetails) async {
                                        audioPlayer
                                            .seek(dragEndDetails.timeStamp);
                                        if (_isPlaying) {
                                          await audioPlayer.pause();
                                          setState(() {
                                            _isPlaying = false;
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            )
                          ],
                          crossAxisAlignment: CrossAxisAlignment.start,
                        ),
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(
                          Icons.more_vert,
                          size: 35,
                        ),
                        itemBuilder: (BuildContext context) =>
                            <PopupMenuEntry<String>>[
                          const PopupMenuItem<String>(
                            value: 'rename',
                            child: Text('Rename'),
                          ),
                          const PopupMenuItem<String>(
                            value: 'share',
                            child: Text('Share'),
                          ),
                          const PopupMenuItem<String>(
                            value: 'delete',
                            child: Text('Delete'),
                          ),
                        ],
                        onSelected: (String value) {
                          if (value == 'rename') {
                            _renameFile(_filePath[index]);
                          } else if (value == 'share') {
                            _shareRecording(_filePath[index]);
                          } else {
                            _deleteRecording(_filePath[index]);
                          }
                        },
                      )
                    ],
                  ),
                ),
              );
            },
          )),
    );
  }
}
