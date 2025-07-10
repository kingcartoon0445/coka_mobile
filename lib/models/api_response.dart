class ApiResponse<T> {
  final bool isSuccess;
  final T? data;
  final String message;

  ApiResponse({
    required this.isSuccess,
    this.data,
    required this.message,
  });

  // Factory constructors cho success và error
  factory ApiResponse.success(T data) {
    return ApiResponse(
      isSuccess: true,
      data: data,
      message: '',
    );
  }

  factory ApiResponse.error(String message) {
    return ApiResponse(
      isSuccess: false,
      data: null,
      message: message,
    );
  }
}

class HiddenStagesResponse {
  final List<String>? hiddenStages;
  final List<String>? hiddenGroups;

  HiddenStagesResponse({
    this.hiddenStages,
    this.hiddenGroups,
  });

  factory HiddenStagesResponse.fromJson(Map<String, dynamic> json) => HiddenStagesResponse(
    hiddenStages: json['hiddenStages'] != null ? List<String>.from(json['hiddenStages']) : null,
    hiddenGroups: json['hiddenGroups'] != null ? List<String>.from(json['hiddenGroups']) : null,
  );
} 