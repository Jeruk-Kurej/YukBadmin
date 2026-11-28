import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Alamat dan kunci publik project Supabase (publishable key `sb_publishable_…`
/// atau anon key lama), diisi saat build:
///
/// ```
/// flutter run --dart-define-from-file=env/dev.json
/// ```
///
/// Tanpa nilai ini app memakai data lokal (seperti sebelum ada Supabase),
/// dan tes otomatis tidak menyentuh jaringan. Kunci `service_role` tidak
/// boleh dipakai di app.
abstract final class SupabaseConfig {
  static const url = String.fromEnvironment('SUPABASE_URL');
  static const anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;
}

/// Klien Supabase, atau null kalau app berjalan dengan data lokal.
/// Tes bisa menimpanya.
final supabaseClientProvider = Provider<SupabaseClient?>(
  (ref) => SupabaseConfig.isConfigured ? Supabase.instance.client : null,
);
