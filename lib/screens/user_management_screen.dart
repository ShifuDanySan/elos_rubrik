// lib/screens/user_management_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/usuario.dart';
import '../providers/user_provider.dart';

class UserManagementScreen extends StatelessWidget {
  const UserManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Usamos Consumer para escuchar los cambios en UserProvider
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Gestión de Usuarios (MySQL)'),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: userProvider.isLoading ? null : userProvider.fetchAllUsers,
                tooltip: 'Recargar Usuarios',
              ),
            ],
          ),
          body: _buildBody(context, userProvider),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showAddUserDialog(context, userProvider),
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
            shape: const CircleBorder(),
            child: const Icon(Icons.person_add),
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, UserProvider userProvider) {
    if (userProvider.isLoading && userProvider.users.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (userProvider.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 60),
              const SizedBox(height: 16),
              Text(
                'Error de conexión o datos:\n${userProvider.errorMessage}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red, fontSize: 16),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: userProvider.fetchAllUsers,
                icon: const Icon(Icons.refresh),
                label: const Text('Intentar de Nuevo'),
              ),
            ],
          ),
        ),
      );
    }

    if (userProvider.users.isEmpty) {
      return const Center(
        child: Text(
          'No hay usuarios registrados. ¡Añade uno!',
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      itemCount: userProvider.users.length,
      itemBuilder: (context, index) {
        final user = userProvider.users[index];
        return _buildUserListItem(context, user, userProvider);
      },
    );
  }

  Widget _buildUserListItem(BuildContext context, User user, UserProvider userProvider) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.teal.shade100,
          child: Text(
            user.nombre[0].toUpperCase(),
            style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text('${user.nombre} ${user.apellido}', style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('DNI: ${user.dni}', style: const TextStyle(fontSize: 12)),
            Text('Email: ${user.email}', style: const TextStyle(fontSize: 12)),
            Text('Tipo: ${user.tipoUsuario == 1 ? 'Admin' : 'Cliente'}', style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
          ],
        ),
        isThreeLine: true,
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () => _confirmDelete(context, user, userProvider),
          tooltip: 'Eliminar Usuario',
        ),
      ),
    );
  }

  /// Muestra un diálogo para confirmar la eliminación del usuario.
  void _confirmDelete(BuildContext context, User user, UserProvider userProvider) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirmar Eliminación'),
          content: Text('¿Estás seguro de que quieres eliminar a ${user.nombre} ${user.apellido} (DNI: ${user.dni})?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                userProvider.deleteUser(user.dni);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );
  }

  /// Muestra un diálogo para agregar un nuevo usuario.
  void _showAddUserDialog(BuildContext context, UserProvider userProvider) {
    final dniController = TextEditingController();
    final nombreController = TextEditingController();
    final apellidoController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Agregar Nuevo Usuario'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTextField(dniController, 'DNI', Icons.badge, (v) => v!.isEmpty ? 'Ingrese DNI' : null),
                  _buildTextField(nombreController, 'Nombre', Icons.person, (v) => v!.isEmpty ? 'Ingrese Nombre' : null),
                  _buildTextField(apellidoController, 'Apellido', Icons.person_outline, (v) => v!.isEmpty ? 'Ingrese Apellido' : null),
                  _buildTextField(emailController, 'Email', Icons.email, (v) => v!.isEmpty || !v.contains('@') ? 'Ingrese Email válido' : null, TextInputType.emailAddress),
                  _buildTextField(passwordController, 'Contraseña', Icons.lock, (v) => v!.length < 6 ? 'Mínimo 6 caracteres' : null, TextInputType.visiblePassword, isObscure: true),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  try {
                    await userProvider.addUser(
                      dni: dniController.text.trim(),
                      nombre: nombreController.text.trim(),
                      apellido: apellidoController.text.trim(),
                      email: emailController.text.trim(),
                      password: passwordController.text.trim(),
                    );
                    Navigator.of(context).pop(); // Cierra el diálogo al éxito
                  } catch (e) {
                    // Muestra una notificación simple de error
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Fallo al agregar: ${userProvider.errorMessage}')),
                    );
                  }
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTextField(
      TextEditingController controller,
      String label,
      IconData icon,
      String? Function(String?) validator,
      [TextInputType keyboardType = TextInputType.text, bool isObscure = false]
      ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: isObscure,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.teal),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.teal, width: 2),
          ),
        ),
        validator: validator,
      ),
    );
  }
}