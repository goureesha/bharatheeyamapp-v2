class ExportService {
  static Future<void> shareCSV({
    required String csvContent,
    required String fileName,
    required String shareText,
  }) async {
    // No-op on web — sharing CSV files is not supported
    throw UnsupportedError('CSV sharing is not supported on web');
  }
}
