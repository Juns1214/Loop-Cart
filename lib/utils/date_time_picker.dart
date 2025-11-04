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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Pick a Date",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          SfDateRangePicker(
            selectionMode: DateRangePickerSelectionMode.single,
            minDate: DateTime.now(),
            onSelectionChanged: (DateRangePickerSelectionChangedArgs args) {
              setState(() {
                selectedDate = args.value;
              });
              widget.onDateTimeSelected(selectedDate, selectedTime);
            },
            monthViewSettings: const DateRangePickerMonthViewSettings(
              firstDayOfWeek: 7,
            ),
            monthCellStyle: const DateRangePickerMonthCellStyle(
              textStyle: TextStyle(color: Colors.black),
              todayTextStyle: TextStyle(color: Colors.blue),
            ),
            selectionColor: const Color(0xFF2E5BFF),
            todayHighlightColor: Colors.blueAccent,
            backgroundColor: Colors.white,
            headerStyle: const DateRangePickerHeaderStyle(
              textAlign: TextAlign.center,
              textStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "Pick a Time",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          _buildTimeRow(context),
          const SizedBox(height: 10),
          Center(
            child: Text(
              "Selected: ${DateFormat('dd MMM, yyyy').format(selectedDate)} at ${selectedTime.format(context)}",
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeRow(BuildContext context) {
    List<TimeOfDay> timeSlots = List.generate(
      24,
      (index) => TimeOfDay(hour: index, minute: 0),
    );

    return SizedBox(
      height: 45,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: timeSlots.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final time = timeSlots[index];
          final isSelected =
              time.hour == selectedTime.hour && time.minute == selectedTime.minute;

          return GestureDetector(
            onTap: () {
              setState(() {
                selectedTime = time;
              });
              widget.onDateTimeSelected(selectedDate, selectedTime);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF2E5BFF) : Colors.white,
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  time.format(context),
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey[700],
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
