import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/widgets/yb_widgets.dart';
import '../manage/pages/manage_widgets.dart' show LabeledField, PageHeader;
import '../pb/state/providers.dart';
import 'state/auth_providers.dart';

/// P1 Masuk.
class LoginPage extends ConsumerWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pbCount = ref.watch(nearbyPbProvider).value?.length;
    final area = ref.watch(preferencesProvider).area;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Hero biru malam, jadi ikon status bar dibuat terang.
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: Column(
          children: [
            Expanded(
              child: ClipPath(
                clipper: _SlantClipper(),
                child: ColoredBox(
                  color: YbColors.night,
                  child: Stack(
                    children: [
                      const Positioned.fill(
                        child: CustomPaint(painter: _HeroLines()),
                      ),
                      Positioned.fill(
                        child: SafeArea(
                          bottom: false,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(24, 16, 24, 72),
                            child: _HeroContent(pbCount: pbCount, area: area),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Column(
                  children: [
                    FilledButton.icon(
                      // Masuk dengan Google butuh server (Supabase Auth).
                      // Sampai itu ada, tombol ini tidak berpura-pura masuk.
                      onPressed: () => ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Masuk dengan Google tersedia setelah app tersambung ke server. Untuk sekarang, pakai email.',
                            ),
                          ),
                        ),
                      icon: const Icon(Icons.account_circle_outlined),
                      label: const Text('Lanjut dengan Google'),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                      ),
                      onPressed: () => context.push('/masuk/email'),
                      icon: const Icon(Icons.mail_outline_rounded),
                      label: const Text('Masuk dengan email'),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Dengan masuk, kamu setuju dengan Syarat dan Ketentuan YukBadmin.',
                      textAlign: TextAlign.center,
                      style: YbText.label(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroContent extends StatelessWidget {
  const _HeroContent({required this.pbCount, required this.area});

  final int? pbCount;
  final String area;

  @override
  Widget build(BuildContext context) {
    // Isi ditaruh di tengah secara vertikal. Di layar pendek atau teks besar,
    // isi diperkecil supaya tidak terpotong.
    return LayoutBuilder(
      builder: (context, box) => SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: SizedBox(
            width: box.maxWidth,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: YbColors.accent,
                    borderRadius: BorderRadius.circular(YbRadius.md),
                  ),
                  child: Icon(
                    Icons.sports_tennis,
                    size: 36,
                    color: YbColors.onAccent,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'YukBadmin',
                  style: YbText.display(size: 46, color: Colors.white),
                ),
                const SizedBox(height: 12),
                Text(
                  'Temukan PB badminton yang pas, lalu main lebih rutin.',
                  style: YbText.body(size: 17, color: Colors.white),
                ),
                const SizedBox(height: 16),
                for (final point in const [
                  'Cari komunitas badminton (PB) sesuai level dan jadwalmu',
                  'Kelola member, kehadiran, dan iuran PB-mu',
                  'Bukan untuk booking lapangan',
                ])
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          point.startsWith('Bukan')
                              ? Icons.do_not_disturb_alt
                              : Icons.check,
                          size: 18,
                          color: YbColors.accent,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            point,
                            style: YbText.body(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (pbCount != null) ...[
                  const SizedBox(height: 18),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$pbCount',
                        style: YbText.display(
                          size: 44,
                          color: YbColors.accent,
                          height: 1,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(
                            'PB aktif di $area',
                            style: YbText.body(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SlantClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) => Path()
    ..lineTo(size.width, 0)
    ..lineTo(size.width, size.height - 48)
    ..lineTo(0, size.height)
    ..close();

  @override
  bool shouldReclip(_SlantClipper oldClipper) => false;
}

/// Garis lapangan tipis dan satu garis kuning di sisi kanan hero.
class _HeroLines extends CustomPainter {
  const _HeroLines();

  @override
  void paint(Canvas canvas, Size size) {
    final thin = Paint()
      ..color = Colors.white.withValues(alpha: 0.14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final left = size.width * 0.56;
    canvas.drawRect(
      Rect.fromLTRB(
        left,
        size.height * 0.2,
        size.width + 2,
        size.height * 0.62,
      ),
      thin,
    );
    canvas.drawLine(
      Offset(left, size.height * 0.34),
      Offset(size.width, size.height * 0.34),
      thin,
    );
    canvas.drawLine(
      Offset(left, size.height * 0.46),
      Offset(size.width, size.height * 0.46),
      thin,
    );
    canvas.drawRect(
      Rect.fromLTWH(size.width - 10, 0, 4, size.height * 0.6),
      Paint()..color = YbColors.accent,
    );
  }

  @override
  bool shouldRepaint(_HeroLines oldDelegate) => false;
}

/// P1a Masuk atau daftar dengan email. Belum tersambung ke server: akun
/// baru ditandai belum terverifikasi sampai Supabase Auth dipasang.
class EmailSignInPage extends ConsumerStatefulWidget {
  const EmailSignInPage({super.key});

  @override
  ConsumerState<EmailSignInPage> createState() => _EmailSignInPageState();
}

class _EmailSignInPageState extends ConsumerState<EmailSignInPage> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  var _newAccount = false;
  var _hidden = true;
  AuthError? _authError;
  var _busy = false;

  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    setState(() => _authError = null);
    if (!_form.currentState!.validate()) return;
    final auth = ref.read(authServiceProvider);
    final email = _email.text.trim();
    setState(() => _busy = true);
    final outcome = _newAccount
        ? await auth.register(
            name: _name.text,
            email: email,
            password: _password.text,
          )
        : await auth.signIn(email: email, password: _password.text);
    if (!mounted) return;
    setState(() => _busy = false);
    final error = outcome.error;
    if (error != null) {
      if (error.onEmail || error.onPassword) {
        setState(() => _authError = error);
      } else {
        _message(error.message);
      }
      return;
    }
    if (outcome.needsVerification) {
      // Akun dibuat; masuk setelah tautan verifikasi di email dibuka.
      _password.clear();
      _switchMode(false);
      _message(
        'Akun dibuat. Buka tautan verifikasi yang kami kirim ke $email, lalu masuk.',
      );
      return;
    }
    context.go(outcome.preferencesDone ? '/beranda' : '/preferensi');
  }

  void _message(String text) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));

  void _switchMode(bool newAccount) => setState(() {
    _newAccount = newAccount;
    _authError = null;
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Form(
          key: _form,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PageHeader(title: _newAccount ? 'Daftar' : 'Masuk'),
                const SizedBox(height: 12),
                YbPageTitle(
                  _newAccount ? 'Buat akun' : 'Masuk dengan email',
                  subtitle: _newAccount
                      ? 'Akun disimpan di HP ini sampai app tersambung ke server.'
                      : 'Pakai email yang sudah terdaftar.',
                ),
                const SizedBox(height: 20),
                YbSegmented<bool>(
                  options: const [
                    (false, 'Masuk', null),
                    (true, 'Daftar', null),
                  ],
                  selected: _newAccount,
                  onChanged: _switchMode,
                ),
                const SizedBox(height: 20),
                if (_newAccount)
                  LabeledField(
                    label: 'Nama',
                    child: TextFormField(
                      controller: _name,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.name],
                      decoration: const InputDecoration(
                        hintText: 'Nama lengkap',
                      ),
                      validator: (v) => (v ?? '').trim().length < 2
                          ? 'Isi namamu, minimal 2 huruf.'
                          : null,
                    ),
                  ),
                LabeledField(
                  label: 'Email',
                  child: TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                    onChanged: (_) {
                      if (_authError != null) setState(() => _authError = null);
                    },
                    forceErrorText: _authError?.onEmail == true
                        ? _authError!.message
                        : null,
                    decoration: const InputDecoration(
                      hintText: 'nama@email.com',
                      errorMaxLines: 3,
                    ),
                    validator: (v) => _emailPattern.hasMatch((v ?? '').trim())
                        ? null
                        : 'Isi email yang benar, misalnya nama@email.com.',
                  ),
                ),
                LabeledField(
                  label: 'Kata sandi',
                  child: TextFormField(
                    controller: _password,
                    obscureText: _hidden,
                    textInputAction: TextInputAction.done,
                    onChanged: (_) {
                      if (_authError != null) setState(() => _authError = null);
                    },
                    forceErrorText: _authError?.onPassword == true
                        ? _authError!.message
                        : null,
                    onFieldSubmitted: (_) => _submit(),
                    autofillHints: [
                      _newAccount
                          ? AutofillHints.newPassword
                          : AutofillHints.password,
                    ],
                    decoration: InputDecoration(
                      hintText: _newAccount ? 'Minimal 8 karakter' : null,
                      errorMaxLines: 3,
                      suffixIcon: IconButton(
                        tooltip: _hidden
                            ? 'Tampilkan kata sandi'
                            : 'Sembunyikan kata sandi',
                        onPressed: () => setState(() => _hidden = !_hidden),
                        icon: Icon(
                          _hidden
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                    validator: (v) {
                      final value = v ?? '';
                      if (!_newAccount) {
                        return value.isEmpty ? 'Isi kata sandimu.' : null;
                      }
                      return value.length < 8
                          ? 'Kata sandi minimal 8 karakter.'
                          : null;
                    },
                  ),
                ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: _submit,
                  child: Text(
                    _busy ? 'Memuat…' : (_newAccount ? 'Buat akun' : 'Masuk'),
                  ),
                ),
                if (!_newAccount)
                  TextButton(
                    onPressed: () => ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Atur ulang kata sandi tersedia setelah app tersambung ke server.',
                          ),
                        ),
                      ),
                    child: const Text('Lupa kata sandi?'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
