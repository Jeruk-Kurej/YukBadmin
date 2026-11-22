import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/data/local_store.dart';

/// Pilihan tampilan pengguna: ikuti sistem, terang, atau gelap.
class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final store = ref.watch(localStoreProvider);
    listenSelf((_, next) => writeCached(store, CacheKeys.themeMode, next.name));
    return readCached(
      store,
      CacheKeys.themeMode,
      (json) => ThemeMode.values.byName(json! as String),
      ThemeMode.system,
    );
  }

  void set(ThemeMode mode) => state = mode;
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

/// Kecerahan yang dipakai untuk [mode] dengan kecerahan sistem [platform].
Brightness resolveBrightness(ThemeMode mode, Brightness platform) =>
    switch (mode) {
      ThemeMode.system => platform,
      ThemeMode.light => Brightness.light,
      ThemeMode.dark => Brightness.dark,
    };
