class UserProfileResponse {
  final int? code;
  final UserProfile? content;

  UserProfileResponse({
    required this.code,
    required this.content,
  });

  factory UserProfileResponse.fromJson(Map<String, dynamic> json) {
    return UserProfileResponse(
      code: json['code'] as int?,
      content: json['content'] != null
          ? UserProfile.fromJson(json['content'] as Map<String, dynamic>)
          : null,
    );
  }
}

class UserProfile {
  final String? id;
  final String? fullName;
  final String? phone;
  final String? email;
  final DateTime? dob;
  final int? gender;
  final String? about;
  final String? address;
  final String? position;
  final String? avatar;
  final String? cover;
  final bool? isVerifyPhone;
  final bool? isVerifyEmail;
  final bool? isFcm;

  UserProfile({
    this.id,
    this.fullName,
    this.phone,
    this.email,
    this.dob,
    this.gender,
    this.about,
    this.address,
    this.position,
    this.avatar,
    this.cover,
    this.isVerifyPhone,
    this.isVerifyEmail,
    this.isFcm,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String?,
      fullName: json['fullName'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      dob: json['dob'] != null ? DateTime.tryParse(json['dob']) : null,
      gender: json['gender'] as int?,
      about: json['about'] as String?,
      address: json['address'] as String?,
      position: json['position'] as String? ?? '',
      avatar: json['avatar'] as String?,
      cover: json['cover'] as String? ?? '',
      isVerifyPhone: json['isVerifyPhone'] as bool?,
      isVerifyEmail: json['isVerifyEmail'] as bool?,
      isFcm: json['isFcm'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'phone': phone,
      'email': email,
      'dob': dob?.toIso8601String(),
      'gender': gender,
      'about': about,
      'address': address,
      'position': position,
      'avatar': avatar,
      'cover': cover,
      'isVerifyPhone': isVerifyPhone,
      'isVerifyEmail': isVerifyEmail,
      'isFcm': isFcm,
    };
  }
}
