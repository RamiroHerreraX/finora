import 'package:flutter/material.dart';
import '../db/database_helper.dart'; // Asegúrate de que esta ruta sea correcta

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Clave global para el formulario
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  // Estados para mostrar/ocultar contraseña
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Expresiones regulares
  final RegExp _emailRegex = RegExp(
      r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9]+\.[a-zA-Z]+");
  final RegExp _passwordRegex = RegExp(
      r'^(?=.*[A-Z])(?=.*\d)(?=.*[!@#$%^&*()_+={}\[\]|\\:;"<,>.?/]).{8,}$');

  // -------------------- MÉTODO DE REGISTRO --------------------
  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final username = _usernameController.text.trim();
      final password = _passwordController.text.trim();

      try {
        final result =
            await DatabaseHelper.instance.register(username, password);

        if (!mounted) return;

        if (result == -1) {
          // Alerta: Usuario ya existe
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text("El usuario (email) ya existe. Intenta con otro. 🛑"),
              backgroundColor: Colors.orange,
            ),
          );
        } else if (result > 0) {
          // Alerta: Éxito
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Usuario registrado con éxito. ¡Inicia sesión! 🎉"),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );

          _usernameController.clear();
          _passwordController.clear();
          _confirmPasswordController.clear();

          Navigator.pop(context); // Regresar al Login
        } else {
          // Alerta: Error genérico de registro
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Error al registrar. Intenta de nuevo. 🚫"),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (!mounted) return;
        // ALERTA CORREGIDA: En lugar de mostrar el error técnico de la base de datos (e.g., DatabaseException),
        // mostramos un mensaje amigable al usuario que indica un fallo general del servicio.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("No se pudo conectar al servicio de registro. Intenta más tarde. 🌐"), 
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // -------------------- BUILD WIDGET --------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("FINORA - Registro"),
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  "Crea tu cuenta",
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                const Text(
                  "Únete a FINORA y toma el control de tus finanzas.",
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                // Campo Email
                TextFormField(
                  controller: _usernameController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: "Usuario (Email)",
                    prefixIcon: const Icon(Icons.email),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'El email es obligatorio.';
                    }
                    if (!_emailRegex.hasMatch(value)) {
                      return 'Introduce un formato de email válido.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                
                // INDICACIONES DE CONTRASEÑA FUERA DEL TEXTFIELD
                const Text(
                  "Requisitos de la contraseña: Mín. 8 caracteres, 1 Mayúscula, 1 Número y 1 Símbolo.",
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 8), 

                // Campo Contraseña con mostrar/ocultar
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: "Contraseña",
                    prefixIcon: const Icon(Icons.lock),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    // hintText: "Mín. 8 chars, Mayús, Núm, Símbolo" <-- Eliminado
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword
                          ? Icons.visibility
                          : Icons.visibility_off),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'La contraseña es obligatoria.';
                    }
                    if (!_passwordRegex.hasMatch(value)) {
                      return 'No cumple los requisitos de seguridad.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Confirmar Contraseña con mostrar/ocultar
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    labelText: "Confirmar Contraseña",
                    prefixIcon: const Icon(Icons.lock_reset),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirmPassword
                          ? Icons.visibility
                          : Icons.visibility_off),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Confirma tu contraseña.';
                    }
                    if (value != _passwordController.text) {
                      return 'Las contraseñas no coinciden.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 30),

                // Botón Registro
                ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    elevation: 5,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                      : const Text(
                          "Registrarme",
                          style: TextStyle(fontSize: 18),
                        ),
                ),
                const SizedBox(height: 20),

                // Enlace para volver a Login
                TextButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          Navigator.pop(context);
                        },
                  child: const Text("¿Ya tienes cuenta? Inicia Sesión"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}cñ