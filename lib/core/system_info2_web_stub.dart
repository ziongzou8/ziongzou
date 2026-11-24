class SysInfo {
  static int getTotalPhysicalMemory() => _unavailable();
  static int getAvailablePhysicalMemory() => _unavailable();
  static int getTotalStorage() => _unavailable();
  static int getFreeStorage() => _unavailable();

  static String get rawKernelArchitecture => _unavailable();
  static List<WebCore> get cores => const [];
}

Never _unavailable() => throw UnsupportedError(
      'System performance metrics are not available in a web browser.',
    );

class WebCore {
  const WebCore();

  String get name => '';
}
