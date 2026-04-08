/// Stub implementation — should never be used at runtime.
/// The conditional import resolves to either the web or mobile variant.

Future<bool> exportJsonFile(String jsonString, String fileName) async {
  throw UnsupportedError('Platform not supported');
}

Future<String?> pickJsonFile() async {
  throw UnsupportedError('Platform not supported');
}

Future<bool> exportMultipleFiles({
  required String clientsCsv,
  required String appointmentsCsv,
  required String notesTxt,
  required String dateStr,
}) async {
  throw UnsupportedError('Platform not supported');
}
