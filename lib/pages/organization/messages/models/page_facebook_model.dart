class FacebookPageList {
  final List<FacebookPage> data;
  final Paging? paging;

  FacebookPageList({required this.data, this.paging});

  factory FacebookPageList.fromJson(Map<String, dynamic> json) {
    return FacebookPageList(
      data: (json['data'] as List).map((e) => FacebookPage.fromJson(e)).toList(),
      paging: json['paging'] != null ? Paging.fromJson(json['paging']) : null,
    );
  }
}

class FacebookPage {
  final String id;
  final String name;
  final String accessToken;
  final String category;
  final List<Category> categoryList;
  final List<String> tasks;

  FacebookPage({
    required this.id,
    required this.name,
    required this.accessToken,
    required this.category,
    required this.categoryList,
    required this.tasks,
  });

  factory FacebookPage.fromJson(Map<String, dynamic> json) {
    return FacebookPage(
      id: json['id'],
      name: json['name'],
      accessToken: json['access_token'],
      category: json['category'],
      categoryList: (json['category_list'] as List).map((e) => Category.fromJson(e)).toList(),
      tasks: List<String>.from(json['tasks']),
    );
  }
}

class Category {
  final String id;
  final String name;

  Category({required this.id, required this.name});

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'],
    );
  }
}

class Paging {
  final Cursors cursors;

  Paging({required this.cursors});

  factory Paging.fromJson(Map<String, dynamic> json) {
    return Paging(
      cursors: Cursors.fromJson(json['cursors']),
    );
  }
}

class Cursors {
  final String before;
  final String after;

  Cursors({required this.before, required this.after});

  factory Cursors.fromJson(Map<String, dynamic> json) {
    return Cursors(
      before: json['before'],
      after: json['after'],
    );
  }
}
