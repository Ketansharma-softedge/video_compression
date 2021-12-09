part of 'video_bloc.dart';

abstract class VideoEvent extends Equatable {
  const VideoEvent();

  @override
  List<Object> get props => [];
}

class CompressVideo extends VideoEvent {
  VideoQuality quality;
  @override
  List<Object> get props => [quality];
  CompressVideo({required this.quality});
}

class UploadVideo extends VideoEvent {
 
  File file;
  @override
  List<Object> get props => [file];
  UploadVideo({required this.file,});
}
