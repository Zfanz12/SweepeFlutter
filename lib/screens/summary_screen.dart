import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

import '../theme.dart';
import '../models/app_state.dart';
import '../widgets/shared.dart';
import 'viewer_screen.dart';
import 'landing_screen.dart';

class SummaryScreen extends StatefulWidget {
  const SummaryScreen({super.key});

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  bool _deleting = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final nDel = state.toDelete.length;
    final nKeep = state.toKeep.length;
    final nRev = nDel + nKeep;
    final nSkip = state.images.length - nRev;
    final tb = _totalBytes(state.toDelete);
    final ts = AppState.formatSize(tb);

    return Scaffold(
      backgroundColor: kBg,
      body: Column(
        children: [
          _SummaryNavBar(),
          Expanded(
            child: Center(
              child: SizedBox(
                width: 680,
                child: Column(
                  children: [
                    const SizedBox(height: 32),
                    const Text('Review & Konfirmasi',
                        style: TextStyle(fontFamily: 'Courier New', fontSize: 22, fontWeight: FontWeight.bold, color: kText)),
                    const SizedBox(height: 10),
                    const AmberRule(width: 320),
                    const SizedBox(height: 22),
                    // Pills
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        StatPill(label: 'Direview', value: nRev, color: kAmber),
                        const SizedBox(width: 10),
                        FreedCard(size: ts),
                        const SizedBox(width: 10),
                        StatPill(label: 'Disimpan', value: nKeep, color: kTeal),
                        const SizedBox(width: 10),
                        StatPill(label: 'Dihapus', value: nDel, color: kRose),
                        if (nSkip > 0) ...[
                          const SizedBox(width: 10),
                          StatPill(label: 'Dilewati', value: nSkip, color: kTextMuted),
                        ],
                      ],
                    ),
                    const SizedBox(height: 20),
                    // File list
                    Expanded(
                      child: DeleteListCard(files: state.toDelete),
                    ),
                    const SizedBox(height: 18),
                    // Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SweepButton(
                          label: '← Cek lagi',
                          height: 42, width: 150,
                          onPressed: () async {
                            state.index = 0;
                            await windowManager.maximize();
                            if (context.mounted) Navigator.pushReplacement(context, fadeRoute(const ViewerScreen()));
                          },
                        ),
                        const SizedBox(width: 16),
                        SweepButton(
                          label: _deleting ? 'Menghapus...' : 'Hapus sekarang',
                          bg: kRose, hover: kRoseHov, textColor: kText,
                          height: 42, width: 200,
                          onPressed: _deleting ? null : () => _doDelete(context, state),
                        ),
                      ],
                    ),
                    if (nSkip > 0) ...[
                      const SizedBox(height: 10),
                      Text('$nSkip foto dilewati — bisa dilanjutin dari halaman utama',
                          style: const TextStyle(fontFamily: 'Consolas', fontSize: 10, color: kTextMuted)),
                    ],
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _doDelete(BuildContext context, AppState state) async {
    setState(() => _deleting = true);
    final count = await state.deleteFiles(List.from(state.toDelete));
    if (!mounted) return;
    state.persistFlatSession(resumeIndex: state.index);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _SuccessDialog(
        count: count,
        hasResume: state.resumeSession != null,
        onHome: () {
          Navigator.pop(context);
          Navigator.pushAndRemoveUntil(context, fadeRoute(const LandingScreen()), (_) => false);
        },
      ),
    );
  }

  int _totalBytes(List<String> paths) {
    int total = 0;
    for (final p in paths) {
      try { total += File(p).lengthSync(); } catch (_) {}
    }
    return total;
  }
}

class _SummaryNavBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (_) => windowManager.startDragging(),
      child: Container(
        height: 48, color: kBgNav,
        child: Stack(children: [
          Positioned(bottom: 0, left: 0, right: 0, child: Container(height: 1, color: kAmberDim)),
          const Center(child: Text('Sweepe', style: TextStyle(fontFamily: 'Courier New', fontSize: 13, fontWeight: FontWeight.bold, color: kAmber))),
          Positioned(right: 8, top: 0, bottom: 0,
              child: Row(mainAxisSize: MainAxisSize.min, children: [
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
  final bool hasResume;
  final VoidCallback onHome;
  const _SuccessDialog({required this.count, required this.hasResume, required this.onHome});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: kBgNav,
      shape: const RoundedRectangleBorder(),
      child: SizedBox(
        width: 360, height: 190,
        child: Column(children: [
          Container(height: 2, color: kTeal),
          const SizedBox(height: 28),
          const Text('Berhasil dihapus', style: TextStyle(fontFamily: 'Courier New', fontSize: 17, fontWeight: FontWeight.bold, color: kTeal)),
          const SizedBox(height: 14),
          Text('$count foto dipindahkan ke Recycle Bin.',
              style: const TextStyle(fontFamily: 'Consolas', fontSize: 11, color: kTextDim)),
          if (hasResume) ...[
            const SizedBox(height: 6),
            const Text('Foto yang dilewati siap dilanjutin dari halaman utama.',
                style: TextStyle(fontFamily: 'Consolas', fontSize: 10, color: kAmber)),
          ],
          const SizedBox(height: 22),
          SweepButton(label: 'Ke Halaman Utama', bg: kAmber, hover: kAmberHov, textColor: kBg, height: 36, width: 160, onPressed: onHome),
        ]),
      ),
    );
  }
}

