class Category {
  final String id;
  final String name;
  final String description;

  Category({this.id, this.name, this.description});

  factory Category.fromJson(Map<String, dynamic> parsedJson) {
    return new Category(
      id: parsedJson['_id'],
      name: parsedJson['name'],
      description: parsedJson['description'],
    );
  }
}
