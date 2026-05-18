class TemplateCategory {
  final int idCategory;
  final String categoryName;
  final String? categoryDescription;

  TemplateCategory({
    required this.idCategory,
    required this.categoryName,
    this.categoryDescription,
  });

  factory TemplateCategory.fromJson(Map<String, dynamic> json) {
    return TemplateCategory(
      idCategory:          json['id_category'],
      categoryName:        json['category_name'],
      categoryDescription: json['category_description'],
    );
  }
}