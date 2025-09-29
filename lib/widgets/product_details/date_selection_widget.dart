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
          title: const Text("Rental Dates"),
          subtitle: Text(
            (startDate != null && endDate != null)
                ? "${dateFmt.format(startDate!)} → ${dateFmt.format(endDate!)}"
                : "Select rental start & end date",
          ),
          trailing: ElevatedButton(
            onPressed: onSelectDates,
            child: const Text("Pick Dates"),
          ),
        ),
        if (startDate != null || endDate != null)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onClearDates,
              child: const Text("Clear selection"),
            ),
          ),
      ],
    );
  }
}