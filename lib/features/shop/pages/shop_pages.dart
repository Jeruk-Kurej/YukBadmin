import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/widgets/yb_widgets.dart';
import '../../gear/data/gear_models.dart';
import '../../gear/pages/gear_feed_page.dart' show stockTag;
import '../../gear/state/gear_providers.dart';
import '../../manage/pages/manage_widgets.dart';
import 'shop_form.dart';
import '../../../core/widgets/covers.dart';
import '../../gear/pages/product_art.dart';
import '../../../core/widgets/photo.dart';

/// Kerangka dua tab toko: Profil dan Produk.
class ShopShell extends StatelessWidget {
  const ShopShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    const tabs = [
      (Icons.inventory_2_outlined, Icons.inventory_2, 'Produk'),
      (Icons.person_outline, Icons.person, 'Akun'),
    ];
    return Scaffold(
      body: shell,
      bottomNavigationBar: YbTabBar(
        tabs: tabs,
        currentIndex: shell.currentIndex,
        onTap: (i) =>
            shell.goBranch(i, initialLocation: i == shell.currentIndex),
      ),
    );
  }
}

/// T2 Profil toko.
class ShopProfilePage extends ConsumerStatefulWidget {
  const ShopProfilePage({super.key});

  @override
  ConsumerState<ShopProfilePage> createState() => _ShopProfilePageState();
}

class _ShopProfilePageState extends ConsumerState<ShopProfilePage> {
  final _form = GlobalKey<FormState>();
  final _fields = GlobalKey<ShopFieldsState>();

  void _save() {
    if (!_form.currentState!.validate()) return;
    final shop = ref.read(ownShopProvider).shop!;
    ref
        .read(ownShopProvider.notifier)
        .updateShop(_fields.currentState!.read(shop.id));
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profil toko disimpan'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shop = ref.watch(ownShopProvider.select((s) => s.shop));
    if (shop == null) return const SizedBox.shrink();
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            PageHeader(
              title: 'Profil toko',
              trailing: TextButton(
                onPressed: () => context.push('/toko/${shop.id}'),
                child: const Text('Lihat'),
              ),
            ),
            const SizedBox(height: 16),
            ShopFields(key: _fields, formKey: _form, initial: shop),
            FilledButton(onPressed: _save, child: const Text('Simpan profil')),
          ],
        ),
      ),
    );
  }
}

/// T3 Daftar produk.
class ShopProductsPage extends ConsumerStatefulWidget {
  const ShopProductsPage({super.key});

  @override
  ConsumerState<ShopProductsPage> createState() => _ShopProductsPageState();
}

class _ShopProductsPageState extends ConsumerState<ShopProductsPage> {
  final _search = TextEditingController();
  GearCategory? _category;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(ownShopProvider.select((s) => s.products));
    final q = _search.text.trim().toLowerCase();
    final shown = all
        .where((p) => _category == null || p.category == _category)
        .where((p) => q.isEmpty || p.name.toLowerCase().contains(q))
        .toList();

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          YbPageTitle(
            'Produk',
            trailing: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: YbColors.surface,
                foregroundColor: YbColors.ink,
                minimumSize: const Size(0, 44),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onPressed: () => context.push('/toko-saya/produk/baru'),
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text('Tambah'),
            ),
          ),
          const SizedBox(height: 16),
          if (all.isEmpty)
            YbEmptyState(
              icon: Icons.inventory_2_outlined,
              title: 'Belum ada produk',
              message: 'Tambah produk pertamamu. Isi spesifikasinya supaya bisa disarankan ke pemain yang cocok.',
              actionLabel: 'Tambah produk',
              onAction: () => context.push('/toko-saya/produk/baru'),
            )
          else ...[
            TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              style: YbText.body(size: 15),
              decoration: InputDecoration(
                hintText: 'Cari produk',
                prefixIcon: Icon(Icons.search_rounded, color: YbColors.muted),
                filled: true,
                fillColor: YbColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(YbRadius.pill),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(YbRadius.pill),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                YbChoiceChip(
                  label: 'Semua',
                  selected: _category == null,
                  onTap: () => setState(() => _category = null),
                ),
                for (final c in GearCategory.values)
                  YbChoiceChip(
                    label: c.label,
                    selected: _category == c,
                    onTap: () => setState(() => _category = c),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (shown.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'Tidak ada produk yang cocok.',
                  textAlign: TextAlign.center,
                  style: YbText.body(color: YbColors.muted),
                ),
              ),
            if (shown.isNotEmpty) ...[
              YbSectionTitle('${shown.length} produk'),
              const SizedBox(height: 10),
              YbGroup(
                children: [
                  for (final p in shown)
                    YbListRow(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(YbRadius.md),
                        child: SizedBox(
                          width: 52,
                          height: 52,
                          child: ProductImage(product: p),
                        ),
                      ),
                      title: p.name,
                      subtitle: formatRupiah(p.price),
                      onTap: () => context.push('/toko-saya/produk/${p.id}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Stok paling sering berubah, jadi bisa diganti langsung dari daftar.
                          Semantics(
                            button: true,
                            label:
                                '${p.name}: ${p.inStock ? 'Tersedia' : 'Habis'}. Ketuk untuk mengubah stok.',
                            excludeSemantics: true,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(
                                YbRadius.pill,
                              ),
                              onTap: () {
                                ref
                                    .read(ownShopProvider.notifier)
                                    .setStock(p.id, !p.inStock);
                                ScaffoldMessenger.of(context)
                                  ..hideCurrentSnackBar()
                                  ..showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        '${p.name} sekarang ${p.inStock ? 'Habis' : 'Tersedia'}',
                                      ),
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                child: stockTag(p.inStock),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
            ],
            Text(
              'Ketuk label Tersedia atau Habis untuk mengubah stok.',
              style: YbText.label(),
            ),
          ],
        ],
      ),
    );
  }
}

/// T4 Tambah atau ubah produk.
class ProductFormPage extends ConsumerStatefulWidget {
  const ProductFormPage({super.key, this.productId});

  final String? productId;

  @override
  ConsumerState<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends ConsumerState<ProductFormPage> {
  final _form = GlobalKey<FormState>();
  late final Product? _original = widget.productId == null
      ? null
      : ref
            .read(ownShopProvider)
            .products
            .where((p) => p.id == widget.productId)
            .firstOrNull;
  late final _name = TextEditingController(text: _original?.name ?? '');
  late final _price = TextEditingController(
    text: _original == null ? '' : '${_original.price}',
  );
  late final _description = TextEditingController(
    text: _original?.description ?? '',
  );
  late var _category = _original?.category ?? GearCategory.raket;
  late var _inStock = _original?.inStock ?? true;
  late RacketWeight? _weight = _original?.racket?.weight;
  late RacketBalance? _balance = _original?.racket?.balance;
  late RacketFlex? _flex = _original?.racket?.flex;
  late final Set<int> _sizes = {...?_original?.shoeSizes};
  late StringType? _stringType = _original?.stringType;
  late String? _photoPath = _original?.photoPath;
  String? _specError;

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _description.dispose();
    super.dispose();
  }

  String? _missingSpec() => switch (_category) {
    GearCategory.raket
        when _weight == null || _balance == null || _flex == null =>
      'Lengkapi berat, titik berat, dan kelenturan raket.',
    GearCategory.sepatu when _sizes.isEmpty =>
      'Pilih minimal satu ukuran yang tersedia.',
    GearCategory.senar when _stringType == null => 'Pilih jenis senar.',
    _ => null,
  };

  void _save() {
    final valid = _form.currentState!.validate();
    setState(() => _specError = _missingSpec());
    if (!valid || _specError != null) return;
    final sizes = _sizes.toList()..sort();
    ref
        .read(ownShopProvider.notifier)
        .saveProduct(
          Product(
            id: _original?.id ?? '',
            shopId: ref.read(ownShopProvider).shop!.id,
            name: _name.text.trim(),
            category: _category,
            price: parseRupiah(_price.text)!,
            inStock: _inStock,
            description: _description.text.trim(),
            racket: _category == GearCategory.raket
                ? RacketSpec(weight: _weight!, balance: _balance!, flex: _flex!)
                : null,
            shoeSizes: _category == GearCategory.sepatu ? sizes : const [],
            stringType: _category == GearCategory.senar ? _stringType : null,
            photoPath: _photoPath,
          ),
        );
    context.pop();
  }

  Future<void> _delete() async {
    final ok = await confirmDestructive(
      context,
      title: 'Hapus ${_original!.name}?',
      message:
          'Produk ini hilang dari tab Perlengkapan dan saran untuk pemain.',
      confirmLabel: 'Hapus produk',
    );
    if (!ok || !mounted) return;
    ref.read(ownShopProvider.notifier).removeProduct(_original.id);
    context.pop();
  }

  Widget _chips<T>(
    List<T> values,
    String Function(T) label,
    T? selected,
    ValueChanged<T> onTap,
  ) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      for (final v in values)
        YbChoiceChip(
          label: label(v),
          selected: selected == v,
          onTap: () => onTap(v),
        ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final editing = _original != null;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: Form(
                key: _form,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          const YbBackButton(),
                          const Spacer(),
                          if (editing)
                            IconButton(
                              tooltip: 'Hapus produk',
                              onPressed: _delete,
                              icon: Icon(
                                Icons.delete_outline_rounded,
                                color: YbColors.error,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      YbPageTitle(editing ? 'Ubah produk' : 'Tambah produk'),
                      const SizedBox(height: 20),
                      LabeledField(
                        label: 'Foto produk',
                        helper: 'Opsional. Tanpa foto, gambar contoh sesuai kategori yang dipakai.',
                        child: Semantics(
                          button: true,
                          label: _photoPath == null
                              ? 'Tambah foto produk'
                              : 'Ubah foto produk',
                          excludeSemantics: true,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(YbRadius.md),
                            onTap: () async {
                              final change = await changePhoto(
                                context,
                                ref,
                                title: 'Foto produk',
                                hasPhoto: _photoPath != null,
                              );
                              if (change != null) {
                                setState(() => _photoPath = change.path);
                              }
                            },
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(YbRadius.md),
                              child: SizedBox(
                                height: 160,
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    YbPhoto(
                                      path: _photoPath,
                                      fallback: ProductArt(
                                        category: _category,
                                        seed: _name.text.length,
                                      ),
                                    ),
                                    Positioned(
                                      right: 10,
                                      bottom: 10,
                                      child: YbTag(
                                        _photoPath == null
                                            ? 'Tambah foto'
                                            : 'Ubah foto',
                                        tone: YbTagTone.neutral,
                                        icon: Icons.photo_camera_outlined,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      LabeledField(
                        label: 'Nama produk',
                        child: TextFormField(
                          controller: _name,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(
                            hintText: 'Raket Falcon 80',
                          ),
                          validator: (v) => (v ?? '').trim().length < 3
                              ? 'Isi nama produk.'
                              : null,
                        ),
                      ),
                      LabeledField(
                        label: 'Harga',
                        child: TextFormField(
                          controller: _price,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: const InputDecoration(
                            prefixText: 'Rp ',
                            hintText: '1250000',
                          ),
                          validator: (v) {
                            final price = parseRupiah(v ?? '');
                            if (price == null || price == 0) {
                              return 'Isi harga produk.';
                            }
                            if (price > 100000000) {
                              return 'Harga terlalu besar, cek lagi.';
                            }
                            return null;
                          },
                        ),
                      ),
                      Text('Kategori', style: YbText.label()),
                      const SizedBox(height: 8),
                      _chips(
                        GearCategory.values,
                        (c) => c.label,
                        _category,
                        (c) => setState(() {
                          _category = c;
                          _specError = null;
                        }),
                      ),
                      const SizedBox(height: 18),
                      if (_category == GearCategory.raket) ...[
                        Text('Berat', style: YbText.label()),
                        const SizedBox(height: 8),
                        _chips(
                          RacketWeight.values,
                          (w) => '${w.label} · ${w.grams}',
                          _weight,
                          (w) => setState(() => _weight = w),
                        ),
                        const SizedBox(height: 14),
                        Text('Titik berat', style: YbText.label()),
                        const SizedBox(height: 8),
                        _chips(
                          RacketBalance.values,
                          (b) => b.label,
                          _balance,
                          (b) => setState(() => _balance = b),
                        ),
                        const SizedBox(height: 14),
                        Text('Kelenturan batang', style: YbText.label()),
                        const SizedBox(height: 8),
                        _chips(
                          RacketFlex.values,
                          (f) => f.label,
                          _flex,
                          (f) => setState(() => _flex = f),
                        ),
                      ],
                      if (_category == GearCategory.sepatu) ...[
                        Text('Ukuran tersedia (EU)', style: YbText.label()),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (var size = 35; size <= 47; size++)
                              YbChoiceChip(
                                round: true,
                                label: '$size',
                                selected: _sizes.contains(size),
                                onTap: () => setState(() {
                                  if (!_sizes.add(size)) _sizes.remove(size);
                                }),
                              ),
                          ],
                        ),
                      ],
                      if (_category == GearCategory.senar) ...[
                        Text('Jenis senar', style: YbText.label()),
                        const SizedBox(height: 8),
                        _chips(
                          StringType.values,
                          (t) => t.label,
                          _stringType,
                          (t) => setState(() => _stringType = t),
                        ),
                      ],
                      if (_category != GearCategory.grip)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            'Spesifikasi dipakai untuk menyarankan produk ke pemain yang cocok.',
                            style: YbText.label(),
                          ),
                        ),
                      if (_specError != null) FieldError(_specError!),
                      const SizedBox(height: 18),
                      LabeledField(
                        label: 'Deskripsi',
                        child: TextFormField(
                          controller: _description,
                          minLines: 2,
                          maxLines: 5,
                          maxLength: 300,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: const InputDecoration(
                            hintText: 'Ringan, cocok untuk gaya main seimbang.',
                          ),
                        ),
                      ),
                      Text('Status stok', style: YbText.label()),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          YbChoiceChip(
                            icon: Icons.check,
                            label: 'Ready',
                            selected: _inStock,
                            onTap: () => setState(() => _inStock = true),
                          ),
                          YbChoiceChip(
                            label: 'Habis',
                            selected: !_inStock,
                            onTap: () => setState(() => _inStock = false),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            BottomActionBar(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: _save,
                    child: const Text('Simpan produk'),
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
