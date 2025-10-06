import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
// 🔑 Para formateo de fechas en español
import 'package:intl/date_symbol_data_local.dart'; 
import 'package:intl/intl.dart'; 

// Importaciones de tus pantallas
import 'screens/login_screen.dart'; 
import 'screens/home_screen.dart'; // Asegúrate de tener esta pantalla
import 'db/database_helper.dart'; // Importar DatabaseHelper

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializa los datos de formato para el idioma español
  await initializeDateFormatting('es', null); 
  Intl.defaultLocale = 'es'; 

  // Inicializa Firebase (opcional, si lo usas)
  await Firebase.initializeApp(); 

  // 🔑 Verifica si hay un usuario loggeado en sesión
  final userId = await DatabaseHelper.instance.getSessionUserId();
  
  runApp(MyApp(initialUserId: userId));
}

class MyApp extends StatelessWidget {
  final int? initialUserId;
  const MyApp({super.key, this.initialUserId});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FINORA App',
      locale: const Locale('es', 'ES'), 
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      
      // 🔑 Decide la pantalla inicial según la sesión
      home: initialUserId != null 
          ? HomeScreenWrapper(userId: initialUserId!)
          : const LoginScreen(), 
    );
  }
}

// 🔑 Widget que obtiene el nombre real del usuario desde la BD antes de mostrar HomeScreen
class HomeScreenWrapper extends StatefulWidget {
  final int userId;
  const HomeScreenWrapper({super.key, required this.userId});

  @override
  State<HomeScreenWrapper> createState() => _HomeScreenWrapperState();
}

class _HomeScreenWrapperState extends State<HomeScreenWrapper> {
  String? username;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final db = DatabaseHelper.instance;
    final user = await db.database.then(
      (db) => db.query(
        'users',
        where: 'id = ?',
        whereArgs: [widget.userId],
      ),
    );
    if (user.isNotEmpty) {
      setState(() {
        username = user.first['username'] as String;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (username == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return HomeScreen(username: username!, userId: widget.userId);
  }
}
