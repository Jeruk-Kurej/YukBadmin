import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/router.dart';
import 'app/theme.dart';
import 'app/theme_mode.dart';
import 'core/data/local_store.dart';
import 'core/data/supabase_config.dart';
import 'core/widgets/photo.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Cache dibuka sebelum app tampil supaya data tersimpan langsung terbaca.
  final store = await PrefsLocalStore.open();
  photoDocumentsDir = (await getApplicationDocumentsDirectory()).path;
  if (SupabaseConfig.isConfigured) {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.anonKey,
    );
  }
  runApp(
    ProviderScope(
      overrides: [localStoreProvider.overrideWithValue(store)],
      child: const YukBadminApp(),
    ),
  );
}

class YukBadminApp extends ConsumerStatefulWidget {
  const YukBadminApp({super.key});

  @override
  ConsumerState<YukBadminApp> createState() => _YukBadminAppState();
}

class _YukBadminAppState extends ConsumerState<YukBadminApp>
    with WidgetsBindingObserver {
  Brightness? _applied;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Brightness get _wanted => resolveBrightness(
    ref.read(themeModeProvider),
    WidgetsBinding.instance.platformDispatcher.platformBrightness,
  );

  @override
  void didChangePlatformBrightness() => _apply();

  /// Mengganti palet lalu membangun ulang semua widget. Warna YukBadmin
  /// dibaca langsung dari [YbColors], jadi widget yang tidak bergantung pada
  /// Theme juga perlu dibangun ulang. Isian form tetap tersimpan.
  void _apply() {
    final brightness = _wanted;
    if (brightness == _applied) return;
    YbColors.use(brightness);
    _applied = brightness;
    void rebuild(Element element) {
      element.markNeedsBuild();
      element.visitChildren(rebuild);
    }

    if (mounted) (context as Element).visitChildren(rebuild);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(themeModeProvider, (_, _) => _apply());
    if (_applied == null) {
      _applied = _wanted;
      YbColors.use(_applied!);
    }
    final dark = _applied == Brightness.dark;
    return MaterialApp.router(
      title: 'YukBadmin',
      debugShowCheckedModeBanner: false,
      theme: buildYbTheme(),
      routerConfig: ref.watch(routerProvider),
      // Ikon status bar mengikuti latar app. Layar berlatar gelap (Masuk,
      // hero detail PB) menimpanya sendiri.
      builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        child: child!,
      ),
    );
  }
}
