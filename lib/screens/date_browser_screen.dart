import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

import '../theme.dart';
import '../models/app_state.dart';
import '../widgets/shared.dart';
import 'viewer_screen.dart';
import 'group_summary_screen.dart';
import 'global_summary_screen.dart';
import 'landing_screen.dart';

class DateBrowserScreen extends StatelessWidget {
  const DateBrowserScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final years = state.yearMap.keys.toList()..sort((a, b) => b.compareTo(a));
    final tot = state.totalAll;
    final rev = state.reviewedAll;
    final globalPct = tot > 0 ? rev / tot : 0.0;

    return Scaffold(
      backgroundColor: kBg,
      body: Column(children: [
        _BrowserNavBar(
          onBack: () => _showBackDialog(context, state),
          onDone: () => Navigator.push(context, fadeRoute(const GlobalSummaryScreen())),
        ),
        const SizedBox(height: 24),
        Text(
          state.currentFolder?.split(RegExp(r'[/\\]')).last ?? 'Pilih Grup Foto',
          style: const TextStyle(fontFamily: 'Courier New', fontSize: 22, fontWeight: FontWeight.bold, color: kText),
        ),
        const SizedBox(height: 8),
        // Global progress bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 160),
          child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('$rev / $tot direview',
                  style: const TextStyle(fontFamily: 'Consolas', fontSize: 12, color: kAmber)),
              Text('${state.deletedAll} ditandai hapus',
                  style: const TextStyle(fontFamily: 'Consolas', fontSize: 12, color: kRose)),
            ]),
            const SizedBox(height: 5),
            _ProgressBar(total: tot, nKeep: state.keptAll, nDelete: state.deletedAll, height: 4),
          ]),
        ),
        const SizedBox(height: 12),
        const AmberRule(width: 560),
        const SizedBox(height: 4),
        Expanded(
          child: Center(
            child: SizedBox(
              width: 700,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: years.length,
                itemBuilder: (_, i) => _YearRow(year: years[i], state: state),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
      ]),
    );
  }
}

// ── Back dialog helper ───────────────────────────
void _showBackDialog(BuildContext context, AppState state) {
  showDialog(context: context, builder: (_) => _BackConfirmDialog(
    onSaveAndExit: () {
      state.persistGroupSession();
      Navigator.pop(context); // close dialog
      Navigator.pushAndRemoveUntil(context, fadeRoute(const LandingScreen()), (_) => false);
    },
    onDiscard: () {
      state.clearGroupSession();
      state.clearResumeSession();
      Navigator.pop(context); // close dialog
      Navigator.pushAndRemoveUntil(context, fadeRoute(const LandingScreen()), (_) => false);
    },
    onCancel: () => Navigator.pop(context),
  ));
}

class _BackConfirmDialog extends StatelessWidget {
  final VoidCallback onSaveAndExit, onDiscard, onCancel;
  const _BackConfirmDialog({required this.onSaveAndExit, required this.onDiscard, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: kBgNav, shape: const RoundedRectangleBorder(),
      child: SizedBox(width: 500, height: 230, child: Column(children: [
        Container(height: 2, color: kAmber),
        const SizedBox(height: 24),
        const Text('Keluar dari sesi ini?', style: TextStyle(
            fontFamily: 'Courier New', fontSize: 17, fontWeight: FontWeight.bold, color: kText)),
        const SizedBox(height: 14),
        const Text('Progress kamu akan disimpan.\nKamu bisa lanjutin nanti dari halaman utama.',
            style: TextStyle(fontFamily: 'Consolas', fontSize: 12, color: kTextDim),
            textAlign: TextAlign.center),
        const SizedBox(height: 26),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          SweepButton(label: 'Lanjut beberes', height: 38, width: 150, onPressed: onCancel),
          const SizedBox(width: 10),
          SweepButton(label: 'Simpan & ke utama', bg: kAmber, hover: kAmberHov,
              textColor: kBg, height: 38, width: 170, onPressed: onSaveAndExit),
          const SizedBox(width: 10),
          SweepButton(label: 'Buang sesi', outlined: true,
              borderColor: kRose, textColor: kRose, height: 38, width: 120, onPressed: onDiscard),
        ]),
      ])),
    );
  }
}

// ── Tri-color progress bar ────────────────────────
class _ProgressBar extends StatelessWidget {
  final int total, nKeep, nDelete;
  final double height;
  const _ProgressBar({
    required this.total,
    required this.nKeep,
    required this.nDelete,
    this.height = 3,
  });

  @override
  Widget build(BuildContext context) {
    if (total == 0) return SizedBox(height: height);
    return LayoutBuilder(builder: (_, c) {
      final w = c.maxWidth;
      final keepW   = (nKeep   / total * w).clamp(0.0, w);
      final deleteW = (nDelete / total * w).clamp(0.0, w - keepW);
      return ClipRRect(
        borderRadius: BorderRadius.circular(height),
        child: SizedBox(height: height, width: w,
          child: Stack(children: [
            Container(color: kBgCard),
            Container(width: keepW, color: kTeal),
            Positioned(
              left: keepW,
              child: Container(width: deleteW, height: height, color: kRose),
            ),
          ]),
        ),
      );
    });
  }
}

// ── Year row ──────────────────────────────────────
class _YearRow extends StatelessWidget {
  final int year;
  final AppState state;
  const _YearRow({required this.year, required this.state});

  @override
  Widget build(BuildContext context) {
    final yrPaths = state.pathsForYear(year);
    final (yrRev, yrTot) = state.progressFor(yrPaths);
    final yrDone = yrRev >= yrTot && yrTot > 0;
    final yrExecuted = state.isYearExecuted(year);
    final expanded = state.isYearExpanded(year);
    final moMap = state.yearMap[year] ?? {};
    final pct = yrTot > 0 ? yrRev / yrTot : 0.0;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        height: 60,
        color: kBgCard,
        margin: const EdgeInsets.only(bottom: 3),
        child: Column(children: [
          Expanded(child: Row(children: [
            const SizedBox(width: 12),
            _ExpandBtn(expanded: expanded, color: kAmber,
                onTap: () => state.toggleYear(year)),
            const SizedBox(width: 10),
            Text('$year', style: TextStyle(fontFamily: 'Courier New', fontSize: 18,
                fontWeight: FontWeight.bold,
                color: yrExecuted ? kTextMuted : (yrDone ? kTeal : kText),
                decoration: yrExecuted ? TextDecoration.lineThrough : null,
                decorationColor: kTextMuted)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text('|', style: TextStyle(fontFamily: 'Consolas', fontSize: 14,
                  color: yrExecuted ? kTextMuted.withAlpha(80) : kBorderLt)),
            ),
            Text('$yrRev / $yrTot', style: TextStyle(fontFamily: 'Consolas',
                fontSize: 13, color: yrExecuted ? kTextMuted : (yrDone ? kTeal : kTextMuted))),
            const Spacer(),
            _IBtn(
              icon: Icons.play_arrow_rounded,
              label: 'Review semua',
              color: kTextDim, hoverBg: kAmber,
              width: 148, height: 36,
              onTap: () { state.launchGroupViewer(yrPaths, GroupKey(year, 0, 0)); _goViewer(context); },
            ),
            const SizedBox(width: 6),
            _IBtn(
              icon: Icons.bolt_rounded,
              label: 'Eksekusi',
              color: kTeal, hoverBg: kTeal,
              width: 106, height: 36,
              onTap: () { state.executeGroup(yrPaths, state.weekKeysForYear(year), GroupKey(year, 0, 0)); _goSummary(context); },
            ),
            const SizedBox(width: 6),
            _IBtn(
              icon: Icons.refresh_rounded,
              label: 'Reset',
              color: kRose, hoverBg: kRose,
              width: 84, height: 36,
              onTap: () => state.resetGroupKeys(state.weekKeysForYear(year)),
            ),
            const SizedBox(width: 12),
          ])),
          Padding(
            padding: const EdgeInsets.only(left: 12, right: 10, bottom: 5),
            child: _ProgressBar(total: yrTot, nKeep: state.keepCountFor(yrPaths), nDelete: state.deleteCountFor(yrPaths), height: 3),
          ),
        ]),
      ),
      if (expanded)
        for (final mo in (moMap.keys.toList()..sort((a, b) => b.compareTo(a))))
          _MonthRow(year: year, month: mo, state: state),
    ]);
  }

  void _goViewer(BuildContext ctx) => Navigator.push(ctx, fadeRoute(const ViewerScreen(isGroupMode: true)));
  void _goSummary(BuildContext ctx) => Navigator.push(ctx, fadeRoute(const GroupSummaryScreen()));
}

// ── Month row ─────────────────────────────────────
class _MonthRow extends StatelessWidget {
  final int year, month;
  final AppState state;
  const _MonthRow({required this.year, required this.month, required this.state});

  @override
  Widget build(BuildContext context) {
    final moPaths = state.pathsForMonth(year, month);
    final (moRev, moTot) = state.progressFor(moPaths);
    final moDone = moRev >= moTot && moTot > 0;
    final moExecuted = state.isMonthExecuted(year, month);
    final expanded = state.isMonthExpanded(year, month);
    final moName = AppState.monthName(month);
    final wkMap = state.yearMap[year]?[month] ?? {};
    final pct = moTot > 0 ? moRev / moTot : 0.0;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        height: 56,
        margin: const EdgeInsets.only(left: 24, bottom: 3),
        decoration: BoxDecoration(color: kBgCard2, borderRadius: BorderRadius.circular(6)),
        child: Column(children: [
          Expanded(child: Row(children: [
            const SizedBox(width: 10),
            _ExpandBtn(expanded: expanded, color: kAmberGlow,
                onTap: () => state.toggleMonth(year, month)),
            const SizedBox(width: 8),
            Text(moName, style: TextStyle(fontFamily: 'Courier New', fontSize: 15,
                fontWeight: FontWeight.bold,
                color: moExecuted ? kTextMuted : (moDone ? kTeal : kText),
                decoration: moExecuted ? TextDecoration.lineThrough : null,
                decorationColor: kTextMuted)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text('|', style: TextStyle(fontFamily: 'Consolas', fontSize: 13,
                  color: moExecuted ? kTextMuted.withAlpha(80) : kBorderLt)),
            ),
            Text('$moRev / $moTot', style: TextStyle(fontFamily: 'Consolas',
                fontSize: 12, color: moExecuted ? kTextMuted : (moDone ? kTeal : kTextMuted))),
            const Spacer(),
            _IBtn(
              icon: Icons.play_arrow_rounded,
              label: 'Review',
              color: kTextDim, hoverBg: kAmber,
              width: 100, height: 32,
              onTap: () { state.launchGroupViewer(moPaths, GroupKey(year, month, 0)); Navigator.push(context, fadeRoute(const ViewerScreen(isGroupMode: true))); },
            ),
            const SizedBox(width: 5),
            _IBtn(
              icon: Icons.bolt_rounded,
              color: kTeal, hoverBg: kTeal,
              width: 36, height: 32,
              onTap: () { state.executeGroup(moPaths, state.weekKeysForMonth(year, month), GroupKey(year, month, 0)); Navigator.push(context, fadeRoute(GroupSummaryScreen(label: '$moName $year'))); },
            ),
            const SizedBox(width: 5),
            _IBtn(
              icon: Icons.refresh_rounded,
              color: kRose, hoverBg: kRose,
              width: 36, height: 32,
              onTap: () => state.resetGroupKeys(state.weekKeysForMonth(year, month)),
            ),
            const SizedBox(width: 10),
          ])),
          Padding(
            padding: const EdgeInsets.only(left: 10, right: 8, bottom: 4),
            child: _ProgressBar(total: moTot, nKeep: state.keepCountFor(moPaths), nDelete: state.deleteCountFor(moPaths), height: 2),
          ),
        ]),
      ),
      if (expanded)
        for (final wk in (wkMap.keys.toList()..sort()))
          _WeekRow(year: year, month: month, week: wk, state: state),
    ]);
  }
}

// ── Week row ──────────────────────────────────────
class _WeekRow extends StatelessWidget {
  final int year, month, week;
  final AppState state;
  const _WeekRow({required this.year, required this.month, required this.week, required this.state});

  @override
  Widget build(BuildContext context) {
    final key = GroupKey(year, month, week);
    final paths = state.dateGroups[key] ?? [];
    final (wkRev, wkTot) = state.progressFor(paths);
    final wkDone = wkRev >= wkTot && wkTot > 0;
    final wkExecuted = state.isWeekExecuted(key);
    final gp = state.groupProgress[key];
    final nDel = gp?.delete.length ?? 0;
    final pct = wkTot > 0 ? wkRev / wkTot : 0.0;
    final moName = AppState.monthName(month);

    // Compute date range from file modified dates
    String dateRange = '';
    try {
      final dates = paths.map((p) => File(p).lastModifiedSync()).toList();
      if (dates.isNotEmpty) {
        dates.sort();
        final first = dates.first;
        final last = dates.last;
        if (first.day == last.day) {
          dateRange = '${first.day} $moName';
        } else {
          dateRange = '${first.day} – ${last.day} $moName';
        }
      }
    } catch (_) {}

    return Container(
      height: 56,
      margin: const EdgeInsets.only(left: 52, bottom: 3),
      decoration: BoxDecoration(color: kBgDeep, borderRadius: BorderRadius.circular(4)),
      child: Column(children: [
        Expanded(child: Row(children: [
          const SizedBox(width: 6),
          Container(width: 3, height: 28, decoration: BoxDecoration(
            color: wkDone ? kTeal : kAmberDim,
            borderRadius: BorderRadius.circular(2),
          )),
          const SizedBox(width: 10),
          Text('Week $week', style: TextStyle(fontFamily: 'Consolas', fontSize: 13,
              fontWeight: FontWeight.bold,
              color: wkExecuted ? kTextMuted : (wkDone ? kTeal : kTextDim),
              decoration: wkExecuted ? TextDecoration.lineThrough : null,
              decorationColor: kTextMuted)),
          if (dateRange.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text('|', style: TextStyle(fontFamily: 'Consolas', fontSize: 12,
                  color: wkExecuted ? kTextMuted.withAlpha(80) : kBorderLt)),
            ),
            Text(dateRange, style: TextStyle(fontFamily: 'Consolas', fontSize: 11,
                color: wkExecuted ? kTextMuted : (wkDone ? kTeal.withAlpha(180) : kTextMuted))),
          ],
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text('|', style: TextStyle(fontFamily: 'Consolas', fontSize: 12,
                color: wkExecuted ? kTextMuted.withAlpha(80) : kBorderLt)),
          ),
          Text('$wkRev / $wkTot', style: TextStyle(fontFamily: 'Consolas',
              fontSize: 12, color: wkExecuted ? kTextMuted : (wkDone ? kTeal : kTextMuted))),
          if (nDel > 0) ...[
            const SizedBox(width: 8),
            Text('$nDel hapus', style: const TextStyle(fontFamily: 'Consolas',
                fontSize: 10, color: kRose)),
          ],
          const Spacer(),
          _IBtn(
            icon: Icons.play_arrow_rounded,
            color: kTextDim, hoverBg: kAmber,
            width: 36, height: 32,
            onTap: () { state.launchGroupViewer(paths, key); Navigator.push(context, fadeRoute(const ViewerScreen(isGroupMode: true))); },
          ),
          const SizedBox(width: 5),
          _IBtn(
            icon: Icons.bolt_rounded,
            color: kTeal, hoverBg: kTeal,
            width: 36, height: 32,
            onTap: () { state.executeGroup(paths, [key], key); Navigator.push(context, fadeRoute(GroupSummaryScreen(label: 'Week $week · $moName $year'))); },
          ),
          const SizedBox(width: 5),
          _IBtn(
            icon: Icons.refresh_rounded,
            color: kRose, hoverBg: kRose,
            width: 36, height: 32,
            onTap: () => state.resetGroupKeys([key]),
          ),
          const SizedBox(width: 12),
        ])),
        Padding(
          padding: const EdgeInsets.only(left: 19, right: 8, bottom: 4),
          child: _ProgressBar(total: wkTot, nKeep: gp?.keep.length ?? 0, nDelete: nDel, height: 2),
        ),
      ]),
    );
  }
}

// ── Icon button with optional label ──────────────
class _IBtn extends StatefulWidget {
  final IconData icon;
  final String? label;        // if set, shows label + icon side by side
  final Color color, hoverBg;
  final double width, height;
  final VoidCallback onTap;
  const _IBtn({
    required this.icon,
    required this.color,
    required this.onTap,
    this.label,
    this.hoverBg = kBtnSecHov,
    this.width = 36,
    this.height = 36,
  });
  @override State<_IBtn> createState() => _IBtnState();
}
class _IBtnState extends State<_IBtn> {
  bool _hov = false;
  @override
  Widget build(BuildContext context) {
    final activeColor = _hov ? widget.color : widget.color.withAlpha(170);
    return MouseRegion(
      onEnter: (_) => setState(() => _hov = true),
      onExit: (_) => setState(() => _hov = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: widget.width, height: widget.height,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: _hov ? widget.hoverBg.withAlpha(80) : kBtnSec,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.label != null) ...[
                Text(widget.label!, style: TextStyle(
                    fontFamily: 'Consolas', fontSize: 11,
                    fontWeight: FontWeight.bold, color: activeColor)),
                const SizedBox(width: 5),
              ],
              Icon(widget.icon, size: 14, color: activeColor),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Expand toggle button ──────────────────────────
class _ExpandBtn extends StatefulWidget {
  final bool expanded;
  final Color color;
  final VoidCallback onTap;
  const _ExpandBtn({required this.expanded, required this.color, required this.onTap});
  @override State<_ExpandBtn> createState() => _ExpandBtnState();
}
class _ExpandBtnState extends State<_ExpandBtn> {
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
          width: 28, height: 28,
          decoration: BoxDecoration(
            color: _hov ? kBtnSecHov : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          alignment: Alignment.center,
          child: Icon(
            widget.expanded ? Icons.keyboard_arrow_down_rounded : Icons.keyboard_arrow_right_rounded,
            size: 18, color: widget.color,
          ),
        ),
      ),
    );
  }
}

// ── Browser navbar ────────────────────────────────
class _BrowserNavBar extends StatelessWidget {
  final VoidCallback onBack, onDone;
  const _BrowserNavBar({required this.onBack, required this.onDone});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (_) => windowManager.startDragging(),
      child: Container(height: 48, color: kBgNav, child: Stack(children: [
        Positioned(bottom: 0, left: 0, right: 0, child: Container(height: 1, color: kAmberDim)),
        Positioned(left: 12, top: 0, bottom: 0, child: Center(child: _HovTxt(
            label: '← Back', color: kTextDim, onTap: onBack))),
        const Center(child: Text('Sweepe', style: TextStyle(fontFamily: 'Courier New',
            fontSize: 13, fontWeight: FontWeight.bold, color: kAmber))),
        Positioned(right: 8, top: 0, bottom: 0, child: Row(mainAxisSize: MainAxisSize.min, children: [
          _HovTxt(label: 'Selesai →', color: kTeal, onTap: onDone),
          const SizedBox(width: 4),
          InkWell(onTap: () => windowManager.minimize(),
              child: const Padding(padding: EdgeInsets.all(6), child: Icon(Icons.remove, size: 14, color: kTextMuted))),
          const SizedBox(width: 2),
          InkWell(onTap: () async { if (await windowManager.isMaximized()) { windowManager.unmaximize(); } else { windowManager.maximize(); } },
              child: const Padding(padding: EdgeInsets.all(6), child: Icon(Icons.crop_square, size: 14, color: kTextMuted))),
          const SizedBox(width: 2),
          InkWell(onTap: () => windowManager.close(),
              child: const Padding(padding: EdgeInsets.all(6), child: Icon(Icons.close, size: 14, color: kRose))),
        ])),
      ])),
    );
  }
}

class _HovTxt extends StatefulWidget {
  final String label; final Color color; final VoidCallback onTap;
  const _HovTxt({required this.label, required this.color, required this.onTap});
  @override State<_HovTxt> createState() => _HovTxtState();
}
class _HovTxtState extends State<_HovTxt> {
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
              fontSize: 12, fontWeight: FontWeight.bold, color: widget.color)),
        ),
      ),
    );
  }
}
