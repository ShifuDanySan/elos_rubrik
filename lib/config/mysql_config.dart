// ESTE ARCHIVO ES SOLO PARA DEFINIR LAS CONSTANTES DE CONFIGURACIÓN.
// EN UNA APLICACIÓN REAL, ESTAS CONSTANTES NUNCA DEBEN SER USADAS
// DIRECTAMENTE POR LA APP MÓVIL (FRONTEND) POR MOTIVOS DE SEGURIDAD.
//
// LAS CONEXIONES A BASES DE DATOS SIEMPRE DEBEN SER MANEJADAS POR UN
// SERVIDOR BACKEND (API REST) SEGURO.

class MySQLConfig {
  // Configuración del servidor de base de datos
  static const String host = '127.0.0.1'; // O la IP/URL de tu servidor MySQL
  static const int port = 3306;
  static const String databaseName = 'sistema_usuarios_db';

  // Credenciales de acceso (¡NUNCA HARDCODEAR EN UN FRONTEND!)
  static const String username = 'root';
  static const String password = 'tu_password_secreta';

  // Ejemplo de tabla crucial (la que acabamos de modificar)
  static const String usersTable = 'USUARIOS';

  // Definición de las columnas de la tabla USUARIOS para referencia
  static const String columnDni = 'dni';
  static const String columnNombre = 'nombre';
  static const String columnApellido = 'apellido';
  static const String columnEmail = 'email';
  static const String columnTipoUsuario = 'tipoUsuario';

  // Nota sobre la clave primaria (DNI)
  static const String primaryKeyColumn = columnDni;
}