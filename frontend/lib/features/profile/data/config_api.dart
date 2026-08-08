import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppConfig {
  const AppConfig({
    required this.enableStreamMasking,
    required this.showOovMap,
    required this.showNmmHints,
    this.sseTimeoutSeconds = 8,
  });

  final bool enableStreamMasking;
  final bool showOovMap;
  final bool showNmmHints;
  final int sseTimeoutSeconds;
}

class ConfigApi {
  Future<AppConfig> fetch() async {
    return const AppConfig(
      enableStreamMasking: true,
      showOovMap: true,
      showNmmHints: true,
      sseTimeoutSeconds: 8,
    );
  }
}

final configApiProvider = Provider<ConfigApi>((ref) => ConfigApi());
