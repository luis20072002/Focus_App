class ApiConstants {
  // Cambia a tu IP local si usas dispositivo fisico: 'http://192.168.x.x:8000'
  static const String baseUrl = 'http://127.0.0.1:8000';
  //static const String baseUrl = 'http://10.0.2.2:8000';
  //static const String baseUrl = 'http://172.18.30.64:8000';

  // Auth
  static const String login = '$baseUrl/auth/login';
  static const String register = '$baseUrl/auth/register';
  static const String me = '$baseUrl/auth/me';
  static const String logout = '$baseUrl/auth/logout';

  // Tareas
  static const String tasks = '$baseUrl/tasks/';
  static const String tasksToday = '$baseUrl/tasks/today';

  // Plantillas
  static const String templates = '$baseUrl/templates';
  static const String categories = '$baseUrl/templates/categories';
}
