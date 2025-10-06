// task_calendar_screen.dart

import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart'; // Aunque ya está en main, la mantienes si vas a usar Intl aquí.

class TaskCalendarScreen extends StatefulWidget {
  final int userId;
  const TaskCalendarScreen({super.key, required this.userId});

  @override
  State<TaskCalendarScreen> createState() => _TaskCalendarScreenState();
}

class _TaskCalendarScreenState extends State<TaskCalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  // Usamos DateTime.now() en el local time zone.
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // Mapa de tareas por fecha. Si tus fechas en DB son UTC, considera usar DateTime.utc aquí.
  Map<DateTime, List<String>> _events = {
    // Nota: El mapa debe contener fechas solo con año, mes y día, sin hora.
    DateTime.utc(2025, 10, 5): ['Revisar Facturas', 'Cita con cliente'],
    DateTime.utc(2025, 10, 10): ['Junta de equipo FINORA'],
    DateTime.utc(2025, 10, 15): ['Pagar impuestos trimestrales'],
    DateTime.utc(2025, 10, 30): ['Preparar cierre de mes'],
  };

  List<String> _getEventsForDay(DateTime day) {
    // Aseguramos que la clave de búsqueda sea solo Año-Mes-Día
    return _events[DateTime.utc(day.year, day.month, day.day)] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    // Establece el día seleccionado al día actual si es nulo
    _selectedDay ??= _focusedDay;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Calendario de Tareas 🗓️", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFE8F6FA),
        iconTheme: const IconThemeData(color: Color(0xFF1ABC9C)),
        elevation: 0,
      ),
      body: Column(
        children: [
          TableCalendar(
            // 🔑 El locale 'es_ES' ahora funciona gracias a los cambios en main.dart
            locale: 'es_ES', 
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) {
              return isSameDay(_selectedDay, day);
            },
            onDaySelected: (selectedDay, focusedDay) {
              if (!isSameDay(_selectedDay, selectedDay)) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              }
            },
            onFormatChanged: (format) {
              if (_calendarFormat != format) {
                setState(() {
                  _calendarFormat = format;
                });
              }
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
            eventLoader: _getEventsForDay,
            headerStyle: HeaderStyle(
              formatButtonVisible: true,
              titleCentered: true,
              formatButtonShowsNext: false,
              formatButtonDecoration: BoxDecoration(
                color: const Color(0xFF1ABC9C),
                borderRadius: BorderRadius.circular(10.0),
              ),
              formatButtonTextStyle: const TextStyle(color: Colors.white),
            ),
            calendarStyle: const CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Color(0x661ABC9C), 
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Color(0xFF1ABC9C), 
                shape: BoxShape.circle,
              ),
              markerDecoration: BoxDecoration(
                color: Colors.red, 
                shape: BoxShape.circle,
              ),
            ),
          ),
          const Divider(),
          // 🔑 SOLUCIÓN AL RenderFlex overflow: El ListView está dentro de un Expanded
          Expanded( 
            child: ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    // Usamos DateFormat para un mejor formato de la fecha
                    "Tareas para: ${DateFormat('EEEE, d MMMM', 'es').format(_selectedDay ?? _focusedDay)}",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                ..._getEventsForDay(_selectedDay ?? _focusedDay).map((event) => ListTile(
                      title: Text(event),
                      leading: const Icon(Icons.task, color: Color(0xFF1ABC9C)),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Tarea seleccionada: $event')));
                      },
                    )),
                if (_getEventsForDay(_selectedDay ?? _focusedDay).isEmpty)
                  const Center(child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Text("No hay tareas pendientes para este día."),
                  )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}