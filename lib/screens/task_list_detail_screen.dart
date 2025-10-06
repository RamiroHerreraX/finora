import 'package:flutter/material.dart';
import '../db/database_helper.dart'; // Asegúrate de que esta ruta sea correcta
// Puedes reutilizar TaskScreen para el modal o crear una nueva
// import 'task_screen.dart'; 

// 1. Cambiamos a StatefulWidget para poder actualizar la lista
class TaskListDetailScreen extends StatefulWidget {
  final int userId;
  final String category;
  final List<Map<String, dynamic>> allTasks; // Tareas completas para filtrar

  const TaskListDetailScreen({
    super.key,
    required this.userId,
    required this.category,
    required this.allTasks,
  });

  @override
  State<TaskListDetailScreen> createState() => _TaskListDetailScreenState();
}

class _TaskListDetailScreenState extends State<TaskListDetailScreen> {
  // 2. Usamos una lista de estado para almacenar y filtrar las tareas
  List<Map<String, dynamic>> _filteredTasks = [];

  @override
  void initState() {
    super.initState();
    _loadFilteredTasks();
  }

  // --- 3. Funciones de Carga y Filtrado ---
  void _loadFilteredTasks() {
    setState(() {
      _filteredTasks = _filterTasks(widget.category, widget.allTasks);
    });
  }

  List<Map<String, dynamic>> _filterTasks(String category, List<Map<String, dynamic>> allTasks) {
    // ⚠️ Nota: Esta lógica de filtrado es simple. En un entorno real,
    // es mejor que la DB filtre por ti.

    // Primero, asumimos que necesitas la columna 'is_completed' en tu DB.
    final incompleteTasks = allTasks.where((t) => t['is_completed'] == 0).toList();
    final completedTasks = allTasks.where((t) => t['is_completed'] == 1).toList();

    switch (category) {
      case "Todas":
        // Mostramos incompletas primero, luego completadas.
        return [...incompleteTasks, ...completedTasks];
      case "Hoy":
        final today = DateTime.now().toString().split(' ')[0];
        // Filtramos solo las de hoy que están incompletas
        return incompleteTasks.where((t) => t['date'] == today).toList();
      case "Terminados":
        return completedTasks; 
      case "Calendario":
        return incompleteTasks.where((t) => t['date'] != null && t['date'].isNotEmpty).toList();
      default:
        // Lógica para listas de usuario
        return [];
    }
  }
  
  // --- 4. Marcar como Completada/Incompleta ---
  Future<void> _toggleTaskStatus(int taskId, int currentStatus) async {
    // Si estaba 0 (incompleta), pasa a 1 (completa)
    final newStatus = currentStatus == 0 ? 1 : 0; 
    
    // Asumiendo que DatabaseHelper tiene este método.
    await DatabaseHelper.instance.updateTaskStatus(taskId, newStatus);
    
    // Recargar todas las tareas desde la DB (para reflejar el cambio en la pantalla TaskScreen)
    // y luego recargar la vista detallada.
    _reloadTaskData();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(newStatus == 1 ? "Tarea marcada como completada! ✅" : "Tarea marcada como pendiente.")),
      );
    }
  }

  // Función auxiliar para recargar datos de TaskScreen y TaskListDetailScreen
  void _reloadTaskData() {
    // Para recargar los datos en TaskScreen, puedes usar Navigator.pop
    // y luego en TaskScreen llamar a _loadTasks(). 
    // Por ahora, solo cargamos la lista filtrada:
    // **Nota:** Para una recarga completa, necesitarías refrescar TaskScreen.
    _loadFilteredTasks();
  }

  // --- 5. Modal de Edición de Tarea ---
  void _showEditTaskModal(Map<String, dynamic> task) {
    final titleController = TextEditingController(text: task['title']);
    final descriptionController = TextEditingController(text: task['description']);
    final dateController = TextEditingController(text: task['date']);
    final taskId = task['id'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20, 
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Text("Editar Tarea ✏️", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              const SizedBox(height: 20),
              TextField(controller: titleController, decoration: const InputDecoration(labelText: "Título de la tarea*", border: OutlineInputBorder(), prefixIcon: Icon(Icons.title))),
              const SizedBox(height: 15),
              TextField(controller: descriptionController, maxLines: 3, decoration: const InputDecoration(labelText: "Descripción", border: OutlineInputBorder(), prefixIcon: Icon(Icons.description))),
              const SizedBox(height: 15),
              TextField(
                controller: dateController, readOnly: true,
                onTap: () async {
                  DateTime? initialDate = dateController.text.isNotEmpty ? DateTime.parse(dateController.text) : DateTime.now();
                  DateTime? pickedDate = await showDatePicker(context: context, initialDate: initialDate, firstDate: DateTime(2000), lastDate: DateTime(2100));
                  if (pickedDate != null) { dateController.text = pickedDate.toString().split(' ')[0]; }
                },
                decoration: const InputDecoration(labelText: "Fecha Límite", border: OutlineInputBorder(), prefixIcon: Icon(Icons.calendar_today)),
              ),
              const SizedBox(height: 25),
              ElevatedButton.icon(
                onPressed: () async {
                  final title = titleController.text.trim();
                  if (title.isEmpty) return;

                  try {
                    // Asumiendo que DatabaseHelper tiene este método.
                    await DatabaseHelper.instance.updateTask(
                        taskId,
                        title,
                        descriptionController.text.trim(),
                        dateController.text.trim());
                    
                    Navigator.pop(context); 
                    _reloadTaskData(); // Recargar la lista
                    if (mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Tarea actualizada con éxito! 💾"))); }
                  } catch (e) {
                    if (mounted) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error al guardar: ${e.toString()}"))); }
                  }
                },
                icon: const Icon(Icons.save),
                label: const Text("Guardar Cambios"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1ABC9C),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15), 
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    
    // Si la categoría es 'Terminados' y no tienes la columna 'is_completed',
    // usa la lógica que corresponda para filtrar la lista si es necesario.
    if (widget.category == "Terminados" && _filteredTasks.isEmpty) {
        // Puedes agregar una alerta aquí si la DB está incompleta.
    }


    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFE8F6FA),
        iconTheme: const IconThemeData(color: Color(0xFF1ABC9C)),
        elevation: 0,
      ),
      body: _filteredTasks.isEmpty
          ? Center(child: Text("No hay tareas en la lista de ${widget.category}. 🎉"))
          : ListView.builder(
              itemCount: _filteredTasks.length,
              itemBuilder: (context, index) {
                final task = _filteredTasks[index];
                final isCompleted = (task['is_completed'] ?? 0) == 1; // Manejo seguro

                return ListTile(
                  // 6. Icono de Completado/Incompleto
                  leading: IconButton(
                    icon: Icon(
                      isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                      color: isCompleted ? Colors.green : const Color(0xFF1ABC9C),
                    ),
                    onPressed: () => _toggleTaskStatus(task['id'], task['is_completed'] ?? 0),
                  ),
                  
                  // 7. Estilo de texto para tareas completadas
                  title: Text(
                    task['title'],
                    style: TextStyle(
                      decoration: isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
                      color: isCompleted ? Colors.grey : Colors.black,
                    ),
                  ),
                  subtitle: Text(task['description'] ?? 'Sin descripción'),
                  trailing: Text(task['date'] ?? ''),
                  
                  // 8. Al tocar la lista (excepto el ícono), abrimos el modal de edición
                  onTap: () => _showEditTaskModal(task),
                );
              },
            ),
    );
  }
}