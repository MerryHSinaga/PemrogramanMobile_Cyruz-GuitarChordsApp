import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';

class ScheduleScreen extends StatefulWidget {
  final String userId;
  const ScheduleScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final TextEditingController _eventNameController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  TimeOfDay? _selectedTime;
  String _selectedZone = 'WIB';
  bool _isAdding = false;
  String _selectedTab = "upcoming";

  List<Map<String, dynamic>> _reminders = [];

  static const Map<String, int> _zoneOffsets = {
    'WIB': 7,
    'WITA': 8,
    'WIT': 9,
    'London': 0,
  };

  @override
  void initState() {
    super.initState();
    NotificationService.init();
    NotificationService.requestPermissionIfNeeded();
    _loadReminders();
  }

  @override
  void dispose() {
    _eventNameController.dispose();
    super.dispose();
  }

  Future<void> _loadReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'reminders_${widget.userId}';
    final data = prefs.getString(key);

    if (data != null) {
      try {
        final decoded = jsonDecode(data) as List;
        _reminders = decoded.map<Map<String, dynamic>>((e) {
          final m = Map<String, dynamic>.from(e);
          return {
            'id': m['id'],
            'name': m['name'],
            'datetime': m['datetime'],
            'zone': m['zone'],
            'converted': Map<String, String>.from(m['converted']),
          };
        }).toList();
      } catch (_) {
        _reminders = [];
      }
    }
    setState(() {});
  }

  Future<void> _saveReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'reminders_${widget.userId}';
    await prefs.setString(key, jsonEncode(_reminders));
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      builder: (context, child) => Theme(
        data: ThemeData.dark(),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked == null) return;

    final now = DateTime.now();
    final selectedDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      picked.hour,
      picked.minute,
    );

    final minAllowed = now.add(const Duration(minutes: 2));
    if (selectedDateTime.isBefore(minAllowed)) {
      _showTimeErrorPopup();
      return;
    }

    setState(() => _selectedTime = picked);
  }

  void _showTimeErrorPopup() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Waktu Tidak Valid"),
        content: const Text("Jam yang dipilih harus 2 menit di atas sekarang."),
        actions: [
          TextButton(
            child: const Text("OK"),
            onPressed: () => Navigator.of(context).pop(),
          )
        ],
      ),
    );
  }

  Map<String, String> _convertAllZones(DateTime base, String baseZone) {
    final baseOffset = _zoneOffsets[baseZone]!;
    final result = <String, String>{};

    _zoneOffsets.forEach((zone, offset) {
      final diff = offset - baseOffset;
      final converted = base.add(Duration(hours: diff));
      result[zone] =
          '${converted.hour.toString().padLeft(2, '0')}:${converted.minute.toString().padLeft(2, '0')}';
    });

    return result;
  }

  Future<void> _addSchedule() async {
    if (_isAdding) return;

    if (_eventNameController.text.isEmpty || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Lengkapi nama & waktu"),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(top: 16, left: 16, right: 16),
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    final now = DateTime.now();
    final picked = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    final minAllowed = now.add(const Duration(minutes: 2));
    if (picked.isBefore(minAllowed)) {
      _showTimeErrorPopup();
      return;
    }

    setState(() => _isAdding = true);

    final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    _reminders.add({
      'id': id.toString(),
      'name': _eventNameController.text,
      'datetime': picked.toIso8601String(),
      'zone': _selectedZone,
      'converted': _convertAllZones(picked, _selectedZone),
    });

    await _saveReminders();

    NotificationService.showInstant(
      id: id + 10,
      title: 'Cyruz',
      body: '“${_eventNameController.text}” berhasil disimpan.',
    );

    _eventNameController.clear();
    _selectedTime = null;

    setState(() => _isAdding = false);

    if (Navigator.canPop(context)) Navigator.pop(context);

    Future.delayed(const Duration(milliseconds: 200), () {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Schedule berhasil ditambahkan"),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(top: 16, left: 16, right: 16),
          duration: const Duration(seconds: 3),
        ),
      );
    });
  }

  Future<void> _deleteSchedule(String id) async {
    _reminders.removeWhere((r) => r['id'] == id);
    await _saveReminders();
    setState(() {});
  }

  Widget _styledTab(String label, bool active, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: active ? const Color(0xFF1A2B5B) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF1A2B5B)),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: active ? Colors.white : const Color(0xFF1A2B5B),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScheduleCard(Map<String, dynamic> r) {
    final dt = DateTime.parse(r['datetime']);
    final isDone = DateTime.now().isAfter(dt);
    final zone = r['zone'];
    final converted = Map<String, String>.from(r['converted']);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFBFC6D0).withOpacity(0.10),
            const Color.fromARGB(255, 103, 139, 232),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.black12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 8,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 14),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '${r['name']} ${isDone ? "" : ""}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Color(0xFF1A2B5B),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete,
                      color: Color.fromARGB(255, 125, 0, 0)),
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text("Hapus Schedule"),
                        content: const Text(
                            "Apakah Anda yakin ingin menghapus schedule ini?"),
                        actions: [
                          TextButton(
                              onPressed: () =>
                                  Navigator.of(context).pop(false),
                              child: const Text("Batal")),
                          TextButton(
                              onPressed: () =>
                                  Navigator.of(context).pop(true),
                              child: const Text("Hapus")),
                        ],
                      ),
                    );
                    if (confirmed == true) _deleteSchedule(r['id']);
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Date: ${dt.day}/${dt.month}/${dt.year}',
                  style: const TextStyle(fontSize: 15, color: Colors.black87),
                ),
                const SizedBox(height: 10),
                ...converted.entries.map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      'Time in ${e.key}: ${e.value}',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: e.key == zone
                            ? FontWeight.normal
                            : FontWeight.normal,
                        color: e.key == zone
                            ? const Color(0xFF1A2B5B)
                            : Colors.black54,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  void _openAddBottomSheet() {
    final TextStyle inputFont =
        const TextStyle(fontSize: 15, color: Colors.black87);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom, top: 20),
            child: ListView(
              padding: const EdgeInsets.all(20),
              shrinkWrap: true,
              children: [
                const Text(
                  "Add New Schedule",
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A2B5B),
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: _eventNameController,
                  style: inputFont,
                  decoration: InputDecoration(
                    prefixIcon:
                        const Icon(Icons.edit_note, color: Color(0xFF123458)),
                    labelText: 'Schedule Name',
                    labelStyle: inputFont,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 12),
                  ),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () async {
                    await _pickDate();
                    setModalState(() {});
                  },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      border:
                          Border.all(color: const Color(0xFF123458)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today,
                            color: Color(0xFF123458)),
                        const SizedBox(width: 10),
                        Text(
                          'Date: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                          style: inputFont,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () async {
                    await _pickTime();
                    setModalState(() {});
                  },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      border:
                          Border.all(color: const Color(0xFF123458)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.access_time,
                            color: Color(0xFF123458)),
                        const SizedBox(width: 10),
                        Text(
                          _selectedTime == null
                              ? "Pick Time"
                              : "Time: ${_selectedTime!.format(context)}",
                          style: inputFont,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedZone,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon:
                        const Icon(Icons.public, color: Color(0xFF123458)),
                    labelText: "Time Zone",
                    labelStyle: inputFont,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: Color(0xFF123458)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: Color(0xFF123458), width: 2),
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                  ),
                  style: inputFont.copyWith(color: const Color(0xFF123458)),
                  dropdownColor: Colors.white,
                  items: _zoneOffsets.keys
                      .map((z) => DropdownMenuItem(
                            value: z,
                            child: Text(
                              z,
                              style: inputFont.copyWith(
                                  color: const Color(0xFF123458)),
                            ),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() => _selectedZone = v);
                    setModalState(() {});
                  },
                ),
                const SizedBox(height: 25),
                ElevatedButton(
                  onPressed: _addSchedule,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF123458),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    _isAdding ? "Saving..." : "Save",
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    final upcoming = _reminders
        .where((r) => DateTime.parse(r['datetime']).isAfter(now))
        .toList();

    final done = _reminders
        .where((r) => DateTime.parse(r['datetime']).isBefore(now))
        .toList();

    upcoming.sort((a, b) =>
        DateTime.parse(a['datetime']).compareTo(DateTime.parse(b['datetime'])));
    done.sort((a, b) =>
        DateTime.parse(a['datetime']).compareTo(DateTime.parse(b['datetime'])));

    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF123458),
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: _openAddBottomSheet,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            const Center(
              child: Text(
                "Let's keep your rhythm on track!",
                style: TextStyle(
                  fontSize: 17,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF123458),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _styledTab(
                      "Upcoming",
                      _selectedTab == "upcoming",
                      () => setState(() => _selectedTab = "upcoming")),
                  const SizedBox(width: 10),
                  _styledTab(
                      "Done",
                      _selectedTab == "done",
                      () => setState(() => _selectedTab = "done")),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _selectedTab == "upcoming"
                    ? (upcoming.isEmpty
                        ? const Center(child: Text("No upcoming schedule"))
                        : ListView(
                            children:
                                upcoming.map(_buildScheduleCard).toList(),
                          ))
                    : (done.isEmpty
                        ? const Center(child: Text("No done schedule"))
                        : ListView(
                            children: done.map(_buildScheduleCard).toList(),
                          )),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
