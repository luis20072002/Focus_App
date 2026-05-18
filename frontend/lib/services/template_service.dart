import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';
import '../core/utils/token_storage.dart';
import '../models/task_template.dart';
import '../models/template_category.dart';

class TemplateService {
  static Future<Map<String, String>> _headers() async {
    final token = await TokenStorage.getToken();
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  // ── GET /categories — Listar todas las categorías ─────────────────────────
  static Future<List<TemplateCategory>> getCategories() async {
    final response = await http.get(
      Uri.parse(ApiConstants.categories),
      headers: await _headers(),
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => TemplateCategory.fromJson(e)).toList();
    } else {
      throw Exception('Error al obtener las categorías');
    }
  }

  // ── GET /templates?id_category= — Plantillas activas ─────────────────────
  // Si idCategory es null devuelve todas las plantillas activas.
  // Si se especifica, filtra por categoría.
  static Future<List<TaskTemplate>> getTemplates({int? idCategory}) async {
    final uri = Uri.parse(ApiConstants.templates).replace(
      queryParameters: idCategory != null
          ? {'id_category': '$idCategory'}
          : null,
    );

    final response = await http.get(uri, headers: await _headers());

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => TaskTemplate.fromJson(e)).toList();
    } else {
      throw Exception('Error al obtener las plantillas');
    }
  }

  // ── GET /templates/{id} — Ver plantilla individual ────────────────────────
  static Future<TaskTemplate> getTemplateById(int idTemplate) async {
    final response = await http.get(
      Uri.parse(ApiConstants.templateById(idTemplate)),
      headers: await _headers(),
    );

    if (response.statusCode == 200) {
      return TaskTemplate.fromJson(jsonDecode(response.body));
    } else if (response.statusCode == 404) {
      throw Exception('Plantilla no encontrada');
    } else {
      throw Exception('Error al obtener la plantilla');
    }
  }
}