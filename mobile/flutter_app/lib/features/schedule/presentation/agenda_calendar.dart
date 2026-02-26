import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class AgendaCalendar extends StatefulWidget {
  const AgendaCalendar({
    super.key,
    required this.selectedDate,
    required this.eventDates,
    required this.onDateSelected,
  });

  final DateTime selectedDate;
  final Set<DateTime> eventDates;
  final ValueChanged<DateTime> onDateSelected;

  @override
  State<AgendaCalendar> createState() => _AgendaCalendarState();
}

class _AgendaCalendarState extends State<AgendaCalendar> {
  late DateTime _focusedDay;

  @override
  void initState() {
    super.initState();
    _focusedDay = _normalize(widget.selectedDate);
  }

  @override
  void didUpdateWidget(covariant AgendaCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isSameDay(oldWidget.selectedDate, widget.selectedDate)) {
      _focusedDay = _normalize(widget.selectedDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();

    return TableCalendar<Object>(
      locale: locale,
      firstDay: DateTime.utc(2000, 1, 1),
      lastDay: DateTime.utc(2100, 12, 31),
      focusedDay: _focusedDay,
      selectedDayPredicate: (day) => _isSameDay(day, widget.selectedDate),
      onDaySelected: (selectedDay, focusedDay) {
        setState(() => _focusedDay = focusedDay);
        widget.onDateSelected(_normalize(selectedDay));
      },
      onPageChanged: (focusedDay) {
        setState(() => _focusedDay = focusedDay);
      },
      headerStyle: const HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
      ),
      availableCalendarFormats: const {
        CalendarFormat.month: 'Month',
      },
      calendarFormat: CalendarFormat.month,
      eventLoader: (day) {
        final normalized = _normalize(day);
        if (widget.eventDates.contains(normalized)) {
          return const [true];
        }
        return const [];
      },
      calendarBuilders: CalendarBuilders(
        markerBuilder: (context, day, events) {
          if (events.isEmpty) return const SizedBox.shrink();
          return Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.only(bottom: 4),
              decoration: const BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
            ),
          );
        },
      ),
    );
  }

  DateTime _normalize(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  bool _isSameDay(DateTime left, DateTime right) {
    return left.year == right.year &&
        left.month == right.month &&
        left.day == right.day;
  }
}
