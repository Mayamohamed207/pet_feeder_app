class Interpreter {
  static Future<Interpreter> fromAsset(String path) async {
    throw UnsupportedError('TFLite is not supported on web');
  }

  void run(dynamic input, dynamic output) {
    throw UnsupportedError('TFLite is not supported on web');
  }

  void close() {}
}
