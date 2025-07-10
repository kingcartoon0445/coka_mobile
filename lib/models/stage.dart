// Stage Group Model (không chứa stages để tránh circular reference)
class StageGroup {
  final String id;
  final String name;
  final String hexCode;
  
  StageGroup({
    required this.id,
    required this.name,
    required this.hexCode,
  });
  
  factory StageGroup.fromJson(Map<String, dynamic> json) => StageGroup(
    id: json['id'],
    name: json['name'],
    hexCode: json['hexCode'],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'hexCode': hexCode,
  };

  StageGroup copyWith({
    String? id,
    String? name,
    String? hexCode,
  }) {
    return StageGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      hexCode: hexCode ?? this.hexCode,
    );
  }
}

// Stage Model
class Stage {
  final String id;
  final String name;
  final StageGroup stageGroup;
  
  Stage({required this.id, required this.name, required this.stageGroup});
  
  factory Stage.fromJson(Map<String, dynamic> json) => Stage(
    id: json['id'],
    name: json['name'],
    stageGroup: StageGroup.fromJson(json['stageGroup']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'stageGroup': stageGroup.toJson(),
  };
}

// StageGroupWithStages - model riêng để chứa group và danh sách stages
class StageGroupWithStages {
  final StageGroup group;
  final List<Stage> stages;
  
  StageGroupWithStages({
    required this.group,
    this.stages = const [],
  });

  // Getter methods để truy cập thuộc tính của group
  String get id => group.id;
  String get name => group.name;
  String get hexCode => group.hexCode;

  StageGroupWithStages copyWith({
    StageGroup? group,
    List<Stage>? stages,
  }) {
    return StageGroupWithStages(
      group: group ?? this.group,
      stages: stages ?? this.stages,
    );
  }
} 