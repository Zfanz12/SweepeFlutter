import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

import '../theme.dart';
import '../models/app_state.dart';
import '../widgets/shared.dart';
import 'date_browser_screen.dart';
import 'landing_screen.dart';

class GlobalSummaryScreen extends StatefulWidget {
  const GlobalSummaryScreen({super.key});
  @override
  State<GlobalSummaryScreen> createState() => _GlobalSummaryScreenState();
}

class _GlobalSummaryScreenState extends State<GlobalSummaryScreen> {
  bool _deleting = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final allDel = state.allDeleteList;
    final allTot = state.totalAll;
    final nDel = allDel.length;
    final nKeep = state.groupProgress.values.expand((gp) => gp.keep).toSet().length;
    final nRev = nDel + nKeep;
    final nSkip = allTot - nRev;
    final tb = _totalBytes(allDel);
    final ts = AppState.formatSize(tb);

    // All reviewed = no skipped photos = hide "Simpan sesi" button
    final allReviewed = nSkip <= 0;

    return Scaffold(
      backgroundColor: kBg,
      body: Column(children: [
        _NavBar(),
        Expanded(child: Center(child: SizedBox(width: 680, child: Column(children: [
          const SizedBox(height: 32),
          const Text('Summary Keseluruhan', style: TextStyle(fontFamily: 'Courier New', fontSize: 22, fontWeight: FontWeight.bold, color: kText)),
          const SizedBox(height: 10),
          const AmberRule(width: 360),
          const SizedBox(height: 22),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            StatPill(label: 'Total', value: allTot, color: kAmber, width: 104),
            const SizedBox(width: 8),
            StatPill(label: 'Direview', value: nRev, color: kAmberGlow, width: 104),
            const SizedBox(width: 8),
            FreedCard(size: ts),
            const SizedBox(width: 8),
            StatPill(label: 'Disimpan', value: nKeep, color: kTeal, width: 104),
            const SizedBox(width: 8),
            StatPill(label: 'Dihapus', value: nDel, color: kRose, width: 104),
            if (nSkip > 0) ...[const SizedBox(width: 8), StatPill(label: 'Dilewati', value: nSkip, color: kTextMuted, width: 104)],
          ]),
          const SizedBox(height: 20),
          Expanded(child: DeleteListCard(files: allDel)),
          const SizedBox(height: 18),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            SweepButton(label: '← Kembali ke grup', height: 42, width: 170,
                onPressed: () => Navigator.pushReplacement(context, fadeRoute(const DateBrowserScreen()))),
            const SizedBox(width: 8),
            SweepButton(
              label: _deleting ? 'Menghapus...' : 'Hapus semua sekarang',
              bg: kRose, hover: kRoseHov, textColor: kText, height: 42, width: 220,
              onPressed: _deleting ? null : () => _doDeleteAll(context, state),
            ),
          ]),
          if (nSkip > 0) ...[
            const SizedBox(height: 10),
            Text('$nSkip foto dilewati — bisa di-review lagi dari halaman utama',
                style: const TextStyle(fontFamily: 'Consolas', fontSize: 10, color: kTextMuted)),
          ],
          const SizedBox(height: 24),
        ])))),
      ]),
    );
  }

  Future<void> _doDeleteAll(BuildContext context, AppState state) async {
    setState(() => _deleting = true);
    final allDel = state.allDeleteList;
    final count = await state.deleteFiles(List.from(allDel));
    if (!mounted) return;

    final nRev = state.reviewedAll;
    final allTot = state.totalAll;
    final allReviewed = (allTot - nRev) <= 0;

    showDialog(
      context: context, barrierDismissible: false,
      builder: (_) => _SuccessDialog(
        count: count,
        allReviewed: allReviewed,
        onHomeClean: () {
          state.clearGroupSession();
          state.clearResumeSession();
          Navigator.pushAndRemoveUntil(context, fadeRoute(const LandingScreen()), (_) => false);
        },
        onHomeSave: () {
          state.persistGroupSession();
          Navigator.pushAndRemoveUntil(context, fadeRoute(const LandingScreen()), (_) => false);
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
  final bool allReviewed;
  final VoidCallback onHomeClean, onHomeSave;
  const _SuccessDialog({required this.count, required this.allReviewed, required this.onHomeClean, required this.onHomeSave});

  @override
  Widget build(BuildContext context) {
    return Dialog(backgroundColor: kBgNav, shape: const RoundedRectangleBorder(),
      child: SizedBox(
        width: allReviewed ? 380 : 480,
        height: allReviewed ? 200 : 230,
        child: Column(children: [
          Container(height: 2, color: kTeal),
          const SizedBox(height: 26),
          const Text('Berhasil dihapus', style: TextStyle(fontFamily: 'Courier New', fontSize: 17, fontWeight: FontWeight.bold, color: kTeal)),
          const SizedBox(height: 14),
          Text('$count foto dipindahkan ke Recycle Bin.', style: const TextStyle(fontFamily: 'Consolas', fontSize: 11, color: kTextDim)),
          const SizedBox(height: 26),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            // Always show "Ke Halaman Utama"
            SweepButton(label: 'Ke Halaman Utama', height: 36, width: 160, onPressed: onHomeClean),
            // Only show "Simpan sesi" if there are skipped photos
            if (!allReviewed) ...[
              const SizedBox(width: 8),
              SweepButton(label: 'Simpan sesi & ke Utama →', bg: kAmber, hover: kAmberHov, textColor: kBg, height: 36, width: 220, onPressed: onHomeSave),
            ],
          ]),
        ]),
      ),
    );
  }
}
