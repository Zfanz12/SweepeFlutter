import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

const _kSessionKey = 'sweepe_session';

const List<String> kImageExtensions = [
  '.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'
];

// ── Date group key ────────────────────────────────
class GroupKey {
  final int year, month, week;
  const GroupKey(this.year, this.month, this.week);

  @override
  bool operator ==(Object other) =>
      other is GroupKey && year == other.year && month == other.month && week == other.week;

  @override
  int get hashCode => Object.hash(year, month, week);

  String toJson() => '$year,$month,$week';
  static GroupKey fromJson(String s) {
    final parts = s.split(',');
    return GroupKey(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
  }

  @override
  String toString() => 'GroupKey($year, $month, $week)';
}

// ── Group progress ────────────────────────────────
class GroupProgress {
  final List<String> delete;
  final List<String> keep;
  GroupProgress({List<String>? delete, List<String>? keep})
      : delete = delete ?? [],
        keep = keep ?? [];

  Map<String, dynamic> toJson() => {'delete': delete, 'keep': keep};
  factory GroupProgress.fromJson(Map<String, dynamic> j) => GroupProgress(
        delete: List<String>.from(j['delete'] ?? []),
        keep: List<String>.from(j['keep'] ?? []),
      );
}

// ── Main app state ────────────────────────────────
class AppState extends ChangeNotifier {
  // ── Flat mode ──
  List<String> images = [];
  int index = 0;
  List<String> toDelete = [];
  List<String> toKeep = [];
  Set<String> toSkip = {};   // foto yang di-skip tapi belum di-decide
  String? currentFolder;
  String lastSortMode = 'name_asc';

  // ── Group mode ──
  bool groupMode = false;
  Map<GroupKey, List<String>> dateGroups = {};
  Map<GroupKey, GroupProgress> groupProgress = {};
  String groupSortMode = 'date_desc';
  GroupKey? currentGroupKey;

  // ── Browser expand state ──
  Set<int> expandedYears = {};
  Set<String> expandedMonths = {}; // "year,month"

  // ── Resume session ──
  Map<String, dynamic>? resumeSession;

  // ── Helpers ──────────────────────────────────────

  static int _weekOfMonth(DateTime dt) {
    final firstDay = DateTime(dt.year, dt.month, 1);
    final adj = dt.day + firstDay.weekday - 1;
    return ((adj - 1) ~/ 7) + 1;
  }

  static List<String> _listImages(String folder) {
    try {
      return Directory(folder)
          .listSync()
          .whereType<File>()
          .where((f) => kImageExtensions.contains(p.extension(f.path).toLowerCase()))
          .map((f) => f.path)
          .toList();
    } catch (_) {
      return [];
    }
  }

  static List<String> _sortImages(List<String> imgs, String mode) {
    final sorted = List<String>.from(imgs);
    switch (mode) {
      case 'name_asc':
        sorted.sort((a, b) => p.basename(a).toLowerCase().compareTo(p.basename(b).toLowerCase()));
        break;
      case 'name_desc':
        sorted.sort((a, b) => p.basename(b).toLowerCase().compareTo(p.basename(a).toLowerCase()));
        break;
      case 'size_asc':
        sorted.sort((a, b) => File(a).lengthSync().compareTo(File(b).lengthSync()));
        break;
      case 'size_desc':
        sorted.sort((a, b) => File(b).lengthSync().compareTo(File(a).lengthSync()));
        break;
      case 'date_desc':
        sorted.sort((a, b) => File(b).lastModifiedSync().compareTo(File(a).lastModifiedSync()));
        break;
      case 'date_asc':
        sorted.sort((a, b) => File(a).lastModifiedSync().compareTo(File(b).lastModifiedSync()));
        break;
    }
    return sorted;
  }

  // ── Flat mode load ────────────────────────────────
  void loadImages(String folder, String sortMode) {
    currentFolder = folder;
    lastSortMode = sortMode;
    final all = _listImages(folder);
    images = _sortImages(all, sortMode);
    index = 0;
    toDelete = [];
    toKeep = [];
    toSkip = {};
    groupMode = false;
    notifyListeners();
  }

  void swipeDelete() {
    if (index >= images.length) return;
    final path = images[index];
    toKeep.remove(path);
    toSkip.remove(path);   // tidak lagi skipped
    if (!toDelete.contains(path)) toDelete.add(path);
    index++;
    notifyListeners();
  }

  void swipeKeep() {
    if (index >= images.length) return;
    final path = images[index];
    toDelete.remove(path);
    toSkip.remove(path);   // tidak lagi skipped
    if (!toKeep.contains(path)) toKeep.add(path);
    index++;
    notifyListeners();
  }

  void undo() {
    if (index <= 0) return;
    index--;
    final path = images[index];
    toDelete.remove(path);
    toKeep.remove(path);
    toSkip.remove(path);
    notifyListeners();
  }

  void skip() {
    if (index >= images.length) return;
    final path = images[index];
    toDelete.remove(path);
    toKeep.remove(path);
    toSkip.add(path);      // track sebagai skipped
    index++;
    notifyListeners();
  }

  // ── Group mode ────────────────────────────────────
  void startGroupMode(String folder, String sortMode) {
    currentFolder = folder;
    groupSortMode = sortMode;
    groupMode = true;
    groupProgress = {};
    dateGroups = _buildDateGroups(folder, sortMode);
    resumeSession = {'_is_group': true, 'folder': folder};
    persistGroupSession();
    notifyListeners();
  }

  Map<GroupKey, List<String>> _buildDateGroups(String folder, String sortMode) {
    final all = _sortImages(_listImages(folder), sortMode);
    final groups = <GroupKey, List<String>>{};
    for (final path in all) {
      try {
        final dt = File(path).lastModifiedSync();
        final wk = _weekOfMonth(dt);
        final key = GroupKey(dt.year, dt.month, wk);
        groups.putIfAbsent(key, () => []).add(path);
      } catch (_) {
        groups.putIfAbsent(const GroupKey(0, 0, 0), () => []).add(path);
      }
    }
    return groups;
  }

  void launchGroupViewer(List<String> paths, GroupKey key) {
    currentGroupKey = key;
    images = List.from(paths);
    toDelete = [];
    toKeep = [];

    // Restore existing progress
    final realKeys = _weekKeysFor(key);
    final pathSet = paths.toSet();
    for (final wk in realKeys) {
      final gp = groupProgress[wk];
      if (gp == null) continue;
      for (final p in gp.delete) {
        if (pathSet.contains(p) && !toDelete.contains(p)) toDelete.add(p);
      }
      for (final p in gp.keep) {
        if (pathSet.contains(p) && !toKeep.contains(p)) toKeep.add(p);
      }
    }

    final decided = {...toDelete, ...toKeep};
    final undecided = images.where((p) => !decided.contains(p)).toList();
    index = undecided.isNotEmpty ? images.indexOf(undecided.first) : 0;
    notifyListeners();
  }

  List<GroupKey> _weekKeysFor(GroupKey key) {
    if (key.week != 0) return [key];
    if (key.month != 0) {
      return dateGroups.keys
          .where((k) => k.year == key.year && k.month == key.month)
          .toList();
    }
    return dateGroups.keys.where((k) => k.year == key.year).toList();
  }

  void saveGroupViewerProgress() {
    if (currentGroupKey == null) return;
    final key = currentGroupKey!;

    if (key.week != 0) {
      groupProgress[key] = GroupProgress(
        delete: List.from(toDelete),
        keep: List.from(toKeep),
      );
      return;
    }

    // Virtual key — distribute per real week key
    final pathToWk = <String, GroupKey>{};
    for (final entry in dateGroups.entries) {
      for (final p in entry.value) {
        pathToWk[p] = entry.key;
      }
    }

    final touchedKeys = <GroupKey>{};
    for (final p in [...toDelete, ...toKeep]) {
      final wk = pathToWk[p];
      if (wk != null) touchedKeys.add(wk);
    }

    final pathSet = images.toSet();
    for (final wk in touchedKeys) {
      final existing = groupProgress[wk] ?? GroupProgress();
      groupProgress[wk] = GroupProgress(
        delete: existing.delete.where((p) => !pathSet.contains(p)).toList(),
        keep: existing.keep.where((p) => !pathSet.contains(p)).toList(),
      );
    }

    for (final p in toDelete) {
      final wk = pathToWk[p];
      if (wk != null) {
        groupProgress.putIfAbsent(wk, () => GroupProgress());
        if (!groupProgress[wk]!.delete.contains(p)) {
          groupProgress[wk]!.delete.add(p);
        }
      }
    }
    for (final p in toKeep) {
      final wk = pathToWk[p];
      if (wk != null) {
        groupProgress.putIfAbsent(wk, () => GroupProgress());
        if (!groupProgress[wk]!.keep.contains(p)) {
          groupProgress[wk]!.keep.add(p);
        }
      }
    }
  }

  void resetGroupKeys(List<GroupKey> keys) {
    for (final k in keys) {
      groupProgress.remove(k);
    }
    persistGroupSession();
    notifyListeners();
  }

  void executeGroup(List<String> paths, List<GroupKey> weekKeys, GroupKey virtualKey) {
    currentGroupKey = virtualKey;
    images = List.from(paths);
    final pathSet = paths.toSet();
    toDelete = [];
    toKeep = [];
    for (final k in weekKeys) {
      final gp = groupProgress[k];
      if (gp == null) continue;
      for (final p in gp.delete) {
        if (pathSet.contains(p) && !toDelete.contains(p)) toDelete.add(p);
      }
      for (final p in gp.keep) {
        if (pathSet.contains(p) && !toKeep.contains(p)) toKeep.add(p);
      }
    }
    notifyListeners();
  }

  // ── Progress helpers ──────────────────────────────
  (int, int) progressFor(List<String> paths) {
    final ps = paths.toSet();
    final allDecided = <String>{};
    for (final gp in groupProgress.values) {
      allDecided.addAll(gp.delete);
      allDecided.addAll(gp.keep);
    }
    return (ps.intersection(allDecided).length, paths.length);
  }

  int get totalAll => dateGroups.values.fold(0, (s, v) => s + v.length);

  int get reviewedAll {
    final all = <String>{};
    for (final gp in groupProgress.values) {
      all.addAll(gp.delete);
      all.addAll(gp.keep);
    }
    return all.length;
  }

  int get deletedAll {
    final all = <String>{};
    for (final gp in groupProgress.values) {
      all.addAll(gp.delete);
    }
    return all.length;
  }

  List<String> get allDeleteList =>
      groupProgress.values.expand((gp) => gp.delete).toSet().toList();

  // ── Year map helper ───────────────────────────────
  Map<int, Map<int, Map<int, List<String>>>> get yearMap {
    final result = <int, Map<int, Map<int, List<String>>>>{};
    for (final entry in dateGroups.entries) {
      final k = entry.key;
      result.putIfAbsent(k.year, () => {}).putIfAbsent(k.month, () => {})[k.week] = entry.value;
    }
    return result;
  }

  List<GroupKey> weekKeysForYear(int yr) {
    final ym = yearMap[yr] ?? {};
    return [
      for (final mo in ym.keys)
        for (final wk in (ym[mo] ?? {}).keys) GroupKey(yr, mo, wk)
    ];
  }

  List<GroupKey> weekKeysForMonth(int yr, int mo) {
    final wkMap = yearMap[yr]?[mo] ?? {};
    return [for (final wk in wkMap.keys) GroupKey(yr, mo, wk)];
  }

  List<String> pathsForYear(int yr) {
    final ym = yearMap[yr] ?? {};
    return [for (final wm in ym.values) for (final paths in wm.values) ...paths];
  }

  List<String> pathsForMonth(int yr, int mo) {
    final wkMap = yearMap[yr]?[mo] ?? {};
    return [for (final paths in wkMap.values) ...paths];
  }

  // ── Toggle expand ─────────────────────────────────
  void toggleYear(int yr) {
    if (expandedYears.contains(yr)) {
      expandedYears.remove(yr);
    } else {
      expandedYears.add(yr);
    }
    notifyListeners();
  }

  void toggleMonth(int yr, int mo) {
    final key = '$yr,$mo';
    if (expandedMonths.contains(key)) {
      expandedMonths.remove(key);
    } else {
      expandedMonths.add(key);
    }
    notifyListeners();
  }

  bool isYearExpanded(int yr) => expandedYears.contains(yr);
  bool isMonthExpanded(int yr, int mo) => expandedMonths.contains('$yr,$mo');

  // ── Clear ─────────────────────────────────────────
  void clearGroupSession() {
    groupMode = false;
    dateGroups = {};
    groupProgress = {};
    currentGroupKey = null;
    expandedYears = {};
    expandedMonths = {};
    notifyListeners();
  }

  void clearResumeSession() {
    resumeSession = null;
    notifyListeners();
    _clearPersistedSession();
  }

  // ── Delete files ──────────────────────────────────
  Future<int> deleteFiles(List<String> paths) async {
    int count = 0;
    for (final path in paths) {
      try {
        final file = File(path);
        if (await file.exists()) {
          // Move to recycle bin via shell on Windows
          await Process.run('powershell', [
            '-Command',
            r"Add-Type -AssemblyName Microsoft.VisualBasic; "
                r"[Microsoft.VisualBasic.FileIO.FileSystem]::DeleteFile("
                "'$path'"
                r", 'OnlyErrorDialogs', 'SendToRecycleBin')"
          ]);
          count++;
        }
      } catch (_) {}
    }
    // Clean up state after deletion
    final deleted = paths.toSet();
    images.removeWhere((p) => deleted.contains(p));
    toDelete.removeWhere((p) => deleted.contains(p));
    toKeep.removeWhere((p) => deleted.contains(p));
    toSkip.removeWhere((p) => deleted.contains(p));
    for (final k in groupProgress.keys) {
      groupProgress[k]!.delete.removeWhere((p) => deleted.contains(p));
      groupProgress[k]!.keep.removeWhere((p) => deleted.contains(p));
    }
    for (final k in dateGroups.keys.toList()) {
      dateGroups[k]!.removeWhere((p) => deleted.contains(p));
      if (dateGroups[k]!.isEmpty) dateGroups.remove(k);
    }
    notifyListeners();
    return count;
  }

  // ── Persistence ───────────────────────────────────
  Future<void> persistGroupSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final gp = <String, dynamic>{};
      for (final entry in groupProgress.entries) {
        gp[entry.key.toJson()] = entry.value.toJson();
      }
      final dg = <String, dynamic>{};
      for (final entry in dateGroups.entries) {
        dg[entry.key.toJson()] = entry.value;
      }
      final data = {
        'mode': 'group',
        'folder': currentFolder,
        'sort_mode': groupSortMode,
        'date_groups': dg,
        'group_progress': gp,
      };
      await prefs.setString(_kSessionKey, jsonEncode(data));
    } catch (_) {}
  }

  Future<void> persistFlatSession({required int resumeIndex}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = {
        'folder': currentFolder,
        'remaining': images,
        'sort_mode': lastSortMode,
        'resume_index': resumeIndex,
        'to_delete': toDelete,
        'to_keep': toKeep,
        'to_skip': toSkip.toList(),
      };
      await prefs.setString(_kSessionKey, jsonEncode(data));
      resumeSession = data;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> loadSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kSessionKey);
      if (raw == null) return;
      final data = jsonDecode(raw) as Map<String, dynamic>;

      if (data['mode'] == 'group') {
        _loadGroupSession(data);
      } else {
        _loadFlatSession(data);
      }
      notifyListeners();
    } catch (_) {}
  }

  void _loadFlatSession(Map<String, dynamic> data) {
    final remaining = List<String>.from(data['remaining'] ?? [])
        .where((p) => File(p).existsSync())
        .toList();
    if (remaining.isEmpty) {
      _clearPersistedSession();
      return;
    }
    resumeSession = {
      'folder': data['folder'],
      'remaining': remaining,
      'sort_mode': data['sort_mode'] ?? 'name_asc',
      'resume_index': data['resume_index'] ?? 0,
      'to_delete': List<String>.from(data['to_delete'] ?? []),
      'to_keep': List<String>.from(data['to_keep'] ?? []),
      'to_skip': List<String>.from(data['to_skip'] ?? []),
    };
  }

  void _loadGroupSession(Map<String, dynamic> data) {
    groupMode = true;
    currentFolder = data['folder'];
    groupSortMode = data['sort_mode'] ?? 'date_desc';

    final dgRaw = data['date_groups'] as Map<String, dynamic>? ?? {};
    final gpRaw = data['group_progress'] as Map<String, dynamic>? ?? {};

    dateGroups = {};
    for (final entry in dgRaw.entries) {
      final k = GroupKey.fromJson(entry.key);
      final paths = List<String>.from(entry.value)
          .where((p) => File(p).existsSync())
          .toList();
      if (paths.isNotEmpty) dateGroups[k] = paths;
    }

    final allExisting = dateGroups.values.expand((v) => v).toSet();
    groupProgress = {};
    for (final entry in gpRaw.entries) {
      final k = GroupKey.fromJson(entry.key);
      final v = entry.value as Map<String, dynamic>;
      groupProgress[k] = GroupProgress(
        delete: List<String>.from(v['delete'] ?? [])
            .where(allExisting.contains)
            .toList(),
        keep: List<String>.from(v['keep'] ?? [])
            .where(allExisting.contains)
            .toList(),
      );
    }

    if (dateGroups.isEmpty) {
      groupMode = false;
      _clearPersistedSession();
      return;
    }

    resumeSession = {'_is_group': true, 'folder': currentFolder};
  }

  void resumeFlat() {
    if (resumeSession == null || resumeSession!['_is_group'] == true) return;
    final s = resumeSession!;
    currentFolder = s['folder'];
    lastSortMode = s['sort_mode'] ?? 'name_asc';
    images = List<String>.from(s['remaining'] ?? [])
        .where((p) => File(p).existsSync())
        .toList();
    final existing = images.toSet();
    toDelete = List<String>.from(s['to_delete'] ?? [])
        .where(existing.contains)
        .toList();
    toKeep = List<String>.from(s['to_keep'] ?? [])
        .where(existing.contains)
        .toList();
    toSkip = List<String>.from(s['to_skip'] ?? [])
        .where(existing.contains)
        .toSet();
    index = s['resume_index'] ?? 0;
    if (index >= images.length) index = images.length - 1;
    groupMode = false;
    notifyListeners();
  }

  Future<void> _clearPersistedSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kSessionKey);
    } catch (_) {}
  }

  // ── Format helpers ────────────────────────────────
  static String formatSize(int bytes) {
    final kb = bytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
    final mb = kb / 1024;
    if (mb < 1024) return '${mb.toStringAsFixed(1)} MB';
    return '${(mb / 1024).toStringAsFixed(2)} GB';
  }

  static String monthName(int m) =>
      ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
       'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][m];
}
