import 'package:flutter/material.dart';
import '../models/task_template.dart';
import '../models/template_category.dart';
import '../services/template_service.dart';

class TemplateProvider extends ChangeNotifier {
  List<TemplateCategory> _categories        = [];
  List<TaskTemplate>     _templates         = [];
  int?                   _selectedCategory;
  bool                   _loadingCategories = false;
  bool                   _loadingTemplates  = false;
  String?                _error;

  // ── Getters ──────────────────────────────────────────────────────────────
  List<TemplateCategory> get categories        => _categories;
  List<TaskTemplate>     get templates         => _templates;
  int?                   get selectedCategory  => _selectedCategory;
  bool                   get loadingCategories => _loadingCategories;
  bool                   get loadingTemplates  => _loadingTemplates;
  bool                   get loading           => _loadingCategories || _loadingTemplates;
  String?                get error             => _error;

  // Plantillas filtradas por la categoría seleccionada actualmente.
  // Si no hay categoría seleccionada devuelve todas.
  List<TaskTemplate> get filteredTemplates {
    if (_selectedCategory == null) return _templates;
    return _templates.where((t) => t.idCategory == _selectedCategory).toList();
  }

  // ── GET /categories — Cargar categorías ──────────────────────────────────
  Future<void> loadCategories() async {
    _loadingCategories = true;
    _error             = null;
    notifyListeners();
    try {
      _categories = await TemplateService.getCategories();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    }
    _loadingCategories = false;
    notifyListeners();
  }

  // ── GET /templates — Cargar plantillas activas ────────────────────────────
  // Si idCategory es null trae todas. Guarda también la categoría activa
  // para que filteredTemplates funcione sin petición extra.
  Future<void> loadTemplates({int? idCategory}) async {
    _loadingTemplates = true;
    _selectedCategory = idCategory;
    _error            = null;
    notifyListeners();
    try {
      _templates = await TemplateService.getTemplates(idCategory: idCategory);
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    }
    _loadingTemplates = false;
    notifyListeners();
  }

  // Carga categorías y todas las plantillas en paralelo.
  // Útil al abrir la pantalla de creación de tarea (RF-F14) para tenerlo
  // todo listo de una sola vez.
  Future<void> loadAll() async {
    await Future.wait([
      loadCategories(),
      loadTemplates(),
    ]);
  }

  // Cambia la categoría seleccionada y filtra localmente sin ir al servidor.
  // Solo llama al servidor si las plantillas de esa categoría no están cargadas.
  Future<void> selectCategory(int? idCategory) async {
    if (_selectedCategory == idCategory) return;
    _selectedCategory = idCategory;
    notifyListeners();

    // Si ya tenemos plantillas de todas las categorías (carga inicial con
    // idCategory=null), el filtrado es local y no hace falta otra petición.
    final alreadyLoaded = _templates.isNotEmpty &&
        (idCategory == null ||
            _templates.any((t) => t.idCategory == idCategory));

    if (!alreadyLoaded) {
      await loadTemplates(idCategory: idCategory);
    }
  }

  // ── GET /templates/{id} — Buscar plantilla por id en caché o en API ───────
  // Primero busca en la lista ya cargada para evitar una petición innecesaria.
  Future<TaskTemplate?> getTemplateById(int idTemplate) async {
    final cached = _templates.where((t) => t.idTaskTemplate == idTemplate);
    if (cached.isNotEmpty) return cached.first;

    _error = null;
    try {
      return await TemplateService.getTemplateById(idTemplate);
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return null;
    }
  }

  // ── Limpia el estado (cerrar sesión) ──────────────────────────────────────
  void clear() {
    _categories       = [];
    _templates        = [];
    _selectedCategory = null;
    _error            = null;
    notifyListeners();
  }
}