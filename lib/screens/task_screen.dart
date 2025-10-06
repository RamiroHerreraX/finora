import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../services/notification_service.dart';
import 'task_list_detail_screen.dart'; // Asegúrate de que esta ruta sea correcta
import 'task_calendar_screen.dart'; // Asegúrate de que esta ruta sea correcta

// Definición de colores de fondo para las tarjetas, imitando el diseño
const List<Color> _cardColors = [
  Color(0xFFE6F3FF), // Azul claro (Todas)
  Color(0xFFFFF3E0), // Amarillo claro (Hoy)
  Color(0xFFFFE0E6), // Rojo/Rosa claro (Calendario)
  Color(0xFFE0FFF3), // Verde claro (Terminados)
];

// 1. 🔑 RESTAURA LA CLASE TaskScreen
class TaskScreen extends StatefulWidget {
  final int userId;
  const TaskScreen({super.key, required this.userId});

  @override
  State<TaskScreen> createState() => _TaskScreenState();
}

// 2. 🔑 RESTAURA EL CONTENIDO COMPLETO DE LA CLASE _TaskScreenState
class _TaskScreenState extends State<TaskScreen> {
  // RESTAURA TODAS LAS VARIABLES (getters) AQUÍ
  int _allCount = 0;
  int _todayCount = 0;
  int _calendarCount = 0;
  int _completedCount = 0; 
  
  List<Map<String, dynamic>> _tasks = [];
  Map<String, List<Map<String, dynamic>>> _groupedTasks = {};

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  // RESTAURA TODAS LAS FUNCIONES Y MÉTODOS AQUÍ

  // --- Función para calcular las categorías inteligentes ---
  Future<void> _loadTasks() async {
    try {
      final allTasks = await DatabaseHelper.instance.getTasks(widget.userId);
      final todayDate = DateTime.now().toString().split(' ')[0];

      setState(() {
        _tasks = allTasks;
        _allCount = allTasks.length;
        
        _todayCount = allTasks.where((t) => t['date'] == todayDate).length;
        _calendarCount = allTasks.where((t) => t['date'] != null && t['date'].isNotEmpty).length;
        _completedCount = 0; // Ajusta si tienes columna 'is_completed'
        
        _groupedTasks = {}; 
      });
    } catch (e) {
      print("Error al cargar tareas: $e");
    }
  }

  // Se mantiene el _deleteTask
  Future<void> _deleteTask(int id) async {
    await DatabaseHelper.instance.deleteTask(id);
    _loadTasks();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tarea eliminada.")),
      );
    }
  }

  // Función para manejar la navegación al pulsar una tarjeta
  void _handleCardTap(String categoryName) {
    if (categoryName == "Calendario") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TaskCalendarScreen(userId: widget.userId),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TaskListDetailScreen(
            userId: widget.userId,
            category: categoryName, 
            allTasks: _tasks, // Ahora _tasks está definida
          ),
        ),
      );
    }
  }

  // --- Modal para Agregar Tarea ---
  void _showAddTaskModal() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final dateController = TextEditingController(
        text: DateTime.now().toString().split(' ')[0]);

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
              // ... (Contenido del Modal, se deja abreviado por espacio)
              const Text("Añadir Nueva Tarea 📝", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              const SizedBox(height: 20),
              TextField(controller: titleController, decoration: const InputDecoration(labelText: "Título de la tarea*", border: OutlineInputBorder(), prefixIcon: Icon(Icons.title))),
              const SizedBox(height: 15),
              TextField(controller: descriptionController, maxLines: 3, decoration: const InputDecoration(labelText: "Descripción", border: OutlineInputBorder(), prefixIcon: Icon(Icons.description))),
              const SizedBox(height: 15),
              TextField(
                controller: dateController, readOnly: true,
                onTap: () async {
                  DateTime? pickedDate = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime(2100));
                  if (pickedDate != null) { dateController.text = pickedDate.toString().split(' ')[0]; }
                },
                decoration: const InputDecoration(labelText: "Fecha Límite", border: OutlineInputBorder(), prefixIcon: Icon(Icons.calendar_today)),
              ),
              const SizedBox(height: 25),
              ElevatedButton.icon(
                onPressed: () async {
                  final title = titleController.text.trim();
                  if (title.isEmpty) { return; }
                  try {
                    await DatabaseHelper.instance.addTask(title, descriptionController.text.trim(), dateController.text.trim(), widget.userId);
                    NotificationService.showNotification("Tarea Creada", title);
                    Navigator.pop(context); 
                    _loadTasks(); 
                    if (mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Tarea guardada con éxito! ✅"))); }
                  } catch (e) {
                    if (mounted) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error al guardar: ${e.toString()}"))); }
                  }
                },
                icon: const Icon(Icons.save),
                label: const Text("Guardar Tarea"),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              ),
            ],
          ),
        );
      },
    );
  }
  
  // --- 3. RESTAURA EL MÉTODO _buildTaskCard AQUÍ ---
  Widget _buildTaskCard(String listName, int taskCount, Color color, {List<Map<String, dynamic>>? previewTasks}) {
    IconData icon = switch (listName) {
      "Todas" => Icons.list_alt,
      "Hoy" => Icons.wb_sunny_outlined,
      "Calendario" => Icons.calendar_today_outlined,
      "Terminados" => Icons.check_circle_outline,
      _ => Icons.folder, // Para listas de usuario
    };
    
    return InkWell(
      onTap: () => _handleCardTap(listName),
      child: Card(
        color: color,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(icon, size: 20, color: Colors.black54),
                      const SizedBox(width: 5),
                      Text(
                        listName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                  Text(
                    taskCount.toString(),
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (previewTasks != null)
                ...previewTasks.take(3).map((task) => Padding(
                  padding: const EdgeInsets.only(bottom: 5.0),
                  child: Row(
                    children: [
                      Icon(Icons.circle_outlined, size: 14, color: Colors.black54),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(task['title'], style: TextStyle(fontSize: 14, color: Colors.black87), overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                )).toList(),
            ],
          ),
        ),
      ),
    );
  }
  
  // --- Widget Build Principal ---
  @override
  Widget build(BuildContext context) {
    final listNames = _groupedTasks.keys.toList(); // Ahora _groupedTasks está definida

    return Scaffold(
      backgroundColor: const Color(0xFFE8F6FA), 
      appBar: AppBar(
        title: const Text("Tareas", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 28, color: Color(0xFF1ABC9C))),
        backgroundColor: const Color(0xFFE8F6FA), centerTitle: false, elevation: 0,
        actions: [ IconButton(onPressed: () {}, icon: const Icon(Icons.settings)), const SizedBox(width: 10) ],
      ),
      
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(left: 30.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Funcionalidad 'Nueva lista' pendiente de implementar en DB.")));
              }, 
              child: const Text("Nueva lista", style: TextStyle(color: Color(0xFF1ABC9C), fontWeight: FontWeight.bold))
            ),
            FloatingActionButton.extended(
              onPressed: _showAddTaskModal,
              label: const Text("Nuevo"),
              icon: const Icon(Icons.add),
              backgroundColor: const Color(0xFF1ABC9C),
            ),
          ],
        ),
      ),
      
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(15.0),
              child: GridView.count(
                shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisCount: 2, crossAxisSpacing: 10.0, mainAxisSpacing: 10.0, childAspectRatio: 1.0,
                children: [
                  // Llama a _buildTaskCard y a las variables (getters) que ahora están definidas
                  _buildTaskCard("Todas", _allCount, _cardColors[0]),
                  _buildTaskCard("Hoy", _todayCount, _cardColors[1]),
                  _buildTaskCard("Calendario", _calendarCount, _cardColors[2]),
                  _buildTaskCard("Terminados", _completedCount, _cardColors[3]),
                ],
              ),
            ),
          ),
          
          if (listNames.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(left: 15.0, top: 20.0, bottom: 10.0),
              child: Text("MIS LISTAS", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[600])),
            ),
          ),

          if (listNames.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 10.0, mainAxisSpacing: 10.0, childAspectRatio: 1.0),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final listName = listNames[index];
                  final tasks = _groupedTasks[listName]!;
                  Color cardColor = _cardColors[(index + 4) % _cardColors.length]; 
                  return _buildTaskCard(listName, tasks.length, cardColor, previewTasks: tasks);
                },
                childCount: listNames.length,
              ),
            ),
          ),
          
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}