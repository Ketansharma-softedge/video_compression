import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_compress/video_compress.dart';
import 'package:video_compression/bloc/video_bloc.dart';
import 'package:video_compression/utility/format_bytes.dart';
import 'package:video_player/video_player.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(primarySwatch: Colors.teal),
      home: const MyHomePage(title: 'Video Compressor Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  VideoBloc videoBloc = VideoBloc();
  late File file;
  int time = 0;
  late VideoPlayerController _controller;
  late Subscription _subscription;
  late MediaInfo? mediaInfo;
  String fileSize = '0';
  VideoQuality quality = VideoQuality.MediumQuality;
  double video_progress = 0;

  Future uploadVideo(File file) async {
    // send a request to get image link
    try {
      var bytes = await file.readAsBytes();
      String encodedFile = base64.encode(bytes);

      final extension = p.extension(file.path);
      developer.log('main api');
      var response = await Dio().post(
          'https://753hgssmyb.execute-api.ap-south-1.amazonaws.com/testing/post-file',
          data: {
            "project_name": "video-compress",
            "file_extension": extension.replaceFirst('.', ""),
            "file_content": encodedFile
          },
          options: Options(
            headers: {
              'Accept': '*/*',
            },
          ));
      developer.log('sdfferf' + response.data.toString());
    } catch (e, s) {
      developer.log(e.toString());
      developer.log(s.toString());
    }

    // String imageLink = (data['data'] as Map)['file_url'];
  }

  @override
  void initState() {
    super.initState();
    _subscription = VideoCompress.compressProgress$.subscribe((progress) {
      setState(() {
        video_progress = progress;
      });
      debugPrint('progress: $progress');
    });
  }

  @override
  void dispose() {
    super.dispose();
    _subscription.unsubscribe();
  }

  void startTimer() {
    Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        time = time + 1;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.teal[100],
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: Center(
            child:
                Column(mainAxisAlignment: MainAxisAlignment.start, children: <
                    Widget>[
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              DropdownButton<VideoQuality>(
                value: quality,
                icon: const Icon(Icons.arrow_downward),
                iconSize: 24,
                elevation: 16,
                style: const TextStyle(color: Colors.deepPurple),
                underline: Container(
                  height: 2,
                  color: Colors.deepPurpleAccent,
                ),
                onChanged: (newValue) {
                  setState(() {
                    quality = newValue!;
                  });
                },
                items: [
                  VideoQuality.DefaultQuality,
                  VideoQuality.HighestQuality,
                  VideoQuality.LowQuality,
                  VideoQuality.MediumQuality,
                  VideoQuality.Res1280x720Quality,
                  VideoQuality.Res1920x1080Quality,
                  VideoQuality.Res640x480Quality,
                  VideoQuality.Res960x540Quality,
                ].map<DropdownMenuItem<VideoQuality>>((value) {
                  return DropdownMenuItem<VideoQuality>(
                    value: value,
                    child: Text(value.toString()),
                  );
                }).toList(),
              ),
              ElevatedButton.icon(
                  onPressed: () =>
                      videoBloc.add(CompressVideo(quality: quality)),
                  icon: const Icon(Icons.add),
                  label: const Text('Choose'))
            ],
          ),
          Expanded(
            child: Center(
              child: BlocConsumer<VideoBloc, VideoState>(
                  bloc: videoBloc,
                  builder: (context, state) {
                    if (state is VideoInitial) {
                      return const Text(
                        'Select a file from floating action button',
                      );
                    } else if (state is LoadingState) {
                      if (state.loaderstate == LoaderState.compressing) {
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: SizedBox(
                                height: 100,
                                width: 100,
                                child: CircularProgressIndicator(
                                  value: video_progress / 100,
                                  backgroundColor: Colors.green[100],
                                  valueColor: const AlwaysStoppedAnimation(
                                      Colors.green),
                                  strokeWidth: 4,
                                ),
                              ),
                            ),
                            Text(video_progress.toStringAsFixed(2) + '%'),
                          ],
                        );
                      }
                      return const SizedBox(
                          height: 100,
                          width: 100,
                          child: CircularProgressIndicator(
                            color: Colors.green,
                          ));
                    } else if (state is VideoCompressed) {
                      developer.log(state.mediaInfo!.file!.path);
                      developer.log(state.fileSize);
                      if (state.success) {
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Video compressed. Size: ${state.fileSize} ',
                                style: Theme.of(context).textTheme.headline6),
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: SizedBox(
                                height: 400,
                                child: AspectRatio(
                                  aspectRatio: _controller.value.aspectRatio,
                                  child: VideoPlayer(_controller),
                                ),
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ElevatedButton(
                                    child: Icon(
                                      _controller.value.isPlaying
                                          ? Icons.pause
                                          : Icons.play_arrow,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _controller.value.isPlaying
                                            ? _controller.pause()
                                            : _controller.play();
                                      });
                                    }),
                                const SizedBox(
                                  width: 30,
                                ),
                                ElevatedButton(
                                    onPressed: () async {
                                      Directory? dir =
                                          await getExternalStorageDirectory();

                                      developer.log(dir!
                                          .parent.parent.parent.parent.path);

                                      final newFile =
                                          await state.mediaInfo!.file!.copy(dir
                                                  .parent
                                                  .parent
                                                  .parent
                                                  .parent
                                                  .path +
                                              '/video_compress' +
                                              DateTime.now()
                                                  .microsecondsSinceEpoch
                                                  .toString() +
                                              '.mp4');
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(SnackBar(
                                              content: Text(
                                                  'Viceo saved ${newFile.path}')));
                                    },
                                    child: const Icon(Icons.save))
                              ],
                            )
                          ],
                        );
                      } else {
                        return Text('Unable to compress.',
                            style: Theme.of(context).textTheme.headline6);
                      }
                    }
                    return const CircularProgressIndicator();
                  },
                  listener: (context, state) {
                    if (state is VideoCompressed) {
                      if (state.success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                    Text('video compressed successfully')));
                        _subscription.unsubscribe();
                        _controller =
                            VideoPlayerController.file(state.mediaInfo!.file!)
                              ..initialize().then((_) {
                                // Ensure the first frame is shown after the video is initialized, even before the play button has been pressed.
                                setState(() {});
                              });
                        // videoBloc
                        //     .add(UploadVideo(file: state.mediaInfo!.file!));
                        startTimer();
                      }
                    } else if (state is VideoUploaded) {
                      if (state.success) {
                        _controller = VideoPlayerController.network(state.url)
                          ..initialize().then((_) {
                            // Ensure the first frame is shown after the video is initialized, even before the play button has been pressed.
                            setState(() {});
                          });
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('video Uploaded successfully')));
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('video not Uploaded')));
                      }
                    }
                  }),
            ),
          ),
        ]) // This trailing comma makes auto-formatting nicer for build methods.
            ));
  }
}
