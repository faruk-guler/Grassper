import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../providers/note_provider.dart';
import '../models/note_model.dart';
import '../core/constants.dart';
import '../core/strings.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<NoteProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.calendarView, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: theme.textTheme.bodyLarge?.color,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: TableCalendar(
                  locale: 'tr_TR',
                  firstDay: DateTime.utc(2000, 1, 1),
                  lastDay: DateTime.utc(2100, 12, 31),
                   focusedDay: _focusedDay,
                  startingDayOfWeek: provider.startingDayOfWeek,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                  },
                  eventLoader: (day) {
                    final d = DateTime(day.year, day.month, day.day);
                    return provider.notes
                        .where((n) => !n.isArchived)
                        .where((n) {
                          final noteDate = DateTime.fromMillisecondsSinceEpoch(n.createdAt);
                          return isSameDay(noteDate, d);
                        })
                        .toList();
                  },
                  calendarStyle: CalendarStyle(
                    todayDecoration: BoxDecoration(
                      color: Colors.transparent,
                      shape: BoxShape.rectangle,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.danger, width: 2),
                    ),
                    todayTextStyle: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold),
                    selectedDecoration: BoxDecoration(
                      color: Colors.transparent,
                      shape: BoxShape.rectangle,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: theme.primaryColor, width: 2),
                    ),
                    selectedTextStyle: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold),
                    defaultDecoration: const BoxDecoration(shape: BoxShape.rectangle),
                    weekendDecoration: const BoxDecoration(shape: BoxShape.rectangle),
                    holidayDecoration: const BoxDecoration(shape: BoxShape.rectangle),
                  ),
                  calendarBuilders: CalendarBuilders(
                    markerBuilder: (context, date, events) {
                      if (events.isNotEmpty) {
                        return Positioned(
                          bottom: 4,
                          child: Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: theme.primaryColor.withOpacity(0.5),
                              shape: BoxShape.circle,
                            ),
                          ),
                        );
                      }
                      return null;
                    },
                    todayBuilder: (context, day, focusedDay) {
                      return Center(
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.danger, width: 2),
                          ),
                          child: Center(
                            child: Text(
                              day.day.toString(),
                              style: const TextStyle(
                                color: AppColors.danger,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                    selectedBuilder: (context, day, focusedDay) {
                      final isToday = isSameDay(day, DateTime.now());
                      final frameColor = isToday ? AppColors.danger : theme.primaryColor;
                      return Center(
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: frameColor, width: 2),
                          ),
                          child: Center(
                            child: Text(
                              day.day.toString(),
                              style: TextStyle(
                                color: frameColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  headerStyle: const HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // Notes List for Selected Day
              Expanded(
                child: _selectedDay == null
                    ? const Center(child: Icon(Icons.calendar_today_outlined, size: 48, color: Colors.grey))
                    : Consumer<NoteProvider>(
                        builder: (context, provider, child) {
                          final selectedNotes = provider.notes
                              .where((n) => !n.isArchived)
                              .where((n) {
                                final noteDate = DateTime.fromMillisecondsSinceEpoch(n.createdAt);
                                return isSameDay(noteDate, _selectedDay!);
                              })
                              .toList();

                          if (selectedNotes.isEmpty) {
                            return Center(
                              child: Text(
                                AppStrings.noContent,
                                style: TextStyle(color: theme.iconTheme.color),
                              ),
                            );
                          }

                          return ListView.builder(
                            itemCount: selectedNotes.length,
                            itemBuilder: (context, index) {
                              final note = selectedNotes[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                color: theme.cardColor,
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  title: Text(
                                    note.title.isEmpty ? AppStrings.untitledNote : note.title,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text(
                                    note.content,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  trailing: note.isPinned 
                                      ? Icon(Icons.push_pin, size: 20, color: note.isImportant ? AppColors.danger : theme.primaryColor)
                                      : null,
                                  onTap: () {
                                    // Navigate to editor if needed, or just view
                                  },
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
