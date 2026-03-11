import 'dart:io';
import 'package:flutter/material.dart';
import '../theme.dart';

// ── Shared fade route ─────────────────────────────
PageRouteBuilder fadeRoute(Widget page) => PageRouteBuilder(
      pageBuilder: (_, __, ___) => page,
      transitionDuration: const Duration(milliseconds: 160),
      transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
    );

// ── Shared navbar ─────────────────────────────────
class SweepNavBar extends StatelessWidget {
  final String title;
  final VoidCallback? onBack;
  final String? doneLabel;
  final VoidCallback? onDone;
  final bool showDone;
  final bool showMinimize;

  const SweepNavBar({
    super.key,
    this.title = 'Sweepe',
    this.onBack,
    this.doneLabel,
    this.onDone,
    this.showDone = false,
    this.showMinimize = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (_) {},
      child: Container(
        height: 48, color: kBgNav,
        child: Stack(children: [
          Positioned(bottom: 0, left: 0, right: 0, child: Container(height: 1, color: kAmberDim)),
          if (onBack != null)
            Positioned(left: 12, top: 0, bottom: 0,
                child: Center(child: _NavTextBtn(label: '← Back', color: kTextDim, onTap: onBack!))),
          Center(child: Text(title,
              style: const TextStyle(fontFamily: 'Courier New', fontSize: 13, fontWeight: FontWeight.bold, color: kAmber))),
          Positioned(right: 8, top: 0, bottom: 0,
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                if (showDone && onDone != null)
                  _NavTextBtn(label: doneLabel ?? 'Selesai →', color: kTeal, onTap: onDone!),
                if (showDone && onDone != null) const SizedBox(width: 8),
                if (showMinimize) ...[
                  _WinBtn(icon: Icons.remove, onTap: () {}),
                  const SizedBox(width: 4),
                ],
                _WinBtn(icon: Icons.close, color: kRose, onTap: () {}),
              ])),
        ]),
      ),
    );
  }
}

class _NavTextBtn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _NavTextBtn({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: color, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        textStyle: const TextStyle(fontFamily: 'Consolas', fontSize: 11, fontWeight: FontWeight.bold),
      ),
      child: Text(label),
    );
  }
}

class _WinBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _WinBtn({required this.icon, required this.onTap, this.color = kTextMuted});
  @override
  Widget build(BuildContext context) {
    return InkWell(onTap: onTap, child: Padding(padding: const EdgeInsets.all(6), child: Icon(icon, size: 14, color: color)));
  }
}

// ── Stat pill ─────────────────────────────────────
class StatPill extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final double width;
  const StatPill({super.key, required this.label, required this.value, required this.color, this.width = 110});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width, height: 80,
      decoration: BoxDecoration(color: kBgCard, border: Border(
        top: BorderSide(color: color, width: 2),
        left: BorderSide(color: color), right: BorderSide(color: color), bottom: BorderSide(color: color),
      )),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text('$value', style: TextStyle(fontFamily: 'Courier New', fontSize: 30, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 3),
        Text(label, style: const TextStyle(fontFamily: 'Consolas', fontSize: 11, color: kTextMuted)),
      ]),
    );
  }
}

// ── Freed card (reward display) ───────────────────
class FreedCard extends StatelessWidget {
  final String size;
  const FreedCard({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    // Split e.g. "500.0 MB" → ["500.0", "MB"]
    final parts = size.split(' ');
    final number = parts.isNotEmpty ? parts[0] : size;
    final unit   = parts.length > 1  ? parts[1] : '';

    return Container(
      width: 130, height: 80,
      decoration: BoxDecoration(
        color: kBgCard,
        border: Border(
          top:    BorderSide(color: kTeal, width: 2),
          left:   BorderSide(color: kTeal),
          right:  BorderSide(color: kTeal),
          bottom: BorderSide(color: kTeal),
        ),
      ),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(number, style: const TextStyle(
                fontFamily: 'Courier New',
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: kTeal)),
            const SizedBox(width: 4),
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(unit, style: const TextStyle(
                  fontFamily: 'Consolas',
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: kTeal)),
            ),
          ],
        ),
        const SizedBox(height: 3),
        const Text('dikosongkan', style: TextStyle(
            fontFamily: 'Consolas', fontSize: 10, color: kTextMuted)),
      ]),
    );
  }
}

// ── Amber rule ────────────────────────────────────
class AmberRule extends StatelessWidget {
  final double width;
  const AmberRule({super.key, this.width = 320});
  @override
  Widget build(BuildContext context) => Container(width: width, height: 1, color: kAmberDim);
}

// ── Sweep button with hover ───────────────────────
class SweepButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color bg, hover, textColor;
  final double height, width;
  final bool outlined;
  final Color? borderColor;
  const SweepButton({super.key, required this.label, this.onPressed, this.bg = kBtnSec, this.hover = kBtnSecHov, this.textColor = kText, this.height = 42, this.width = 160, this.outlined = false, this.borderColor});

  @override
  State<SweepButton> createState() => _SweepButtonState();
}

class _SweepButtonState extends State<SweepButton> {
  bool _hov = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hov = true),
      onExit: (_) => setState(() => _hov = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: widget.width, height: widget.height,
          decoration: BoxDecoration(
            color: widget.outlined ? Colors.transparent : (_hov ? widget.hover : widget.bg),
            borderRadius: BorderRadius.circular(8),
            border: widget.outlined ? Border.all(color: widget.borderColor ?? kBorder) : (_hov ? Border.all(color: widget.hover) : null),
          ),
          alignment: Alignment.center,
          child: Text(widget.label, style: TextStyle(fontFamily: 'Courier New', fontSize: widget.height >= 42 ? 12 : 11, fontWeight: FontWeight.bold, color: widget.textColor)),
        ),
      ),
    );
  }
}

// ── Delete list card ──────────────────────────────
class DeleteListCard extends StatelessWidget {
  final List<String> files;
  final double height;
  const DeleteListCard({super.key, required this.files, this.height = 220});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(color: kBgCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: kBorder)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
          child: Row(children: [
            const Text('Files yang akan dihapus', style: TextStyle(fontFamily: 'Courier New', fontSize: 11, fontWeight: FontWeight.bold, color: kRose)),
            const SizedBox(width: 6),
            Text('${files.length}', style: const TextStyle(fontFamily: 'Consolas', fontSize: 11, color: kTextMuted)),
          ]),
        ),
        Expanded(
          child: files.isEmpty
              ? const Center(child: Text('Tidak ada foto yang ditandai untuk dihapus.', style: TextStyle(fontFamily: 'Consolas', fontSize: 11, color: kTextMuted)))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
                  itemCount: files.length,
                  itemBuilder: (_, i) => _FileRow(path: files[i]),
                ),
        ),
      ]),
    );
  }
}

class _FileRow extends StatelessWidget {
  final String path;
  const _FileRow({required this.path});

  @override
  Widget build(BuildContext context) {
    final name = path.split(RegExp(r'[/\\]')).last;
    String size = '?';
    try {
      final bytes = File(path).lengthSync();
      final kb = bytes / 1024;
      size = kb < 1024 ? '${kb.toStringAsFixed(0)} KB' : '${(kb / 1024).toStringAsFixed(1)} MB';
    } catch (_) {}
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(children: [
        const SizedBox(width: 4),
        const Text('—', style: TextStyle(fontFamily: 'Consolas', fontSize: 9, color: kRose)),
        const SizedBox(width: 6),
        Expanded(child: Text(name, style: const TextStyle(fontFamily: 'Consolas', fontSize: 11, color: kTextDim), overflow: TextOverflow.ellipsis)),
        const SizedBox(width: 8),
        SizedBox(width: 60, child: Text(size, style: const TextStyle(fontFamily: 'Consolas', fontSize: 9, color: kTextMuted), textAlign: TextAlign.right)),
      ]),
    );
  }
}
