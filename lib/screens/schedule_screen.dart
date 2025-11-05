import 'dart:convert';
import 'dart:ui';
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
  String _baseZone = 'WIB';
  List<Map<String, dynamic>> _reminders = [];
  bool _isAdding = false;

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
            'id': m['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
            'name': m['name'] ?? 'Untitled',
            'datetime': m['datetime'] ?? DateTime.now().toIso8601String(),
            'zone': m['zone'] ?? 'WIB',
            'converted': Map<String, String>.from(m['converted'] ?? {}),
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
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: Colors.purple),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedTime = picked);
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
        const SnackBar(content: Text('Lengkapi nama kegiatan dan waktu!')),
      );
      return;
    }

    setState(() => _isAdding = true);

    try {
      final dt = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      if (dt.isBefore(DateTime.now())) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Waktu yang diinput harus di atas sekarang!')),
        );
        setState(() => _isAdding = false);
        return;
      }

      final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final converted = _convertAllZones(dt, _baseZone);
      final name = _eventNameController.text;
      final zone = _baseZone;

      final reminder = {
        'id': id.toString(),
        'name': name,
        'datetime': dt.toIso8601String(),
        'zone': zone,
        'converted': converted,
      };

      _reminders.add(reminder);
      await _saveReminders();

      final formattedDate =
          '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}';
      final formattedTime = _selectedTime!.format(context);

      NotificationService.showInstant(
        id: id + 10,
        title: 'Cyruz',
        body:
            'Jadwal berhasil disimpan. Jangan lupa "$name" pada $formattedDate pukul $formattedTime. Cyruz siap menemanimu!',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jadwal berhasil disimpan.')),
      );
    } finally {
      setState(() {
        _isAdding = false;
        _eventNameController.clear();
        _selectedTime = null;
      });
    }
  }

  Future<void> _deleteSchedule(int index) async {
    setState(() => _reminders.removeAt(index));
    await _saveReminders();
  }

  Widget _buildDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _baseZone,
          dropdownColor: Colors.grey[900],
          items: _zoneOffsets.keys
              .map((z) => DropdownMenuItem<String>(
                    value: z,
                    child: Text(z, style: const TextStyle(color: Colors.white)),
                  ))
              .toList(),
          onChanged: (v) => setState(() => _baseZone = v!),
        ),
      ),
    );
  }

  Widget _buildScheduleCard(Map<String, dynamic> r) {
    final dt = DateTime.parse(r['datetime']);
    final converted = Map<String, String>.from(r['converted']);
    final sortedConverted = Map<String, String>.fromEntries([
      ...converted.entries.where((e) => e.key == _baseZone),
      ...converted.entries.where((e) => e.key != _baseZone),
    ]);
    final isDone = DateTime.now().isAfter(dt);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${r['name']}${isDone ? " (Selesai)" : ""}',
            style: const TextStyle(
              color: Color.fromARGB(255, 164, 55, 189),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text('Date: ${dt.day}/${dt.month}/${dt.year}',
              style: const TextStyle(color: Colors.white70, fontSize: 16)),
          const Divider(color: Colors.white24),
          ...sortedConverted.entries.map((e) => Text(
              'Time in ${e.key}: ${e.value}',
              style: TextStyle(
                color: e.key == _baseZone ? Colors.purpleAccent : Colors.white54,
                fontSize: 16,
                fontWeight:
                    e.key == _baseZone ? FontWeight.bold : FontWeight.normal,
              ))),
          Align(
            alignment: Alignment.topRight,
            child: IconButton(
              icon: const Icon(Icons.delete, color: Colors.purpleAccent),
              onPressed: () => _deleteSchedule(_reminders.indexOf(r)),
            ),
          ),
        ],
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

    final sortedReminders = [...upcoming, ...done];

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/background.png', fit: BoxFit.cover),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
            child: Container(color: Colors.black.withOpacity(0.3)),
          ),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text(
                  "Let’s keep your rhythm on track here!",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w500,
                    shadows: [
                      Shadow(
                        color: Colors.purpleAccent,
                        blurRadius: 10,
                        offset: Offset(0, 0),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 25),
                TextField(
                  controller: _eventNameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white10,
                    hintText: 'Schedule name',
                    hintStyle: const TextStyle(color: Colors.white54),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: _pickDate,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today,
                            color: Colors.purpleAccent),
                        const SizedBox(width: 12),
                        Text(
                          'Date: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: _pickTime,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      children: [
                        const Icon(Icons.access_time,
                            color: Colors.purpleAccent),
                        const SizedBox(width: 12),
                        Text(
                          _selectedTime == null
                              ? 'Pick Time'
                              : 'Time: ${_selectedTime!.format(context)}',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildDropdown(),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _isAdding ? null : _addSchedule,
                  icon: _isAdding
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.add_alert, color: Colors.white),
                  label: Text(
                    _isAdding ? 'Adding...' : 'Add',
                    style: const TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 24),
                if (sortedReminders.isNotEmpty)
                  for (final r in sortedReminders) _buildScheduleCard(r)
                else
                  const Center(
                      child: Text('No schedules yet.',
                          style: TextStyle(color: Colors.white54))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
