import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DateTimePicker extends StatefulWidget {
  final Function(DateTime, TimeOfDay) onDateTimeSelected;
  final DateTime? initialDate;
  final TimeOfDay? initialTime;

  const DateTimePicker({
    super.key,
    required this.onDateTimeSelected,
    this.initialDate,
    this.initialTime,
  });

  @override
  State<DateTimePicker> createState() => _DateTimePickerState();
}

class _DateTimePickerState extends State<DateTimePicker> {
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  static const Color _primaryGreen = Color(0xFF2E7D32);

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? DateTime.now();
    _selectedTime = widget.initialTime ?? const TimeOfDay(hour: 14, minute: 0);
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: _primaryGreen, onPrimary: Colors.white, onSurface: Color(0xFF212121)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && mounted) {
      setState(() => _selectedDate = picked);
      widget.onDateTimeSelected(_selectedDate, _selectedTime);
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: _primaryGreen, onPrimary: Colors.white, onSurface: Color(0xFF212121)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && mounted) {
      setState(() => _selectedTime = picked);
      widget.onDateTimeSelected(_selectedDate, _selectedTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 1.5),
      ),
      child: Column(
        children: [
          _buildDateTimeRow('Date', DateFormat('MMM dd, yyyy').format(_selectedDate), Icons.calendar_today, _selectDate),
          const Divider(height: 24),
          _buildDateTimeRow('Time', _selectedTime.format(context), Icons.access_time, _selectTime),
        ],
      ),
    );
  }

  Widget _buildDateTimeRow(String label, String value, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: _primaryGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: _primaryGreen, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontFamily: 'Roboto', fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF424242))),
                  const SizedBox(height: 2),
                  Text(value, style: const TextStyle(fontFamily: 'Roboto', fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF212121))),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF9E9E9E)),
          ],
        ),
      ),
    );
  }
}