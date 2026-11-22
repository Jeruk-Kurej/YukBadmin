import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../app/tours.dart';
import '../../../core/widgets/photo.dart';
import '../../../core/widgets/yb_widgets.dart';
import '../../pb/data/pb_models.dart';
import '../data/manage_models.dart';
import '../state/manage_providers.dart';
import 'manage_widgets.dart';

YbTag memberTag(Member m) => YbTag(
  m.typeShort,
  tone: m.type == MemberType.tetap ? YbTagTone.primarySoft : YbTagTone.accent,
);

/// K5 Daftar member.
class MembersPage extends ConsumerStatefulWidget {
  const MembersPage({super.key});

  @override
  ConsumerState<MembersPage> createState() => _MembersPageState();
}

class _MembersPageState extends ConsumerState<MembersPage> {
  final _search = TextEditingController();
  MemberType? _type;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(manageProvider.select((s) => s.members));
    final q = _search.text.trim().toLowerCase();
    final shown =
        all
            .where((m) => _type == null || m.type == _type)
            .where((m) => q.isEmpty || m.name.toLowerCase().contains(q))
            .toList()
          ..sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          );
    int count(MemberType t) => all.where((m) => m.type == t).length;

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          PageHeader(
            title: 'Member',
            back: false,
            trailing: OutlinedButton.icon(
              key: TourKeys.membersAdd,
              onPressed: () => context.push('/member/baru'),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Tambah'),
            ),
          ),
          const SizedBox(height: 14),
          if (all.isEmpty)
            YbEmptyState(
              icon: Icons.people_outline,
              title: 'Belum ada member',
              message: 'Tambah satu per satu, atau tempel daftar lama dari chat supaya langsung terisi.',
              actionLabel: 'Impor dari catatan',
              onAction: () => context.push('/impor'),
            )
          else ...[
            TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              style: YbText.body(size: 15),
              decoration: InputDecoration(
                hintText: 'Cari nama member',
                prefixIcon: Icon(Icons.search, color: YbColors.ink),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                YbChoiceChip(
                  label: 'Semua ${all.length}',
                  selected: _type == null,
                  onTap: () => setState(() => _type = null),
                ),
                YbChoiceChip(
                  label: 'Tetap ${count(MemberType.tetap)}',
                  selected: _type == MemberType.tetap,
                  onTap: () => setState(() => _type = MemberType.tetap),
                ),
                YbChoiceChip(
                  label: 'Insidental ${count(MemberType.insidental)}',
                  selected: _type == MemberType.insidental,
                  onTap: () => setState(() => _type = MemberType.insidental),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (shown.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'Tidak ada member yang cocok dengan pencarian ini.',
                  textAlign: TextAlign.center,
                  style: YbText.body(color: YbColors.muted),
                ),
              ),
            for (final m in shown) ...[
              YbCard(
                padding: const EdgeInsets.all(12),
                onTap: () => context.push('/member/${m.id}'),
                child: Row(
                  children: [
                    YbAvatar(m.initials, photoPath: m.photoPath),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            m.name,
                            style: YbText.body(
                              size: 15,
                              weight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            m.level == null
                                ? 'Level belum diisi'
                                : 'Level ${m.level!.label}',
                            style: YbText.label(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    memberTag(m),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 4),
            FilledButton.icon(
              onPressed: () => context.push('/impor'),
              icon: const Icon(Icons.upload_outlined, size: 20),
              label: const Text('Impor dari catatan'),
            ),
          ],
        ],
      ),
    );
  }
}

/// K6 Tambah / detail member. [memberId] null berarti menambah baru.
class MemberFormPage extends ConsumerStatefulWidget {
  const MemberFormPage({super.key, this.memberId});

  final String? memberId;

  @override
  ConsumerState<MemberFormPage> createState() => _MemberFormPageState();
}

class _MemberFormPageState extends ConsumerState<MemberFormPage> {
  final _form = GlobalKey<FormState>();
  late final Member? _original = widget.memberId == null
      ? null
      : ref.read(manageProvider).memberById(widget.memberId!);
  late final _name = TextEditingController(text: _original?.name ?? '');
  late final _whatsapp = TextEditingController(
    text: _original?.whatsapp == null
        ? ''
        : displayWhatsapp(_original!.whatsapp!),
  );
  late Level? _level = _original?.level;
  late MemberType _type = _original?.type ?? MemberType.tetap;
  late String? _photoPath = _original?.photoPath;

  @override
  void dispose() {
    _name.dispose();
    _whatsapp.dispose();
    super.dispose();
  }

  void _save() {
    if (!_form.currentState!.validate()) return;
    final notifier = ref.read(manageProvider.notifier);
    final number = _whatsapp.text.trim().isEmpty
        ? null
        : normalizeWhatsapp(_whatsapp.text);
    if (_original == null) {
      notifier.addMember(
        name: _name.text,
        type: _type,
        level: _level,
        whatsapp: number,
        photoPath: _photoPath,
      );
    } else {
      notifier.updateMember(
        Member(
          id: _original.id,
          name: _name.text.trim(),
          type: _type,
          level: _level,
          whatsapp: number,
          photoPath: _photoPath,
        ),
      );
    }
    context.pop();
  }

  Future<void> _delete() async {
    final ok = await confirmDestructive(
      context,
      title: 'Hapus ${_original!.name}?',
      message: 'Catatan kehadiran dan iuran member ini di semua sesi ikut terhapus dan tidak bisa dikembalikan.',
      confirmLabel: 'Hapus member',
    );
    if (!ok || !mounted) return;
    ref.read(manageProvider.notifier).removeMember(_original.id);
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final editing = _original != null;
    if (widget.memberId != null && !editing) {
      return Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const PageHeader(title: 'Detail member'),
                const SizedBox(height: 20),
                YbEmptyState(
                  icon: Icons.person_off_outlined,
                  title: 'Member ini sudah tidak ada',
                  message: 'Mungkin sudah dihapus. Kembali ke daftar member.',
                  actionLabel: 'Kembali',
                  onAction: () => context.pop(),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: Form(
                key: _form,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  children: [
                    PageHeader(
                      title: editing ? 'Detail member' : 'Tambah member',
                      trailing: editing
                          ? IconButton(
                              tooltip: 'Hapus member',
                              onPressed: _delete,
                              icon: Icon(
                                Icons.delete_outline,
                                color: YbColors.primary,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: Column(
                        children: [
                          PhotoCircle(
                            path: _photoPath,
                            tooltip: 'Ubah foto member',
                            fallback: ValueListenableBuilder(
                              valueListenable: _name,
                              builder: (_, value, _) =>
                                  YbAvatar(initialsOf(value.text), size: 76),
                            ),
                            onTap: () async {
                              final change = await changePhoto(
                                context,
                                ref,
                                title: 'Foto member',
                                hasPhoto: _photoPath != null,
                              );
                              if (change != null) {
                                setState(() => _photoPath = change.path);
                              }
                            },
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _photoPath == null ? 'Tambah foto' : 'Ubah foto',
                            style: YbText.label(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    LabeledField(
                      label: 'Nama lengkap',
                      child: TextFormField(
                        controller: _name,
                        autofocus: !editing,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        validator: (v) {
                          final name = (v ?? '').trim();
                          if (name.length < 2) return 'Isi nama member.';
                          final taken = ref
                              .read(manageProvider)
                              .members
                              .any(
                                (m) =>
                                    m.id != _original?.id &&
                                    m.name.toLowerCase() == name.toLowerCase(),
                              );
                          return taken
                              ? 'Sudah ada member dengan nama ini. Tambahkan pembeda, misalnya nama belakang.'
                              : null;
                        },
                      ),
                    ),
                    LabeledField(
                      label: 'Nomor WhatsApp (opsional)',
                      helper: 'Dipakai untuk mengirim pengingat iuran.',
                      child: TextFormField(
                        controller: _whatsapp,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'[0-9+ -]'),
                          ),
                        ],
                        decoration: const InputDecoration(
                          hintText: '0813 1111 2222',
                        ),
                        validator: (v) =>
                            (v ?? '').trim().isNotEmpty &&
                                normalizeWhatsapp(v!) == null
                            ? 'Nomor belum benar, misalnya 0813 1111 2222.'
                            : null,
                      ),
                    ),
                    Text('Level', style: YbText.label()),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final level in Level.values)
                          YbChoiceChip(
                            round: true,
                            label: level.label,
                            selected: _level == level,
                            onTap: () => setState(
                              () => _level = _level == level ? null : level,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text('Jenis member', style: YbText.label()),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final type in MemberType.values)
                          YbChoiceChip(
                            label: type == MemberType.tetap
                                ? 'Tetap'
                                : 'Insidental',
                            selected: _type == type,
                            onTap: () => setState(() => _type = type),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            BottomActionBar(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: _save,
                    child: const Text('Simpan'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
