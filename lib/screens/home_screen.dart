import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import 'login_screen.dart';
import 'task_screen.dart';

class HomeScreen extends StatelessWidget {
  final String username;
  final int userId;

  const HomeScreen({super.key, required this.username, required this.userId});

  // 🔑 MÉTODO DE CIERRE DE SESIÓN
  Future<void> _logout(BuildContext context) async {
    await DatabaseHelper.instance.logout();
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("FINORA - Inicio"),
        automaticallyImplyLeading: false, // Oculta el botón de retroceso
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Cerrar Sesión",
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "¡Bienvenido, $username!",
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 50),
            ElevatedButton(
              child: const Text("Ir a Mis Tareas"),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TaskScreen(userId: userId),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
