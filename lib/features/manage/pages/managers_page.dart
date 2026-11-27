import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/widgets/yb_widgets.dart';
import '../../club/pages/club_view.dart';
import '../../pb/state/providers.dart';
import '../data/manage_models.dart';
import '../state/manage_providers.dart';
import 'manage_widgets.dart';

/// Pesan undangan pengurus yang dikirim lewat WhatsApp.
String coManagerInviteMessage(String name, String pbName) =>
    'Halo ${name.split(' ').first}, kamu diundang jadi pengurus $pbName di YukBadmin. '
    'Buka YukBadmin dan masuk dengan nomor WhatsApp ini untuk menerima undangan.';

/// K17 Pengurus PB: pemilik dan pengurus lain yang ikut mengelola.
class ManagersPage extends ConsumerWidget {
  const ManagersPage({super.key});

  Future<void> _resend(
    BuildContext context,
    String pbName,
    CoManager manager,
  ) async {
    final ok = await openWhatsApp(
      manager.whatsapp,
      coManagerInviteMessage(manager.name, pbName),
    );
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'WhatsApp tidak bisa dibuka. Pastikan WhatsApp terpasang, lalu coba lagi.',
          ),
        ),
      );
    }
  }

  Future<void> _remove(
    BuildContext context,
    WidgetRef ref,
    CoManager manager,
  ) async {
    final ok = await confirmDestructive(
      context,
      title: manager.status == CoManagerStatus.diundang
          ? 'Batalkan undangan ${manager.name}?'
          : 'Keluarkan ${manager.name}?',
      message: manager.status == CoManagerStatus.diundang
          ? 'Tautan undangan yang sudah terkirim tidak bisa dipakai lagi.'
          : '${manager.name} tidak bisa lagi mengubah data PB. Data yang sudah dicatatnya tetap tersimpan.',
      confirmLabel: manager.status == CoManagerStatus.diundang
          ? 'Batalkan undangan'
          : 'Keluarkan',
    );
    if (ok) ref.read(manageProvider.notifier).removeCoManager(manager.id);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(manageProvider);
    final user = ref.watch(sessionProvider);
    final pb = state.pb;
    if (pb == null) return const SizedBox.shrink();

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            const PageHeader(title: 'Pengurus PB'),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: YbColors.accentSoft,
                borderRadius: BorderRadius.circular(YbRadius.md),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Siapa bisa mengubah apa',
                    style: YbText.body(weight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  for (final line in const [
                    'Pengurus bisa mengubah profil PB, member, jadwal, kehadiran, dan iuran.',
                    'Hanya pemilik yang bisa mengundang atau mengeluarkan pengurus.',
                    'Member hanya bisa melihat jadwal dan iurannya sendiri.',
                  ])
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Icon(
                              Icons.check_circle_outline,
                              size: 16,
                              color: YbColors.success,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              line,
                              style: YbText.label(color: YbColors.ink),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            YbCard(
              child: Row(
                children: [
                  YbAvatar(user?.initials ?? '?', accent: true),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.name ?? pb.manager.name,
                          style: YbText.body(size: 15, weight: FontWeight.w700),
                        ),
                        Text(
                          displayWhatsapp(pb.manager.whatsapp),
                          style: YbText.label(),
                        ),
                        const SizedBox(height: 4),
                        const YbTag('Kamu · Pemilik', tone: YbTagTone.primary),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            if (state.coManagers.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Belum ada pengurus lain. Undang rekanmu supaya pencatatan tidak bergantung pada satu orang.',
                  style: YbText.body(color: YbColors.muted),
                ),
              ),
            for (final c in state.coManagers) ...[
              YbCard(
                padding: const EdgeInsets.fromLTRB(14, 10, 4, 10),
                child: Row(
                  children: [
                    YbAvatar(c.initials),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            c.name,
                            style: YbText.body(
                              size: 15,
                              weight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            displayWhatsapp(c.whatsapp),
                            style: YbText.label(),
                          ),
                          const SizedBox(height: 4),
                          c.status == CoManagerStatus.aktif
                              ? const YbTag(
                                  'Aktif',
                                  tone: YbTagTone.success,
                                  icon: Icons.check,
                                )
                              : const YbTag(
                                  'Menunggu diterima',
                                  tone: YbTagTone.accent,
                                ),
                        ],
                      ),
                    ),
                    if (c.status == CoManagerStatus.diundang)
                      IconButton(
                        tooltip: 'Kirim ulang undangan ke ${c.name}',
                        onPressed: () => _resend(context, pb.name, c),
                        icon: Icon(
                          Icons.send_outlined,
                          size: 20,
                          color: YbColors.ink,
                        ),
                      ),
                    IconButton(
                      tooltip: c.status == CoManagerStatus.diundang
                          ? 'Batalkan undangan ${c.name}'
                          : 'Keluarkan ${c.name}',
                      onPressed: () => _remove(context, ref, c),
                      icon: Icon(
                        Icons.person_remove_outlined,
                        size: 20,
                        color: YbColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
      bottomNavigationBar: BottomActionBar(
        children: [
          Expanded(
            child: FilledButton.icon(
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                showDragHandle: true,
                builder: (_) => const _InviteSheet(),
              ),
              icon: const Icon(Icons.person_add_alt_1_outlined, size: 20),
              label: const Text('Undang pengurus'),
            ),
          ),
        ],
      ),
    );
  }
}

/// K18 Undang pengurus.
class _InviteSheet extends ConsumerStatefulWidget {
  const _InviteSheet();

  @override
  ConsumerState<_InviteSheet> createState() => _InviteSheetState();
}

class _InviteSheetState extends ConsumerState<_InviteSheet> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _whatsapp = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _whatsapp.dispose();
    super.dispose();
  }

  String? _whatsappError(String? input) {
    final number = normalizeWhatsapp(input ?? '');
    if (number == null) {
      return 'Isi nomor ponsel yang benar, misalnya 0812 3456 7890.';
    }
    final state = ref.read(manageProvider);
    if (number == state.pb?.manager.whatsapp ||
        state.coManagers.any((c) => c.whatsapp == number)) {
      return 'Nomor ini sudah terdaftar sebagai pengurus.';
    }
    return null;
  }

  Future<void> _invite() async {
    if (!_form.currentState!.validate()) return;
    final pbName = ref.read(manageProvider).pb?.name ?? 'PB';
    final manager = ref
        .read(manageProvider.notifier)
        .inviteCoManager(
          name: _name.text,
          whatsapp: normalizeWhatsapp(_whatsapp.text)!,
        );
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    final ok = await openWhatsApp(
      manager.whatsapp,
      coManagerInviteMessage(manager.name, pbName),
    );
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          ok ? 'Undangan untuk ${manager.name} dicatat' : 'Undangan dicatat, tapi WhatsApp tidak bisa dibuka. Kirim ulang dari daftar pengurus.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          12 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Undang pengurus', style: YbText.display(size: 22)),
              const SizedBox(height: 6),
              Text(
                'Undangan dikirim lewat WhatsApp. Setelah diterima, dia bisa ikut mencatat member, kehadiran, dan iuran.',
                style: YbText.label(),
              ),
              const SizedBox(height: 16),
              LabeledField(
                label: 'Nama',
                child: TextFormField(
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  validator: (v) => (v ?? '').trim().length < 2
                      ? 'Isi nama pengurus, minimal 2 huruf.'
                      : null,
                ),
              ),
              LabeledField(
                label: 'Nomor WhatsApp',
                child: TextFormField(
                  controller: _whatsapp,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9+ -]')),
                  ],
                  decoration: const InputDecoration(hintText: '0812 3456 7890'),
                  validator: _whatsappError,
                ),
              ),
              FilledButton.icon(
                onPressed: _invite,
                icon: const Icon(Icons.chat_bubble_outline, size: 18),
                label: const Text('Kirim undangan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// K20 Lihat sebagai member: pilih member untuk dipratinjau.
class MemberPreviewPickPage extends ConsumerWidget {
  const MemberPreviewPickPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final members = [...ref.watch(manageProvider).members]
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            const PageHeader(title: 'Lihat sebagai member'),
            const SizedBox(height: 6),
            Text(
              'Pilih member untuk melihat jadwal dan iuran dari sisi mereka. Member tidak bisa mengubah data, hanya menjawab ikut dan mengirim bukti transfer.',
              style: YbText.label(),
            ),
            const SizedBox(height: 14),
            if (members.isEmpty)
              YbEmptyState(
                icon: Icons.people_outline,
                title: 'Belum ada member',
                message: 'Tambah member dulu, lalu lihat halaman PB dari sisi mereka.',
                actionLabel: 'Tambah member',
                onAction: () => context.push('/member/baru'),
              ),
            for (final m in members) ...[
              YbCard(
                onTap: () => context.push('/kelola/lihat-member/${m.id}'),
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
                          ),
                          Text(m.typeShort, style: YbText.label()),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: YbColors.muted),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }
}

/// Pratinjau halaman PB dari sisi satu member (tampilan sama dengan P19).
class MemberPreviewPage extends ConsumerWidget {
  const MemberPreviewPage({super.key, required this.memberId});

  final String memberId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(manageProvider);
    final pb = state.pb;
    final member = state.memberById(memberId);
    final now = ref.watch(nowProvider)();
    final notifier = ref.read(manageProvider.notifier);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            PageHeader(
              title: member == null
                  ? 'Lihat sebagai member'
                  : 'Sebagai ${member.name.split(' ').first}',
            ),
            const SizedBox(height: 14),
            if (pb == null || member == null)
              YbEmptyState(
                icon: Icons.person_off_outlined,
                title: 'Member ini sudah tidak ada',
                message: 'Mungkin sudah dihapus. Pilih member lain.',
                actionLabel: 'Kembali',
                onAction: () => context.pop(),
              )
            else ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: YbColors.primarySoft,
                  borderRadius: BorderRadius.circular(YbRadius.md),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.visibility_outlined,
                      size: 18,
                      color: YbColors.primaryDark,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Begini ${pb.name} terlihat oleh ${member.name}. Jawaban dan bukti yang kamu isi di sini dicatat atas nama ${member.name.split(' ').first}.',
                        style: YbText.label(color: YbColors.primaryDark),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text(pb.name, style: YbText.display(size: 22)),
              const SizedBox(height: 8),
              ClubMemberView(
                pb: pb,
                memberId: member.id,
                type: member.type,
                events: state.events,
                now: now,
                showContact: false,
                onRsvp: (eventId, r) => notifier.setRsvp(eventId, member.id, r),
                onProof: (eventId, path) =>
                    notifier.submitProof(eventId, member.id, path),
                onRefundRequest: (eventId, reason) =>
                    notifier.requestRefund(eventId, member.id, reason),
                system: state.duesSystem,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
