import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

import '../theme.dart';
import '../models/app_state.dart';
import '../widgets/shared.dart';
import 'viewer_screen.dart';
import 'date_browser_screen.dart';

class GroupSummaryScreen extends StatefulWidget {
  final String label;
  const GroupSummaryScreen({super.key, this.label = ''});
  @override
  State<GroupSummaryScreen> createState() => _GroupSummaryScreenState();
}

class _GroupSummaryScreenState extends State<GroupSummaryScreen> {
  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().saveGroupViewerProgress();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final nDel = state.toDelete.length;
    final nKeep = state.toKeep.length;
    final nRev = nDel + nKeep;
    final nSkip = state.toSkip.length;
    final tb = _totalBytes(state.toDelete);
    final ts = AppState.formatSize(tb);

    return Scaffold(
      backgroundColor: kBg,
      body: Column(children: [
        _NavBar(),
        Expanded(child: Center(child: SizedBox(width: 680, child: Column(children: [
          const SizedBox(height: 32),
          const Text('Review Grup Ini', style: TextStyle(fontFamily: 'Courier New', fontSize: 22, fontWeight: FontWeight.bold, color: kText)),
          const SizedBox(height: 10),
          const AmberRule(width: 320),
          const SizedBox(height: 22),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            StatPill(label: 'Direview', value: nRev, color: kAmber),
            const SizedBox(width: 10),
            FreedCard(size: ts),
            const SizedBox(width: 10),
            StatPill(label: 'Disimpan', value: nKeep, color: kTeal),
            const SizedBox(width: 10),
            StatPill(label: 'Dihapus', value: nDel, color: kRose),
            if (nSkip > 0) ...[const SizedBox(width: 10), StatPill(label: 'Dilewati', value: nSkip, color: kTextMuted)],
          ]),
          const SizedBox(height: 20),
          Expanded(child: DeleteListCard(files: state.toDelete)),
          const SizedBox(height: 18),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            // Fix: "Cek lagi" should go back to VIEWER, not summary
            SweepButton(
              label: '← Cek lagi', height: 42, width: 140,
              onPressed: () async {
                state.index = 0;
                await windowManager.maximize();
                if (context.mounted) Navigator.pushReplacement(context, fadeRoute(const ViewerScreen(isGroupMode: true)));
              },
            ),
            const SizedBox(width: 12),
            SweepButton(
              label: _deleting ? 'Menghapus...' : 'Hapus & kembali ke grup',
              bg: kRose, hover: kRoseHov, textColor: kText, height: 42, width: 220,
              onPressed: _deleting ? null : () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => _ConfirmDeleteDialog(count: nDel),
                );
                if (confirm == true && context.mounted) _doDelete(context, state);
              },
            ),
            const SizedBox(width: 12),
            SweepButton(
              label: 'Ke Daftar Grup →',
              bg: kBtnSec, hover: kAmberDim, textColor: kAmber, height: 42, width: 160,
              onPressed: () => Navigator.pushReplacement(context, fadeRoute(const DateBrowserScreen())),
            ),
          ]),
          const SizedBox(height: 24),
        ])))),
      ]),
    );
  }

  Future<void> _doDelete(BuildContext context, AppState state) async {
    setState(() => _deleting = true);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _DeletingDialog(total: state.toDelete.length),
    );

    final count = await state.deleteFiles(
      List.from(state.toDelete),
      onProgress: (done, total) {
        if (context.mounted) _DeletingDialog.update(done, total);
      },
    );
    if (!mounted) return;

    Navigator.of(context, rootNavigator: true).pop();
    state.persistGroupSession();
    showDialog(
      context: context, barrierDismissible: false,
      builder: (_) => _SuccessDialog(
        count: count,
        onToBrowser: () {
          Navigator.pop(context);
          Navigator.pushReplacement(context, fadeRoute(const DateBrowserScreen()));
        },
      ),
    );
  }

  int _totalBytes(List<String> paths) {
    int t = 0;
    for (final p in paths) { try { t += File(p).lengthSync(); } catch (_) {} }
    return t;
  }
}

// ── Confirm delete dialog ─────────────────────────
class _ConfirmDeleteDialog extends StatelessWidget {
  final int count;
  const _ConfirmDeleteDialog({required this.count});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: kBgNav,
      shape: const RoundedRectangleBorder(),
      child: SizedBox(width: 420, height: 220, child: Column(children: [
        Container(height: 2, color: kRose),
        const SizedBox(height: 30),
        const Text('Konfirmasi Hapus',
            style: TextStyle(fontFamily: 'Courier New', fontSize: 17,
                fontWeight: FontWeight.bold, color: kText)),
        const SizedBox(height: 14),
        Text('$count foto akan dipindahkan ke Recycle Bin.',
            style: const TextStyle(fontFamily: 'Consolas', fontSize: 12, color: kTextDim)),
        const SizedBox(height: 4),
        const Text('Tindakan ini tidak dapat di-undo dari aplikasi.',
            style: TextStyle(fontFamily: 'Consolas', fontSize: 11, color: kTextMuted)),
        const SizedBox(height: 28),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          SweepButton(label: 'Batal', height: 40, width: 110,
              onPressed: () => Navigator.pop(context, false)),
          const SizedBox(width: 12),
          SweepButton(label: 'Ya, hapus sekarang',
              bg: kRose, hover: kRoseHov, textColor: kText,
              height: 40, width: 180,
              onPressed: () => Navigator.pop(context, true)),
        ]),
      ])),
    );
  }
}

// ── Deleting progress dialog ──────────────────────
class _DeletingDialog extends StatefulWidget {
  final int total;
  const _DeletingDialog({required this.total});

  static final _notifier = ValueNotifier<(int, int)>((0, 0));
  static void update(int done, int total) => _notifier.value = (done, total);

  @override
  State<_DeletingDialog> createState() => _DeletingDialogState();
}

class _DeletingDialogState extends State<_DeletingDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  late final Stopwatch _stopwatch;
  late final Timer _ticker;
  int _elapsed = 0;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _stopwatch = Stopwatch()..start();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsed = _stopwatch.elapsed.inSeconds);
    });
  }

  @override
  void dispose() {
    _pulse.dispose();
    _ticker.cancel();
    _stopwatch.stop();
    super.dispose();
  }

  String get _elapsedLabel {
    final m = _elapsed ~/ 60;
    final s = _elapsed % 60;
    if (m > 0) return '${m}m ${s.toString().padLeft(2, '0')}s berlalu';
    return '${s}s berlalu';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: kBgNav,
      shape: const RoundedRectangleBorder(),
      child: SizedBox(width: 420, height: 230, child: Column(children: [
        Container(height: 2, color: kRose),
        const SizedBox(height: 24),
        FadeTransition(
          opacity: Tween(begin: 0.45, end: 1.0).animate(_pulse),
          child: const Text('Menghapus...',
              style: TextStyle(fontFamily: 'Courier New', fontSize: 17,
                  fontWeight: FontWeight.bold, color: kRose)),
        ),
        const SizedBox(height: 20),
        ValueListenableBuilder<(int, int)>(
          valueListenable: _DeletingDialog._notifier,
          builder: (_, val, __) {
            final done  = val.$1;
            final total = val.$2 == 0 ? widget.total : val.$2;
            final target = total > 0 ? done / total : 0.0;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(end: target),
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOut,
                  builder: (_, v, __) => ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Stack(children: [
                      Container(height: 8, color: kBorder),
                      FractionallySizedBox(
                        widthFactor: v,
                        child: Container(
                          height: 8,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(colors: [kRose, kRoseHov]),
                          ),
                        ),
                      ),
                    ]),
                  ),
                ),
                const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('$done foto dihapus',
                      style: const TextStyle(fontFamily: 'Consolas',
                          fontSize: 11, color: kTextMuted)),
                  Text('$total total',
                      style: const TextStyle(fontFamily: 'Consolas',
                          fontSize: 11, color: kTextMuted)),
                ]),
              ]),
            );
          },
        ),
        const SizedBox(height: 14),
        Text(_elapsedLabel,
            style: const TextStyle(fontFamily: 'Consolas', fontSize: 11, color: kAmberDim)),
      ])),
    );
  }
}

class _NavBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (_) => windowManager.startDragging(),
      child: Container(height: 48, color: kBgNav,
        child: Stack(children: [
          Positioned(bottom: 0, left: 0, right: 0, child: Container(height: 1, color: kAmberDim)),
          const Center(child: Text('Sweepe', style: TextStyle(fontFamily: 'Courier New', fontSize: 13, fontWeight: FontWeight.bold, color: kAmber))),
          Positioned(right: 8, top: 0, bottom: 0, child: Row(mainAxisSize: MainAxisSize.min, children: [
            InkWell(onTap: () => windowManager.minimize(), child: const Padding(padding: EdgeInsets.all(6), child: Icon(Icons.remove, size: 14, color: kTextMuted))),
              const SizedBox(width: 2),
              InkWell(onTap: () async { if (await windowManager.isMaximized()) { windowManager.unmaximize(); } else { windowManager.maximize(); } }, child: const Padding(padding: EdgeInsets.all(6), child: Icon(Icons.crop_square, size: 14, color: kTextMuted))),
              const SizedBox(width: 4),
              InkWell(onTap: () => windowManager.close(), child: const Padding(padding: EdgeInsets.all(6), child: Icon(Icons.close, size: 14, color: kRose))),
          ])),
        ]),
      ),
    );
  }
}

class _SuccessDialog extends StatelessWidget {
  final int count;
  final VoidCallback onToBrowser;
  const _SuccessDialog({required this.count, required this.onToBrowser});
  @override
  Widget build(BuildContext context) {
    return Dialog(backgroundColor: kBgNav, shape: const RoundedRectangleBorder(),
      child: SizedBox(width: 380, height: 200, child: Column(children: [
        Container(height: 2, color: kTeal),
        const SizedBox(height: 30),
        const Text('Berhasil dihapus', style: TextStyle(fontFamily: 'Courier New', fontSize: 17, fontWeight: FontWeight.bold, color: kTeal)),
        const SizedBox(height: 14),
        Text('$count foto dipindahkan ke Recycle Bin.', style: const TextStyle(fontFamily: 'Consolas', fontSize: 11, color: kTextDim)),
        const SizedBox(height: 26),
        SweepButton(label: 'Ke Daftar Grup', bg: kAmber, hover: kAmberHov, textColor: kBg, height: 36, width: 170, onPressed: onToBrowser),
      ])),
    );
  }
}
