import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/config_api.dart';

final configProvider = StateNotifierProvider<ConfigNotifier, AsyncValue<AppConfig>>((ref) {
  return ConfigNotifier(ref.watch(configApiProvider));
});

class ConfigNotifier extends StateNotifier<AsyncValue<AppConfig>> {
  ConfigNotifier(this._api) : super(const AsyncLoading()) {
    refresh();
  }

  final ConfigApi _api;

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_api.fetch);
  }
}
