import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/theme.dart';
import '../../../core/widgets/yb_widgets.dart';
import '../data/pb_models.dart';
import '../state/providers.dart';

/// P10 Hubungi pengurus.
Future<void> showContactSheet(BuildContext context, Pb pb) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _ContactSheet(pb: pb),
    );

class _ContactSheet extends ConsumerStatefulWidget {
  const _ContactSheet({required this.pb});

  final Pb pb;

  @override
  ConsumerState<_ContactSheet> createState() => _ContactSheetState();
}

class _ContactSheetState extends ConsumerState<_ContactSheet> {
  late final _message = TextEditingController(text: _defaultMessage());
  String? _error;

  String _defaultMessage() {
    final name = ref.read(sessionProvider)?.firstName ?? '';
    final intro = name.isEmpty
        ? 'Halo'
        : 'Halo ${widget.pb.manager.name}, saya $name';
    return '$intro. Saya baru mulai main badminton dan ingin ikut sesi '
        '${widget.pb.name}. Boleh tahu cara bergabungnya?';
  }

  String get _displayNumber {
    final n = widget.pb.manager.whatsapp;
    return n.startsWith('62') ? '0${n.substring(2)}' : n;
  }

  Future<void> _openWhatsApp() async {
    final text = _message.text.trim();
    if (text.isEmpty) {
      setState(
        () => _error = 'Tulis pesan dulu supaya pengurus tahu maksudmu.',
      );
      return;
    }
    final uri = Uri.https('wa.me', '/${widget.pb.manager.whatsapp}', {
      'text': text,
    });
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
    } else {
      setState(
        () => _error = 'WhatsApp tidak bisa dibuka. Salin nomor pengurus lalu hubungi langsung.',
      );
    }
  }

  Future<void> _copyNumber() async {
    await Clipboard.setData(ClipboardData(text: _displayNumber));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Nomor $_displayNumber disalin')));
  }

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final manager = widget.pb.manager;
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          12 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Tanya pengurus', style: YbText.display(size: 22)),
            const SizedBox(height: 6),
            // Hasil UAT: pemain baru canggung menghubungi orang asing.
            Text(
              'Pengurus PB memang menerima pertanyaan dari calon member. '
              'Kirim pesan dulu untuk tanya jadwal atau coba main sekali, '
              'tidak harus langsung jadi member.',
              style: YbText.body(color: YbColors.muted),
            ),
            const SizedBox(height: 14),
            YbCard(
              child: Row(
                children: [
                  YbAvatar(manager.initials),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          manager.name,
                          style: YbText.body(size: 15, weight: FontWeight.w700),
                        ),
                        Text(
                          'Pengurus ${widget.pb.name} · $_displayNumber',
                          style: YbText.label(),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Salin nomor',
                    onPressed: _copyNumber,
                    icon: Icon(Icons.copy, size: 20, color: YbColors.ink),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Pesan pembuka',
                    style: YbText.body(weight: FontWeight.w700),
                  ),
                ),
                const YbTag('Bisa diubah', tone: YbTagTone.accent),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _message,
              minLines: 3,
              maxLines: 6,
              style: YbText.body(height: 1.5),
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
              decoration: InputDecoration(errorText: _error, errorMaxLines: 3),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _openWhatsApp,
              icon: const Icon(Icons.chat_bubble_outline, size: 20),
              label: const Text('Buka WhatsApp'),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
          ],
        ),
      ),
    );
  }
}
