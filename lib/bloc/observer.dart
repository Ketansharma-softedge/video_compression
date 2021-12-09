import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:developer' as developer;

class AppBlocObserver extends BlocObserver {
  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    developer.log('$bloc, $error');
    super.onError(bloc, error, stackTrace);
  }

  @override
  void onTransition(Bloc bloc, Transition transition) {
    developer.log('$bloc, $transition');
    super.onTransition(bloc, transition);
  }

  @override
  void onClose(BlocBase bloc) {
    developer.log("Closed: $bloc");
    super.onClose(bloc);
  }
}