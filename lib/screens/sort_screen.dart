import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

import '../theme.dart';
import '../models/app_state.dart';
import '../widgets/shared.dart';
import 'viewer_screen.dart';
import 'date_browser_screen.dart';

class SortScreen extends StatefulWidget {
  final String folder;
  const SortScreen({super.key, required this.folder});

  @override
  State<SortScreen> createState() => _SortScreenState();
}

class _SortScreenState extends State<SortScreen> {
  bool _groupMode = false;
  bool _loading = false;
  String _loadingLabel = '';

  final _sorts = const [
    ('Nama', 'nama file', Icons.sort_by_alpha_rounded,
        [('A → Z', 'name_asc'), ('Z → A', 'name_desc')]),
    ('Ukuran', 'ukuran file', Icons.storage_rounded,
        [('Terkecil', 'size_asc'), ('Terbesar', 'size_desc')]),
    ('Tanggal', 'tanggal foto', Icons.calendar_today_rounded,
        [('Terbaru', 'date_desc'), ('Terlama', 'date_asc')]),
  ];

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: kBg,
          body: Column(
            children: [
              _SortNavBar(onBack: _loading ? null : () => Navigator.pop(context)),
          Expanded(
            child: Center(
              child: SizedBox(
                width: 960,
                child: Column(
                  children: [
                    const SizedBox(height: 52),
                    const Text('Urutkan Foto',
                        style: TextStyle(
                            fontFamily: 'Courier New',
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: kText,
                            letterSpacing: -1)),
                    const SizedBox(height: 12),
                    const Text('Pilih urutan sebelum mulai bersih-bersih',
                        style: TextStyle(
                            fontFamily: 'Consolas',
                            fontSize: 15,
                            color: kTextMuted)),
                    const SizedBox(height: 24),
                    const AmberRule(width: 360),
                    const SizedBox(height: 52),

                    // ── Sort cards ────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (final s in _sorts) ...[
                          _SortCard(
                            title: s.$1,
                            desc: s.$2,
                            icon: s.$3,
                            buttons: s.$4,
                            onSelect: _startWith,
                          ),
                          if (s != _sorts.last) const SizedBox(width: 28),
                        ],
                      ],
                    ),

                    const SizedBox(height: 52),

                    // ── Group toggle ──────────────────────────
                    Container(
                      width: 580,
                      height: 72,
                      decoration: BoxDecoration(
                        color: kBgCard,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _groupMode ? kAmberDim : kBorder),
                      ),
                      child: Column(children: [
                        Container(
                          height: 3,
                          decoration: BoxDecoration(
                            color: _groupMode ? kAmber : kBgCard2,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Row(children: [
                              Icon(Icons.calendar_view_week_rounded,
                                  size: 22, color: _groupMode ? kAmber : kTextMuted),
                              const SizedBox(width: 14),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Kelompokkan per Tanggal',
                                      style: TextStyle(
                                          fontFamily: 'Courier New',
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: _groupMode ? kAmber : kText)),
                                  const SizedBox(height: 3),
                                  const Text('review per tahun / bulan / minggu',
                                      style: TextStyle(
                                          fontFamily: 'Consolas',
                                          fontSize: 11,
                                          color: kTextMuted)),
                                ],
                              ),
                              const Spacer(),
                              Switch(
                                value: _groupMode,
                                onChanged: (v) => setState(() => _groupMode = v),
                                activeColor: kAmber,
                                inactiveTrackColor: kBtnSec,
                                trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
                              ),
                            ]),
                          ),
                        ),
                      ]),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ),  // closes Scaffold (first Stack child)
        if (_loading) _LoadingOverlay(label: _loadingLabel),
      ],
    );
  }

  // ── Placeholder (removed) ─────────────────────────

  Future<void> _startWith(String mode) async {
    setState(() {
      _loading = true;
      _loadingLabel = _groupMode ? 'Mengelompokkan foto...' : 'Memuat foto...';
    });

    // Wait for 2 full frames so the overlay is fully painted before Dart blocks
    await WidgetsBinding.instance.endOfFrame;
    await WidgetsBinding.instance.endOfFrame;

    final state = context.read<AppState>();

    if (_groupMode) {
      state.startGroupMode(widget.folder, mode);
      if (mounted) Navigator.pushReplacement(context, fadeRoute(const DateBrowserScreen()));
    } else {
      state.loadImages(widget.folder, mode);
      if (mounted) Navigator.pushReplacement(context, fadeRoute(const ViewerScreen()));
    }
  }
}

// ── Loading overlay ───────────────────────────────
class _LoadingOverlay extends StatefulWidget {
  final String label;
  const _LoadingOverlay({required this.label});
  @override State<_LoadingOverlay> createState() => _LoadingOverlayState();
}
class _LoadingOverlayState extends State<_LoadingOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: Container(
        color: kBg.withAlpha(220),
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            SizedBox(
              width: 48, height: 48,
              child: CircularProgressIndicator(
                color: kAmber,
                strokeWidth: 2.5,
                backgroundColor: kBorder,
              ),
            ),
            const SizedBox(height: 24),
            Text(widget.label, style: const TextStyle(
                fontFamily: 'Consolas', fontSize: 14,
                fontWeight: FontWeight.bold, color: kAmber)),
            const SizedBox(height: 8),
            Text('Mohon tunggu sebentar...',
                style: const TextStyle(fontFamily: 'Consolas',
                    fontSize: 11, color: kTextMuted)),
          ]),
        ),
      ),
    );
  }
}

// ── Navbar ────────────────────────────────────────
class _SortNavBar extends StatelessWidget {
  final VoidCallback? onBack;
  const _SortNavBar({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (_) => windowManager.startDragging(),
      child: Container(
        height: 52, color: kBgNav,
        child: Stack(children: [
          Positioned(bottom: 0, left: 0, right: 0,
              child: Container(height: 1, color: kAmberDim)),
          Positioned(left: 16, top: 0, bottom: 0,
              child: Center(child: TextButton(
                onPressed: onBack,
                style: TextButton.styleFrom(
                    foregroundColor: kTextDim,
                    textStyle: const TextStyle(
                        fontFamily: 'Consolas', fontSize: 12,
                        fontWeight: FontWeight.bold)),
                child: const Text('← Back'),
              ))),
          const Center(child: Text('Sweepe',
              style: TextStyle(fontFamily: 'Courier New', fontSize: 14,
                  fontWeight: FontWeight.bold, color: kAmber))),
          Positioned(right: 10, top: 0, bottom: 0,
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                _WinBtn(icon: Icons.remove, onTap: () => windowManager.minimize()),
                const SizedBox(width: 2),
                _WinBtn(icon: Icons.crop_square, onTap: () async {
                  if (await windowManager.isMaximized()) { windowManager.unmaximize(); } else { windowManager.maximize(); }
                }),
                const SizedBox(width: 4),
                _WinBtn(icon: Icons.close, color: kRose, onTap: () => windowManager.close()),
              ])),
        ]),
      ),
    );
  }
}

// ── Sort card ─────────────────────────────────────
class _SortCard extends StatelessWidget {
  final String title, desc;
  final IconData icon;
  final List<(String, String)> buttons;
  final void Function(String mode) onSelect;
  const _SortCard({
    required this.title,
    required this.desc,
    required this.icon,
    required this.buttons,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 270,
      height: 190,
      decoration: BoxDecoration(
        color: kBgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorder),
      ),
      child: Column(children: [
        Container(
          height: 3,
          decoration: const BoxDecoration(
            color: kAmber,
            borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
          ),
        ),
        const SizedBox(height: 20),
        Icon(icon, size: 28, color: kAmberDim),
        const SizedBox(height: 10),
        Text(title, style: const TextStyle(
            fontFamily: 'Courier New', fontSize: 18,
            fontWeight: FontWeight.bold, color: kText)),
        const SizedBox(height: 5),
        Text('Urutkan dari $desc', style: const TextStyle(
            fontFamily: 'Consolas', fontSize: 11, color: kTextMuted)),
        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (final b in buttons) ...[
              _SortBtn(label: b.$1, onTap: () => onSelect(b.$2)),
              if (b != buttons.last) const SizedBox(width: 8),
            ],
          ],
        ),
      ]),
    );
  }
}

// ── Sort button ───────────────────────────────────
class _SortBtn extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  const _SortBtn({required this.label, required this.onTap});

  @override
  State<_SortBtn> createState() => _SortBtnState();
}

class _SortBtnState extends State<_SortBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 108, height: 34,
          decoration: BoxDecoration(
            color: _hovered ? kAmber : kBtnSec,
            borderRadius: BorderRadius.circular(6),
          ),
          alignment: Alignment.center,
          child: Text(widget.label, style: TextStyle(
              fontFamily: 'Consolas', fontSize: 11,
              fontWeight: FontWeight.bold,
              color: _hovered ? kBg : kText)),
        ),
      ),
    );
  }
}

// ── Window button ─────────────────────────────────
class _WinBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _WinBtn({required this.icon, required this.onTap, this.color = kTextMuted});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(7),
        child: Icon(icon, size: 14, color: color),
      ),
    );
  }
}
