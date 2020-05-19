import 'dart:async';

class PageStateBloc {

  final pageStateController = StreamController.broadcast();

  Stream get getStream => pageStateController.stream;

  Sink get getSink => pageStateController.sink;

  void dispose() {
    pageStateController.close(); // close our StreamController
  }
}

