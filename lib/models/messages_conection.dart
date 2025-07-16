class MessagesConectionResponse {
  int? code;
  List<Content>? content;
  Metadata? metadata;

  MessagesConectionResponse({this.code, this.content, this.metadata});

  MessagesConectionResponse.fromJson(Map<String, dynamic> json) {
    code = json['code'];
    if (json['content'] != null) {
      content = <Content>[];
      json['content'].forEach((v) {
        content!.add(Content.fromJson(v));
      });
    }
    metadata = json['metadata'] != null ? Metadata.fromJson(json['metadata']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['code'] = code;
    if (content != null) {
      data['content'] = content!.map((v) => v.toJson()).toList();
    }
    if (metadata != null) {
      data['metadata'] = metadata!.toJson();
    }
    return data;
  }
}

class Content {
  String? id;
  String? integrationAuthId;
  String? organizationId;
  String? provider;
  String? uid;
  String? name;
  String? avatar;
  String? subscribed;
  String? connectionState;
  int? status;
  String? createdBy;
  String? createdDate;

  Content(
      {this.id,
      this.integrationAuthId,
      this.organizationId,
      this.provider,
      this.uid,
      this.name,
      this.avatar,
      this.subscribed,
      this.connectionState,
      this.status,
      this.createdBy,
      this.createdDate});

  Content.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    integrationAuthId = json['integrationAuthId'];
    organizationId = json['organizationId'];
    provider = json['provider'];
    uid = json['uid'];
    name = json['name'];
    avatar = json['avatar'];
    subscribed = json['subscribed'];
    connectionState = json['connectionState'];
    status = json['status'];
    createdBy = json['createdBy'];
    createdDate = json['createdDate'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['integrationAuthId'] = integrationAuthId;
    data['organizationId'] = organizationId;
    data['provider'] = provider;
    data['uid'] = uid;
    data['name'] = name;
    data['avatar'] = avatar;
    data['subscribed'] = subscribed;
    data['connectionState'] = connectionState;
    data['status'] = status;
    data['createdBy'] = createdBy;
    data['createdDate'] = createdDate;
    return data;
  }
}

class Metadata {
  int? total;
  int? count;
  int? offset;
  int? limit;

  Metadata({this.total, this.count, this.offset, this.limit});

  Metadata.fromJson(Map<String, dynamic> json) {
    total = json['total'];
    count = json['count'];
    offset = json['offset'];
    limit = json['limit'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['total'] = total;
    data['count'] = count;
    data['offset'] = offset;
    data['limit'] = limit;
    return data;
  }
}
