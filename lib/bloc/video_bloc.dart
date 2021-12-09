import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:bloc/bloc.dart';
import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:video_compress/video_compress.dart';
import 'dart:developer' as developer;
// ignore: library_prefixes
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart' as imagePicker;
import 'package:video_compression/utility/format_bytes.dart';
import 'package:video_player/video_player.dart';
part 'video_event.dart';
part 'video_state.dart';

class VideoBloc extends Bloc<VideoEvent, VideoState> {
  VideoBloc() : super(VideoInitial()) {
    on<CompressVideo>((event, emit) async {
      File file;
      MediaInfo? mediaInfo;
      String fileSize;
      try {
        final picker = imagePicker.ImagePicker();

        // ignore: deprecated_member_use
        imagePicker.XFile? video =
            await picker.pickVideo(source: imagePicker.ImageSource.gallery);
        file = File(video!.path);
        await VideoCompress.setLogLevel(0);
        emit(LoadingState(loaderstate: LoaderState.compressing));
        mediaInfo = await VideoCompress.compressVideo(
          file.path,
          quality: event.quality,
          deleteOrigin: false,
          includeAudio: true,
        );
        fileSize = formatBytes(mediaInfo!.filesize!, 2);
        emit(VideoCompressed(
            mediaInfo: mediaInfo, success: true, fileSize: fileSize));

      } catch (e, t) {
        developer.log(e.toString());
        developer.log(t.toString());
        emit(VideoCompressed(
            mediaInfo: null, success: false, fileSize: '$e, $t'));
      }
    });

    on<UploadVideo>((event, emit) async {
      emit(LoadingState(loaderstate: LoaderState.compressing));
      try {
        // var res = await uploadVideo(event.file);
        // .then((value) {

      } catch (e, t) {
        // }).onError((error, stackTrace) {
        developer.log('video not uploaded');
        developer.log('$e, $t');
        emit(VideoUploaded(
          size: 2,
          url: 'dfg',
          success: false,
        ));
        // });
        // });
      }
    });
  }

  Future<String> uploadVideo(File file) async {
    // send a request to get image link
    try {
      var bytes = await file.readAsBytes();
      String encodedFile = base64.encode(bytes);

      final extension = p.extension(file.path);
      var response = await http.post(
          Uri.parse(
              'https://753hgssmyb.execute-api.ap-south-1.amazonaws.com/testing/post-file'),
          headers: {
            'Accept': '*/*',
          },
          body: json.encode({
            "project_name": "infoflight-data",
            "file_extension": extension.replaceFirst('.', ""),
            "file_content": encodedFile
          }));

      Map<String, dynamic> data = json.decode(response.body);
      String imageLink = (data['data'] as Map)['file_url'];
      return imageLink;
    } catch (e, s) {
      developer.log(e.toString());
      developer.log(s.toString());
    }
    return 'null';
    // String imageLink = (data['data'] as Map)['file_url'];
  }
}
