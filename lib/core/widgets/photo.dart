import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../app/theme.dart';
import '../../features/manage/pages/manage_widgets.dart'
    show confirmDestructive;

enum PhotoSource { camera, gallery }

/// Mengambil foto dan menyimpannya di folder app. Mengembalikan path berkas,
/// atau null kalau pengguna batal. Nanti diganti unggah ke Supabase Storage.
abstract interface class PhotoPicker {
  Future<String?> pick(PhotoSource source);
}

class DevicePhotoPicker implements PhotoPicker {
  const DevicePhotoPicker();

  @override
  Future<String?> pick(PhotoSource source) async {
    final file = await ImagePicker().pickImage(
      source: source == PhotoSource.camera
          ? ImageSource.camera
          : ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (file == null) return null;
    // Berkas dari picker bisa dihapus sistem, jadi salin ke folder app.
    final dir = Directory(
      p.join((await getApplicationDocumentsDirectory()).path, 'foto'),
    );
    await dir.create(recursive: true);
    final target = p.join(
      dir.path,
      '${DateTime.now().microsecondsSinceEpoch}${p.extension(file.path)}',
    );
    await File(file.path).copy(target);
    return target;
  }
}

final photoPickerProvider = Provider<PhotoPicker>(
  (ref) => const DevicePhotoPicker(),
);

/// Hasil memilih foto: path baru, atau null kalau foto dihapus.
typedef PhotoChange = ({String? path});

/// Menampilkan pilihan kamera, galeri, atau hapus foto, lalu menjalankannya.
/// Mengembalikan null kalau pengguna batal.
Future<PhotoChange?> changePhoto(
  BuildContext context,
  WidgetRef ref, {
  required String title,
  bool hasPhoto = false,
}) async {
  final choice = await showModalBottomSheet<String>(
    context: context,
    useRootNavigator: true,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text(title, style: YbText.display(size: 19)),
          ),
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: Text('Ambil foto', style: YbText.body(size: 15)),
            onTap: () => Navigator.of(context).pop('camera'),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: Text('Pilih dari galeri', style: YbText.body(size: 15)),
            onTap: () => Navigator.of(context).pop('gallery'),
          ),
          if (hasPhoto)
            ListTile(
              leading: Icon(Icons.delete_outline, color: YbColors.primary),
              title: Text(
                'Hapus foto',
                style: YbText.body(size: 15, color: YbColors.primary),
              ),
              onTap: () => Navigator.of(context).pop('remove'),
            ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
  if (choice == null || !context.mounted) return null;

  if (choice == 'remove') {
    final ok = await confirmDestructive(
      context,
      title: 'Hapus foto ini?',
      message: 'Foto dihapus dari profil. Kamu bisa menambahkan foto lain kapan saja.',
      confirmLabel: 'Hapus foto',
    );
    return ok ? (path: null) : null;
  }

  try {
    final path = await ref
        .read(photoPickerProvider)
        .pick(choice == 'camera' ? PhotoSource.camera : PhotoSource.gallery);
    return path == null ? null : (path: path);
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Foto tidak bisa dibuka. Izinkan akses kamera atau galeri di Pengaturan, lalu coba lagi.',
          ),
        ),
      );
    }
    return null;
  }
}

/// Folder dokumen app, diisi sekali di `main`.
String? photoDocumentsDir;

/// Path foto yang masih bisa dibuka. Di iOS letak folder app bisa berubah
/// setelah update, jadi foto yang disalin app dicari lagi berdasarkan nama
/// berkasnya di folder foto yang sekarang.
String resolvePhotoPath(String path, String? documentsDir) {
  if (documentsDir == null ||
      p.basename(p.dirname(path)) != 'foto' ||
      File(path).existsSync()) {
    return path;
  }
  return p.join(documentsDir, 'foto', p.basename(path));
}

/// Foto dari berkas di perangkat. Kalau [path] kosong atau berkasnya hilang,
/// [fallback] yang ditampilkan.
class YbPhoto extends StatelessWidget {
  const YbPhoto({
    super.key,
    required this.path,
    required this.fallback,
    this.fit = BoxFit.cover,
  });

  final String? path;
  final Widget fallback;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    if (path == null || path!.isEmpty) return fallback;
    return Image.file(
      File(resolvePhotoPath(path!, photoDocumentsDir)),
      fit: fit,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (_, _, _) => fallback,
    );
  }
}

/// Lingkaran foto dengan tombol kamera kecil, untuk logo dan foto profil.
class PhotoCircle extends StatelessWidget {
  const PhotoCircle({
    super.key,
    required this.path,
    required this.fallback,
    required this.onTap,
    required this.tooltip,
    this.size = 76,
  });

  final String? path;
  final Widget fallback;
  final VoidCallback onTap;
  final String tooltip;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        label: tooltip,
        excludeSemantics: true,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: size,
            height: size,
            child: Stack(
              children: [
                ClipOval(
                  child: SizedBox(
                    width: size,
                    height: size,
                    child: YbPhoto(path: path, fallback: fallback),
                  ),
                ),
                // Tanpa foto, isi lingkaran sudah berupa ikon kamera; lencana
                // hanya dipakai kalau ada foto atau inisial.
                if (path != null || fallback is! PhotoPlaceholder)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: YbColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: YbColors.surface, width: 2),
                      ),
                      child: const Icon(
                        Icons.photo_camera_outlined,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Lingkaran ikon kamera, dipakai sebagai isi [PhotoCircle] tanpa foto.
class PhotoPlaceholder extends StatelessWidget {
  const PhotoPlaceholder({super.key, this.icon = Icons.photo_camera_outlined});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: YbColors.primarySoft,
      alignment: Alignment.center,
      child: Icon(icon, color: YbColors.primary, size: 28),
    );
  }
}

/// Deretan foto yang bisa ditambah dan dihapus, misalnya foto PB.
class PhotoStrip extends ConsumerWidget {
  const PhotoStrip({
    super.key,
    required this.paths,
    required this.onChanged,
    this.max = 6,
  });

  final List<String> paths;
  final ValueChanged<List<String>> onChanged;
  final int max;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Future<void> add() async {
      final change = await changePhoto(context, ref, title: 'Tambah foto PB');
      final path = change?.path;
      if (path != null) onChanged([...paths, path]);
    }

    Future<void> remove(int index) async {
      final ok = await confirmDestructive(
        context,
        title: 'Hapus foto ini?',
        message: 'Foto tidak lagi tampil di halaman PB.',
        confirmLabel: 'Hapus foto',
      );
      if (ok) onChanged([...paths]..removeAt(index));
    }

    return SizedBox(
      height: 84,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: paths.length + (paths.length < max ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          if (i == paths.length) {
            return Tooltip(
              message: 'Tambah foto',
              child: InkWell(
                borderRadius: BorderRadius.circular(YbRadius.sm),
                onTap: add,
                child: Container(
                  width: 84,
                  decoration: BoxDecoration(
                    color: YbColors.surface,
                    borderRadius: BorderRadius.circular(YbRadius.sm),
                    border: Border.all(color: YbColors.line, width: 1.5),
                  ),
                  child: Icon(
                    Icons.add_a_photo_outlined,
                    color: YbColors.muted,
                  ),
                ),
              ),
            );
          }
          return SizedBox(
            width: 84,
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(YbRadius.sm),
                  child: YbPhoto(
                    path: paths[i],
                    fallback: const PhotoPlaceholder(
                      icon: Icons.broken_image_outlined,
                    ),
                  ),
                ),
                if (i == 0)
                  Positioned(
                    left: 4,
                    bottom: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: YbColors.night.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(YbRadius.pill),
                      ),
                      child: Text(
                        'Sampul',
                        style: YbText.body(size: 10, color: Colors.white),
                      ),
                    ),
                  ),
                Positioned(
                  right: 0,
                  top: 0,
                  child: IconButton(
                    tooltip: 'Hapus foto ${i + 1}',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => remove(i),
                    style: IconButton.styleFrom(
                      backgroundColor: YbColors.surface,
                      fixedSize: const Size(28, 28),
                      minimumSize: const Size(28, 28),
                      padding: EdgeInsets.zero,
                    ),
                    icon: const Icon(Icons.close, size: 16),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Galeri foto untuk dilihat pemain. Ketuk foto untuk memperbesar.
class PhotoGallery extends StatelessWidget {
  const PhotoGallery({super.key, required this.paths});

  final List<String> paths;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 92,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: paths.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) => Semantics(
          button: true,
          label: 'Foto ${i + 1} dari ${paths.length}. Ketuk untuk memperbesar.',
          excludeSemantics: true,
          child: InkWell(
            borderRadius: BorderRadius.circular(YbRadius.sm),
            onTap: () => showDialog<void>(
              context: context,
              builder: (context) => Dialog(
                insetPadding: const EdgeInsets.all(16),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  children: [
                    InteractiveViewer(
                      child: YbPhoto(
                        path: paths[i],
                        fit: BoxFit.contain,
                        fallback: const PhotoPlaceholder(
                          icon: Icons.broken_image_outlined,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 8,
                      top: 8,
                      child: IconButton.filledTonal(
                        tooltip: 'Tutup foto',
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(YbRadius.sm),
              child: SizedBox(
                width: 120,
                child: YbPhoto(
                  path: paths[i],
                  fallback: const PhotoPlaceholder(
                    icon: Icons.broken_image_outlined,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
