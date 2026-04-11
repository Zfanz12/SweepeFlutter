import 'dart:io';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

import '../theme.dart';
import '../models/app_state.dart';
import '../widgets/shared.dart';
import 'summary_screen.dart';
import 'group_summary_screen.dart';
import 'date_browser_screen.dart';
import 'landing_screen.dart';

class ViewerScreen extends StatefulWidget {
  final bool isGroupMode;
  const ViewerScreen({super.key, this.isGroupMode = false});
  @override
  State<ViewerScreen> createState() => _ViewerScreenState();
}

class _ViewerScreenState extends State<ViewerScreen> {
  bool _leftFlash = false, _rightFlash = false, _undoFlash = false, _skipFlash = false;
  final FocusNode _focus = FocusNode();
  final ScrollController _carouselCtrl = ScrollController();
  static const double _itemW = 76.0; // thumb width + gap

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      windowManager.maximize();
    });
  }

  @override
  void dispose() {
    _focus.dispose();
    _carouselCtrl.dispose();
    super.dispose();
  }

  void _scrollToIndex(int idx) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_carouselCtrl.hasClients) return;
      final viewport = _carouselCtrl.position.viewportDimension;
      final target = (idx * _itemW) - (viewport / 2) + (_itemW / 2);
      _carouselCtrl.animateTo(
        target.clamp(0.0, _carouselCtrl.position.maxScrollExtent),
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final images = state.images;
    final idx = state.index;
    final isGroup = widget.isGroupMode || state.groupMode;

    if (idx >= images.length && images.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        if (!mounted) return;
        if (isGroup) {
          state.saveGroupViewerProgress();
          Navigator.pushReplacement(context, fadeRoute(const GroupSummaryScreen()));
        } else {
          Navigator.pushReplacement(context, fadeRoute(const SummaryScreen()));
        }
      });
      return const Scaffold(backgroundColor: kBg);
    }

    if (images.isEmpty) return const Scaffold(backgroundColor: kBg);

    final path = images[idx];
    final total = images.length;
    _scrollToIndex(idx);

    // Header label
    String headerLabel;
    if (isGroup) {
      final gk = state.currentGroupKey;
      if (gk != null) {
        if (gk.week != 0) {
          headerLabel = 'Week ${gk.week}  ·  ${AppState.monthName(gk.month)} ${gk.year}';
        } else if (gk.month != 0) {
          headerLabel = '${AppState.monthName(gk.month)} ${gk.year}';
        } else {
          headerLabel = '${gk.year}';
        }
      } else {
        headerLabel = 'Grup';
      }
    } else {
      headerLabel = state.currentFolder?.split(RegExp(r'[/\\]')).last ?? '';
    }

    return KeyboardListener(
      focusNode: _focus..requestFocus(),
      autofocus: true,
      onKeyEvent: _handleKey,
      child: Scaffold(
        backgroundColor: kBg,
        body: Column(children: [
          // ── Navbar ──
          _ViewerNavBar(
            title: headerLabel.isEmpty ? 'Sweepe' : headerLabel,
            onBack: () => _handleBack(context, state, isGroup),
            onDone: () => _handleDone(context, state, isGroup),
          ),
          // ── Progress bar ──
          _ProgressBar(value: total > 0 ? idx / total : 0),
          // ── Carousel with scrollbar ──
          _buildCarousel(images, idx, state),
          // ── Counter ──
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text('${idx + 1}  /  $total',
                style: const TextStyle(fontFamily: 'Courier New', fontSize: 17,
                    fontWeight: FontWeight.bold, color: kAmber)),
          ),
          // ── Main row ──
          Expanded(
            child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              _SidePanel(label: 'HAPUS', arrow: '←', color: kRose, dimColor: kRoseDim,
                  hint: '[ ← ]', flashing: _leftFlash, onTap: () => _doDelete(state)),
              Expanded(child: _buildImage(path, state)),
              _SidePanel(label: 'SIMPAN', arrow: '→', color: kTeal, dimColor: kTealDim,
                  hint: '[ → ]', flashing: _rightFlash, onTap: () => _doKeep(state)),
            ]),
          ),
          // ── Filename + info ──
          const SizedBox(height: 4),
          Text(path.split(RegExp(r'[/\\]')).last,
              style: const TextStyle(fontFamily: 'Consolas', fontSize: 12,
                  fontWeight: FontWeight.bold, color: kText)),
          const SizedBox(height: 2),
          _ImageInfo(path: path),
          const SizedBox(height: 6),
          // ── Undo / Skip ──
          Row(children: [
            Expanded(child: _ActionBtn(label: 'UNDO  ↓', flashing: _undoFlash,
                flashColor: kAmberDim, onTap: () => _doUndo(state))),
            const SizedBox(width: 2),
            Expanded(child: _ActionBtn(label: 'SKIP  ↑', flashing: _skipFlash,
                flashColor: kAmberDim, onTap: () => _doSkip(state))),
          ]),
        ]),
      ),
    );
  }

  Widget _buildCarousel(List<String> images, int idx, AppState state) {
    return Container(
      height: 94,
      color: const Color(0xFF111116),
      child: ScrollbarTheme(
        data: ScrollbarThemeData(
          thumbColor: WidgetStateProperty.all(const Color(0xFFDDDDDD)),
          trackColor: WidgetStateProperty.all(Colors.transparent),
          thickness: WidgetStateProperty.all(6.0),
          radius: const Radius.circular(3),
        ),
        child: Scrollbar(
          controller: _carouselCtrl,
          thumbVisibility: true,
          child: Listener(
            onPointerSignal: (e) {
              if (e is PointerScrollEvent) {
                final newIdx = e.scrollDelta.dy > 0
                    ? (idx + 1).clamp(0, images.length - 1)
                    : (idx - 1).clamp(0, images.length - 1);
                state.index = newIdx;
                state.notifyListeners();
              }
            },
            child: ListView.builder(
              controller: _carouselCtrl,
              scrollDirection: Axis.horizontal,
              itemCount: images.length,
              itemExtent: _itemW,
              padding: const EdgeInsets.only(top: 6, bottom: 14, left: 4, right: 4),
              itemBuilder: (_, i) {
                final isCurrent = i == idx;
                final isDel = state.toDelete.contains(images[i]);
                final isKeep = state.toKeep.contains(images[i]);
                return GestureDetector(
                  onTap: () { state.index = i; state.notifyListeners(); },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        height: 12,
                        width: 68,
                        child: isCurrent
                            ? const Center(
                                child: Text('▼',
                                    style: TextStyle(fontSize: 15, color: kAmber, height: 1)),
                              )
                            : const SizedBox.shrink(),
                      ),
                      Container(
                        width: 68, height: 54,
                        margin: const EdgeInsets.only(right: 4),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isCurrent ? kAmber : isDel ? kRose : isKeep ? kTeal : Colors.transparent,
                            width: isCurrent ? 2 : 1,
                          ),
                        ),
                        child: Stack(fit: StackFit.expand, children: [
                          Image.file(File(images[i]), fit: BoxFit.cover, cacheWidth: 136,
                              errorBuilder: (_, __, ___) => Container(color: kBgCard)),
                          if (isDel) Container(color: kRose.withAlpha(80)),
                          if (isKeep) Container(color: kTeal.withAlpha(60)),
                        ]),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImage(String path, AppState state) {
    final isDel = state.toDelete.contains(path);
    final isKeep = state.toKeep.contains(path);
    return Stack(fit: StackFit.expand, children: [
      Image.file(File(path), fit: BoxFit.contain, filterQuality: FilterQuality.medium,
          errorBuilder: (_, __, ___) =>
              const Center(child: Icon(Icons.broken_image, color: kTextMuted, size: 80))),
      if (isDel) Container(color: kRose.withAlpha(40)),
      if (isKeep) Container(color: kTeal.withAlpha(30)),
    ]);
  }

  void _doDelete(AppState s) {
    setState(() => _leftFlash = true);
    Future.delayed(const Duration(milliseconds: 180), () { if (mounted) setState(() => _leftFlash = false); });
    s.swipeDelete();
  }

  void _doKeep(AppState s) {
    setState(() => _rightFlash = true);
    Future.delayed(const Duration(milliseconds: 180), () { if (mounted) setState(() => _rightFlash = false); });
    s.swipeKeep();
  }

  void _doUndo(AppState s) {
    setState(() => _undoFlash = true);
    Future.delayed(const Duration(milliseconds: 180), () { if (mounted) setState(() => _undoFlash = false); });
    s.undo();
  }

  void _doSkip(AppState s) {
    setState(() => _skipFlash = true);
    Future.delayed(const Duration(milliseconds: 180), () { if (mounted) setState(() => _skipFlash = false); });
    s.skip();
  }

  void _handleKey(KeyEvent e) {
    if (e is! KeyDownEvent) return;
    final s = context.read<AppState>();
    if (e.logicalKey == LogicalKeyboardKey.arrowLeft) _doDelete(s);
    if (e.logicalKey == LogicalKeyboardKey.arrowRight) _doKeep(s);
    if (e.logicalKey == LogicalKeyboardKey.arrowDown) _doUndo(s);
    if (e.logicalKey == LogicalKeyboardKey.arrowUp) _doSkip(s);
  }

  void _handleBack(BuildContext ctx, AppState s, bool isGroup) {
    if (isGroup) {
      s.saveGroupViewerProgress();
      s.persistGroupSession();
      _toWindowed(() {
        if (ctx.mounted) Navigator.pushReplacement(ctx, fadeRoute(const DateBrowserScreen()));
      });
    } else {
      showDialog(context: ctx, builder: (_) => _BackDialog(
        state: s,
        onExit: () async { await _toWindowedAsync(); },
        onNavigateHome: () {
          if (ctx.mounted) Navigator.pushAndRemoveUntil(ctx, fadeRoute(const LandingScreen()), (_) => false);
        },
      ));
    }
  }

  void _handleDone(BuildContext ctx, AppState s, bool isGroup) {
    if (isGroup) {
      showDialog(context: ctx, builder: (_) => _GroupDoneDialog(
        onContinue: () => Navigator.pop(ctx),
        onDone: () {
          Navigator.pop(ctx);
          s.saveGroupViewerProgress();
          _toWindowed(() {
            if (ctx.mounted) Navigator.pushReplacement(ctx, fadeRoute(const GroupSummaryScreen()));
          });
        },
      ));
    } else {
      showDialog(context: ctx, builder: (_) => _DoneDialog(
        onContinue: () => Navigator.pop(ctx),
        onDone: () {
          Navigator.pop(ctx);
          _toWindowed(() {
            if (ctx.mounted) Navigator.pushReplacement(ctx, fadeRoute(const SummaryScreen()));
          });
        },
      ));
    }
  }

  void _toWindowed(VoidCallback after) async {
    await _toWindowedAsync();
    after();
  }

  Future<void> _toWindowedAsync() async {
  }
}

// ── Navbar ─────────────────────────────────────────
class _ViewerNavBar extends StatelessWidget {
  final String title;
  final VoidCallback onBack, onDone;
  const _ViewerNavBar({required this.title, required this.onBack, required this.onDone});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (_) => windowManager.startDragging(),
      child: Container(height: 48, color: kBgNav, child: Stack(children: [
        Positioned(bottom: 0, left: 0, right: 0, child: Container(height: 1, color: kAmberDim)),
        Positioned(left: 12, top: 0, bottom: 0, child: Center(child: _HovBtn(
            label: '← Back', color: kTextDim, onTap: onBack))),
        Center(child: Text(title, style: const TextStyle(
            fontFamily: 'Courier New', fontSize: 13, fontWeight: FontWeight.bold, color: kAmber))),
        Positioned(right: 8, top: 0, bottom: 0, child: Row(mainAxisSize: MainAxisSize.min, children: [
          _HovBtn(label: 'Selesai →', color: kTeal, onTap: onDone),
          const SizedBox(width: 4),
          _IconBtn(icon: Icons.remove, onTap: () => windowManager.minimize()),
          const SizedBox(width: 2),
          _IconBtn(icon: Icons.crop_square, onTap: () async { if (await windowManager.isMaximized()) { windowManager.unmaximize(); } else { windowManager.maximize(); } }),
          const SizedBox(width: 2),
          _IconBtn(icon: Icons.close, color: kRose, onTap: () => windowManager.close()),
        ])),
      ])),
    );
  }
}

// ── Progress bar ───────────────────────────────────
class _ProgressBar extends StatelessWidget {
  final double value;
  const _ProgressBar({required this.value});
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, c) => SizedBox(height: 3,
      child: Stack(children: [
        Container(color: kBgDeep),
        Container(width: c.maxWidth * value.clamp(0.0, 1.0), color: kAmber),
      ])));
  }
}

// ── Side panel ─────────────────────────────────────
class _SidePanel extends StatefulWidget {
  final String label, arrow, hint;
  final Color color, dimColor;
  final bool flashing;
  final VoidCallback onTap;
  const _SidePanel({required this.label, required this.arrow, required this.color,
      required this.dimColor, required this.hint, required this.flashing, required this.onTap});
  @override State<_SidePanel> createState() => _SidePanelState();
}
class _SidePanelState extends State<_SidePanel> {
  bool _hov = false;
  @override
  Widget build(BuildContext context) {
    final active = widget.flashing || _hov;
    return MouseRegion(
      onEnter: (_) => setState(() => _hov = true),
      onExit: (_) => setState(() => _hov = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: 140,
          color: active ? widget.dimColor : Colors.transparent,
          child: Stack(children: [
            if (widget.arrow == '←')
              Positioned(right: 0, top: 0, bottom: 0,
                  child: Container(width: 2, color: widget.color)),
            if (widget.arrow == '→')
              Positioned(left: 0, top: 0, bottom: 0,
                  child: Container(width: 2, color: widget.color)),
            Column(mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text(widget.arrow, style: TextStyle(fontFamily: 'Courier New',
                  fontSize: 56, fontWeight: FontWeight.bold, color: widget.color),
                  textAlign: TextAlign.center),
              const SizedBox(height: 4),
              Text(widget.label, style: TextStyle(fontFamily: 'Consolas',
                  fontSize: 16, fontWeight: FontWeight.bold, color: widget.color),
                  textAlign: TextAlign.center),
            ]),
            Positioned(bottom: 28, left: 0, right: 0,
                child: Text(widget.hint, style: TextStyle(fontFamily: 'Consolas',
                    fontSize: 9, color: widget.dimColor.withAlpha(100)),
                    textAlign: TextAlign.center)),
          ]),
        ),
      ),
    );
  }
}

// ── Action button ──────────────────────────────────
class _ActionBtn extends StatefulWidget {
  final String label;
  final bool flashing;
  final Color flashColor;
  final VoidCallback onTap;
  const _ActionBtn({required this.label, required this.flashing,
      required this.flashColor, required this.onTap});
  @override State<_ActionBtn> createState() => _ActionBtnState();
}
class _ActionBtnState extends State<_ActionBtn> {
  bool _hov = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hov = true),
      onExit: (_) => setState(() => _hov = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          height: 56,
          decoration: BoxDecoration(
            color: (widget.flashing || _hov) ? widget.flashColor : Colors.transparent,
            border: Border.all(color: kAmberDim),
          ),
          alignment: Alignment.center,
          child: Text(widget.label, style: const TextStyle(fontFamily: 'Consolas',
              fontSize: 16, fontWeight: FontWeight.bold, color: kAmber)),
        ),
      ),
    );
  }
}

// ── Image info ─────────────────────────────────────
class _ImageInfo extends StatelessWidget {
  final String path;
  const _ImageInfo({required this.path});
  static const _mo = ['','Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
  @override
  Widget build(BuildContext context) {
    String info = '';
    try {
      final st = File(path).statSync();
      final kb = st.size / 1024;
      final sz = kb < 1024 ? '${kb.toStringAsFixed(1)} KB' : '${(kb/1024).toStringAsFixed(1)} MB';
      final d = st.modified;
      info = '$sz   ·   ${d.day.toString().padLeft(2,'0')} ${_mo[d.month]} ${d.year}';
    } catch (_) {}
    return Text(info, style: const TextStyle(fontFamily: 'Consolas', fontSize: 13, color: kTextMuted));
  }
}

// ── Hover text button ──────────────────────────────
class _HovBtn extends StatefulWidget {
  final String label; final Color color; final VoidCallback onTap;
  const _HovBtn({required this.label, required this.color, required this.onTap});
  @override State<_HovBtn> createState() => _HovBtnState();
}
class _HovBtnState extends State<_HovBtn> {
  bool _hov = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hov = true),
      onExit: (_) => setState(() => _hov = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: _hov ? kBtnSecHov : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(widget.label, style: TextStyle(fontFamily: 'Consolas',
              fontSize: 11, fontWeight: FontWeight.bold, color: widget.color)),
        ),
      ),
    );
  }
}

class _IconBtn extends StatefulWidget {
  final IconData icon; final Color color; final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.onTap, this.color = kTextMuted});
  @override State<_IconBtn> createState() => _IconBtnState();
}
class _IconBtnState extends State<_IconBtn> {
  bool _hov = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hov = true),
      onExit: (_) => setState(() => _hov = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.all(6),
          color: _hov ? kBtnSecHov : Colors.transparent,
          child: Icon(widget.icon, size: 14, color: widget.color),
        ),
      ),
    );
  }
}

// ── Dialogs ────────────────────────────────────────
class _BackDialog extends StatelessWidget {
  final AppState state;
  final Future<void> Function() onExit;
  final VoidCallback onNavigateHome;
  const _BackDialog({required this.state, required this.onExit, required this.onNavigateHome});

  @override
  Widget build(BuildContext context) {
    return Dialog(backgroundColor: kBgNav, shape: const RoundedRectangleBorder(),
      child: SizedBox(width: 540, height: 240, child: Column(children: [
        Container(height: 2, color: kAmber),
        const SizedBox(height: 22),
        const Text('Keluar dari sesi ini?', style: TextStyle(fontFamily: 'Courier New',
            fontSize: 16, fontWeight: FontWeight.bold, color: kText)),
        const SizedBox(height: 14),
        const Text('Progress kamu akan disimpan.\nKamu bisa lanjutin nanti dari halaman utama.',
            style: TextStyle(fontFamily: 'Consolas', fontSize: 11, color: kTextDim),
            textAlign: TextAlign.center),
        const SizedBox(height: 10),
        Text('${state.toDelete.length}  dihapus  ·  ${state.toKeep.length}  disimpan  ·  ${state.index}  direview',
            style: const TextStyle(fontFamily: 'Consolas', fontSize: 10, color: kAmber)),
        const SizedBox(height: 18),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          SweepButton(label: 'Lanjut beberes', height: 36, width: 140,
              onPressed: () => Navigator.pop(context)),
          const SizedBox(width: 8),
          SweepButton(label: 'Simpan & keluar', bg: kAmber, hover: kAmberHov,
              textColor: kBg, height: 36, width: 150,
              onPressed: () async {
                state.persistFlatSession(resumeIndex: state.index);
                Navigator.pop(context);
                await onExit();
                onNavigateHome();
              }),
          const SizedBox(width: 8),
          SweepButton(label: 'Keluar tanpa simpan', outlined: true,
              borderColor: kRose, textColor: kRose, height: 36, width: 170,
              onPressed: () async {
                state.clearResumeSession();
                Navigator.pop(context);
                await onExit();
                onNavigateHome();
              }),
        ]),
      ])),
    );
  }
}

class _DoneDialog extends StatelessWidget {
  final VoidCallback onContinue, onDone;
  const _DoneDialog({required this.onContinue, required this.onDone});
  @override
  Widget build(BuildContext context) {
    return Dialog(backgroundColor: kBgNav, shape: const RoundedRectangleBorder(),
      child: SizedBox(width: 400, height: 200, child: Column(children: [
        Container(height: 2, color: kAmber),
        const SizedBox(height: 28),
        const Text('Berhenti di sini?', style: TextStyle(fontFamily: 'Courier New',
            fontSize: 16, fontWeight: FontWeight.bold, color: kText)),
        const SizedBox(height: 16),
        const Text('Foto yang belum dipilih akan dilewati.',
            style: TextStyle(fontFamily: 'Consolas', fontSize: 11, color: kTextDim)),
        const SizedBox(height: 24),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          SweepButton(label: 'Belum deh', height: 36, width: 120, onPressed: onContinue),
          const SizedBox(width: 12),
          SweepButton(label: 'Ya, selesai →', bg: kAmber, hover: kAmberHov,
              textColor: kBg, height: 36, width: 140, onPressed: onDone),
        ]),
      ])),
    );
  }
}

class _GroupDoneDialog extends StatelessWidget {
  final VoidCallback onContinue, onDone;
  const _GroupDoneDialog({required this.onContinue, required this.onDone});
  @override
  Widget build(BuildContext context) {
    return Dialog(backgroundColor: kBgNav, shape: const RoundedRectangleBorder(),
      child: SizedBox(width: 400, height: 200, child: Column(children: [
        Container(height: 2, color: kAmber),
        const SizedBox(height: 28),
        const Text('Selesai grup ini?', style: TextStyle(fontFamily: 'Courier New',
            fontSize: 16, fontWeight: FontWeight.bold, color: kText)),
        const SizedBox(height: 16),
        const Text('Foto yang belum dipilih akan dilewati.',
            style: TextStyle(fontFamily: 'Consolas', fontSize: 11, color: kTextDim)),
        const SizedBox(height: 24),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          SweepButton(label: 'Belum deh', height: 36, width: 120, onPressed: onContinue),
          const SizedBox(width: 12),
          SweepButton(label: 'Ya, lihat summary →', bg: kAmber, hover: kAmberHov,
              textColor: kBg, height: 36, width: 180, onPressed: onDone),
        ]),
      ])),
    );
  }
}
