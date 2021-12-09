part of 'video_bloc.dart';

abstract class VideoState extends Equatable {
  const VideoState();

  @override
  List<Object> get props => [];
}

class VideoInitial extends VideoState {
  @override
  List<Object> get props => [];
}

enum LoaderState {
  compressing,
  uploading,
}

class LoadingState extends VideoState {
  LoaderState loaderstate;
  @override
  List<Object> get props => [loaderstate];
  LoadingState({required this.loaderstate});
}

class VideoCompressed extends VideoState {
  bool success;
  MediaInfo? mediaInfo;
  String fileSize;
  @override
  List<Object> get props => [success, mediaInfo!, fileSize];
  VideoCompressed(
      {this.mediaInfo, required this.success, required this.fileSize});
}

class VideoUploaded extends VideoState {
  bool success;
  String url;
   int size;
  @override
  List<Object> get props => [success, url, size];
  VideoUploaded({required this.url, required this.success, required this.size});
}
