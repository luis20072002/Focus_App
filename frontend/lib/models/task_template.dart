class TaskTemplate {
  final int idTaskTemplate;
  final int idCategory;
  final String name;
  final String? description;
  final int fointsBase;
  final bool active;

  TaskTemplate({
    required this.idTaskTemplate,
    required this.idCategory,
    required this.name,
    this.description,
    required this.fointsBase,
    required this.active,
  });

  factory TaskTemplate.fromJson(Map<String, dynamic> json) {
    return TaskTemplate(
      idTaskTemplate: json['id_task_template'],
      idCategory:     json['id_category'],
      name:           json['name'],
      description:    json['description'],
      fointsBase:     json['foints_base'],
      active:         json['active'] ?? true,
    );
  }
}