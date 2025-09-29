import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DateSelectionWidget extends StatelessWidget {
  final DateTime? startDate;
  final DateTime? endDate;
  final VoidCallback onSelectDates;
  final VoidCallback onClearDates;

  const DateSelectionWidget({
    super.key,
    required this.startDate,
    required this.endDate,
    required this.onSelectDates,
    required this.onClearDates,
  });

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat.yMMMd();

    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text(
            "Rental Dates",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            (startDate != null && endDate != null)
                ? "${dateFmt.format(startDate!)} → ${dateFmt.format(endDate!)}"
                : "Select rental start & end date",
            style: const TextStyle(fontSize: 14),
          ),
          trailing: ElevatedButton(
            onPressed: onSelectDates,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text("Pick Dates"),
          ),
        ),
        if (startDate != null || endDate != null)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onClearDates,
              child: const Text(
                "Clear selection",
                style: TextStyle(color: Colors.red),
              ),
            ),
          ),
      ],
    );
  }
}