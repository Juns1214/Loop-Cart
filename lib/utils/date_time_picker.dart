import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';
import 'package:intl/intl.dart';

class SyncfusionDateTimePicker extends StatefulWidget {
  final Function(DateTime, TimeOfDay) onDateTimeSelected;

  const SyncfusionDateTimePicker({
    super.key,
    required this.onDateTimeSelected,
  });

  @override
  State<SyncfusionDateTimePicker> createState() => _SyncfusionDateTimePickerState();
}

class _SyncfusionDateTimePickerState extends State<SyncfusionDateTimePicker> {
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = const TimeOfDay(hour: 14, minute: 0);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader("Pick a Date"),
          const SizedBox(height: 12),
          SfDateRangePicker(
            selectionMode: DateRangePickerSelectionMode.single,
            minDate: DateTime.now(),
            onSelectionChanged: (args) {
              if (args.value is DateTime) {
                setState(() => selectedDate = args.value);
                widget.onDateTimeSelected(selectedDate, selectedTime);
              }
            },
            headerStyle: const DateRangePickerHeaderStyle(
              textStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
            ),
            selectionColor: const Color(0xFF2E5BFF),
            todayHighlightColor: const Color(0xFF2E5BFF),
            monthCellStyle: const DateRangePickerMonthCellStyle(
              textStyle: TextStyle(color: Colors.black87),
              todayTextStyle: TextStyle(color: Color(0xFF2E5BFF), fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 24),
          _buildHeader("Pick a Time"),
          const SizedBox(height: 12),
          _buildTimeSelector(),
          const SizedBox(height: 24),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
              child: Text(
                "Selected: ${DateFormat('dd MMM, yyyy').format(selectedDate)} at ${selectedTime.format(context)}",
                style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(String title) {
    return Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A)));
  }

  Widget _buildTimeSelector() {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 24,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final time = TimeOfDay(hour: index, minute: 0);
          final isSelected = time.hour == selectedTime.hour;

          return InkWell(
            onTap: () {
              setState(() => selectedTime = time);
              widget.onDateTimeSelected(selectedDate, selectedTime);
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF2E5BFF) : Colors.white,
                border: Border.all(color: isSelected ? const Color(0xFF2E5BFF) : Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text(
                time.format(context),
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}