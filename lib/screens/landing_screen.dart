import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

import '../theme.dart';
import '../models/app_state.dart';
import '../widgets/shared.dart';
import 'sort_screen.dart';
import 'viewer_screen.dart';
import 'date_browser_screen.dart';

// ── MTP-aware folder picker via platform channel ──
const _mtpChannel = MethodChannel('sweepe/mtp_picker');

Future<String?> _pickFolderMtp() async {
  try {
    final result = await _mtpChannel.invokeMethod<String>('pickFolder');
    return result;
  } on PlatformException {
    return null;
  }
}

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      backgroundColor: kBg,
      body: Column(
        children: [
          GestureDetector(
            onPanStart: (_) => windowManager.startDragging(),
            child: Container(
              height: 36, color: kBg,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _WinCtrl(icon: Icons.remove, onTap: () => windowManager.minimize()),
                  _WinCtrl(icon: Icons.crop_square, onTap: () async {
                    if (await windowManager.isMaximized()) { windowManager.unmaximize(); } else { windowManager.maximize(); }
                  }),
                  _WinCtrl(icon: Icons.close, color: kRose, onTap: () => windowManager.close()),
                  const SizedBox(width: 8),
                ],
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Column(
                      children: [
                        const SizedBox(height: 28),
                        const Text('Sweepe',
                            style: TextStyle(fontFamily: 'Courier New', fontSize: 80, fontWeight: FontWeight.bold, color: kText, letterSpacing: -2)),
                        const SizedBox(height: 10),
                        const Text('bersihkan galerimu, effortless.',
                            style: TextStyle(fontFamily: 'Consolas', fontSize: 18, color: kTextMuted, letterSpacing: 1)),
                        const SizedBox(height: 28),
                        const AmberRule(width: 480),
                        const SizedBox(height: 32),
                        const Text('CARA PAKAI',
                            style: TextStyle(fontFamily: 'Consolas', fontSize: 11, fontWeight: FontWeight.bold, color: kAmber, letterSpacing: 3)),
                        const SizedBox(height: 28),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            _StepCard(num: '01', title: 'Pilih Folder', desc: 'Pilih folder galeri\nyang mau dibersihkan', icon: Icons.folder_open_rounded),
                            _StepArrow(),
                            _StepCard(num: '02', title: 'Sort Foto', desc: 'Urutkan by nama,\nukuran, atau tanggal', icon: Icons.sort_rounded),
                            _StepArrow(),
                            _StepCard(num: '03', title: 'Review', desc: '← Hapus  →  Simpan\n↓  Undo    ↑  Skip', icon: Icons.swipe_rounded),
                            _StepArrow(),
                            _StepCard(num: '04', title: 'Konfirmasi', desc: 'Cek daftar hapus\nsebelum eksekusi', icon: Icons.checklist_rounded),
                            _StepArrow(),
                            _StepCard(num: '05', title: 'Recycle Bin', desc: 'Aman di Bin, hapus\nmanual kapanpun', icon: Icons.delete_outline_rounded),
                          ],
                        ),
                        const SizedBox(height: 48),
                        const AmberRule(width: 480),
                        const SizedBox(height: 40),
                        const Text('MULAI SEKARANG',
                            style: TextStyle(fontFamily: 'Consolas', fontSize: 11, fontWeight: FontWeight.bold, color: kTextMuted, letterSpacing: 3)),
                        const SizedBox(height: 20),
                        _PickFolderButton(onPressed: () => _pickFolder(context, state)),
                        const SizedBox(height: 32),
                        if (state.resumeSession != null) _ResumeCard(state: state),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickFolder(BuildContext context, AppState state) async {
    if (state.resumeSession != null) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (_) => _ConfirmDialog(
          title: 'Ganti folder?',
          body: 'Sesi sebelumnya yang belum selesai akan hilang.\nKamu tidak bisa melanjutkannya lagi.',
          confirmLabel: 'Ya, ganti folder',
          onConfirm: () => Navigator.pop(context, true),
        ),
      );
      if (confirm != true) return;
      state.clearResumeSession();
      state.clearGroupSession();
    }

    final result = await _pickFolderMtp();
    if (result != null && context.mounted) {
      Navigator.push(context, fadeRoute(SortScreen(folder: result)));
    }
  }
}

class _StepArrow extends StatelessWidget {
  const _StepArrow();
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.only(top: 60),
    child: Text('›', style: TextStyle(fontFamily: 'Courier New', fontSize: 28, color: kAmberDim)),
  );
}

class _StepCard extends StatelessWidget {
  final String num, title, desc;
  final IconData icon;
  const _StepCard({required this.num, required this.title, required this.desc, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 176, height: 220,
      decoration: BoxDecoration(color: kBgCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: kBorder)),
      child: Column(children: [
        Container(height: 3, decoration: const BoxDecoration(color: kAmberDim, borderRadius: BorderRadius.vertical(top: Radius.circular(12)))),
        const SizedBox(height: 18),
        Text(num, style: const TextStyle(fontFamily: 'Consolas', fontSize: 11, fontWeight: FontWeight.bold, color: kAmber, letterSpacing: 2)),
        const SizedBox(height: 12),
        Icon(icon, size: 30, color: kAmberDim),
        const SizedBox(height: 12),
        Text(title, style: const TextStyle(fontFamily: 'Courier New', fontSize: 16, fontWeight: FontWeight.bold, color: kText)),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(desc, style: const TextStyle(fontFamily: 'Consolas', fontSize: 12, color: kTextMuted, height: 1.6), textAlign: TextAlign.center),
        ),
      ]),
    );
  }
}

class _ResumeCard extends StatelessWidget {
  final AppState state;
  const _ResumeCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final s = state.resumeSession!;
    final isGroup = s['_is_group'] == true;
    final folder = (s['folder'] as String? ?? '').split(RegExp(r'[/\\]')).last;
    String hint;
    if (isGroup) {
      hint = '${state.reviewedAll} / ${state.totalAll} foto direview  ·  per tanggal';
    } else {
      final ri = (s['resume_index'] as int? ?? 0);
      final remaining = (s['remaining'] as List?)?.length ?? 0;
      hint = '${remaining - ri} belum direview  ·  $ri / $remaining selesai';
    }
    return Container(
      width: 560, height: 88,
      decoration: BoxDecoration(color: kBgCard, border: Border.all(color: kAmberDim), borderRadius: BorderRadius.circular(8)),
      child: Row(children: [
        Container(width: 4, decoration: const BoxDecoration(color: kAmber, borderRadius: BorderRadius.horizontal(left: Radius.circular(8)))),
        const SizedBox(width: 20),
        Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Resume  "$folder"', style: const TextStyle(fontFamily: 'Courier New', fontSize: 14, fontWeight: FontWeight.bold, color: kAmber)),
          const SizedBox(height: 5),
          Text(hint, style: const TextStyle(fontFamily: 'Consolas', fontSize: 12, color: kTextMuted)),
        ])),
        TextButton(
          onPressed: () { state.clearResumeSession(); state.clearGroupSession(); },
          style: TextButton.styleFrom(foregroundColor: kTextMuted),
          child: const Text('Buang', style: TextStyle(fontFamily: 'Consolas', fontSize: 11, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 8),
        SweepButton(label: 'Lanjut →', bg: kAmber, hover: kAmberHov, textColor: kBg, height: 38, width: 100, onPressed: () => _resume(context)),
        const SizedBox(width: 20),
      ]),
    );
  }

  void _resume(BuildContext context) {
    final isGroup = state.resumeSession?['_is_group'] == true;
    if (isGroup) {
      Navigator.push(context, fadeRoute(const DateBrowserScreen()));
    } else {
      state.resumeFlat();
      Navigator.push(context, fadeRoute(const ViewerScreen()));
    }
  }
}

class _ConfirmDialog extends StatelessWidget {
  final String title, body, confirmLabel;
  final VoidCallback onConfirm;
  const _ConfirmDialog({required this.title, required this.body, required this.confirmLabel, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: kBgNav, shape: const RoundedRectangleBorder(),
      child: SizedBox(width: 480, height: 220, child: Column(children: [
        Container(height: 2, color: kAmber),
        const SizedBox(height: 30),
        Text(title, style: const TextStyle(fontFamily: 'Courier New', fontSize: 17, fontWeight: FontWeight.bold, color: kText)),
        const SizedBox(height: 18),
        Text(body, style: const TextStyle(fontFamily: 'Consolas', fontSize: 12, color: kTextDim), textAlign: TextAlign.center),
        const SizedBox(height: 30),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          SweepButton(label: 'Batal', height: 40, width: 110, onPressed: () => Navigator.pop(context, false)),
          const SizedBox(width: 14),
          SweepButton(label: confirmLabel, bg: kAmber, hover: kAmberHov, textColor: kBg, height: 40, width: 180, onPressed: onConfirm),
        ]),
      ])),
    );
  }
}

class _PickFolderButton extends StatefulWidget {
  final VoidCallback onPressed;
  const _PickFolderButton({required this.onPressed});
  @override State<_PickFolderButton> createState() => _PickFolderButtonState();
}
class _PickFolderButtonState extends State<_PickFolderButton> {
  bool _hov = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hov = true),
      onExit: (_) => setState(() => _hov = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 320, height: 68,
          decoration: BoxDecoration(
            color: _hov ? kAmberHov : kAmber,
            borderRadius: BorderRadius.circular(10),
            boxShadow: _hov ? [BoxShadow(color: kAmber.withAlpha(80), blurRadius: 24, spreadRadius: 2)] : [],
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.folder_open_rounded, size: 22, color: Color(0xFF0C0C0E)),
            const SizedBox(width: 12),
            const Text('Pilih Folder Sekarang',
                style: TextStyle(fontFamily: 'Courier New', fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0C0C0E))),
            const SizedBox(width: 10),
            AnimatedSlide(
              duration: const Duration(milliseconds: 150),
              offset: _hov ? const Offset(0.2, 0) : Offset.zero,
              child: const Text('→', style: TextStyle(fontFamily: 'Courier New', fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0C0C0E))),
            ),
          ]),
        ),
      ),
    );
  }
}

class _WinCtrl extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _WinCtrl({required this.icon, required this.onTap, this.color = kTextMuted});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
        child: Icon(icon, size: 14, color: color),
      ),
    );
  }
}
