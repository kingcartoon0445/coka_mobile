import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:coka/api/api_client.dart';
import 'package:coka/api/repositories/organization_repository.dart';
import 'package:coka/shared/widgets/awesome_alert.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

//Color

const kPrimaryColor = Color(0xFF4C46F1);

const kSecondaryColor = Color(0xFFF0F5F9);

const kTextColor = Color(0xFF2D2D2D);

const kTextSmallColor = Color(0x66323438);

// Form Error

final RegExp emailValidatorRegExp = RegExp(r"^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+");

final RegExp phonenumValidatorRegExp = RegExp(r'^(?:\+?(?:84)?|0)([0-9]{9})$');

final RegExp nameRegExp = RegExp(
    r'[a-zỳọáầảấờễàạằệếýộậốũứĩõúữịỗìềểẩớặòùồợãụủíỹắẫựỉỏừỷởóéửỵẳẹèẽổẵẻỡơôưăêâđA-ZỲỌÁẦẢẤỜỄÀẠẰỆẾÝỘẬỐŨỨĨÕÚỮỊỖÌỀỂẨỚẶÒÙỒỢÃỤỦÍỸẮẪỰỈỎỪỶỞÓÉỬỴẲẸÈẼỔẴẺỠƠÔƯĂÊÂĐ ]{4,30}$');

final RegExp regex = RegExp(r'^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[!@#\$&*~]).{8,}$');

final RegExp numberRegExp = RegExp(r'\d');

const String kOtpError = "Mã OTP không đúng";

const String kLoginError = "Tài khoản hoặc mật khẩu không đúng";

const String kEmailNullError = "Hãy nhập email của bạn";

const String kAddressNullError = "Hãy nhập địa chỉ của bạn";

const String kCompanyNullError = "Hãy nhập công ty của bạn";

const String kJobNullError = "Hãy nhập công việc của bạn";

const String kAchieveNullError = "Hãy nhập thành tựu của bạn";

const String kInvalidEmailError = "Hãy nhập email hợp lệ";

const String kEmailPhoneNullError = "Hãy nhập email hoặc số điện thoại của bạn";

const String kInvalidEmailPhoneError = "Hãy nhập email hoặc số điện thoại hợp lệ";

const String kInvalidNameError = "Hãy nhập tên hợp lệ";

const String kPassNullError = "Hãy nhập mật khẩu của bạn";

const String kRepeatPassNullError = "Hãy nhập mật khẩu xác nhận của bạn";

const String kShortPassError = "Mật khầu quá ngắn";

const String kValidPassError =
    "Mật khẩu phải có từ 8 ký tự trở lên bao gồm chữ số chữ hoa chữ thường và ký tự đặc biệt";

const String kMatchPassError = "Mật khẩu và mật khẩu xác nhận không trùng khớp";

const String kNamelNullError = "Hãy nhập tên của bạn";

const String kPhoneNumberNullError = "Hãy nhập số điện thoại của bạn";

const String kInvalidPhoneError = "Hãy nhập số điện thoại hợp lệ của bạn";

const String kDuplicatePhoneError = "Số điện thoại đã được sử dụng";

const String kOtpNumberNullError = "Hãy nhập đủ mã OTP của bạn";

const String kRollNullError = "Hãy chọn một chức vụ";

//demo img

const String kAvaUrl = "https://i.imgur.com/2w5h8sN.jpg";

const String kAvaUrl1 = "https://i.imgur.com/ju4l1Vs.jpg";

const String kAvaUrl2 = "https://i.imgur.com/2gdXfvG.jpg";

const String kAvaUrl3 = "https://i.imgur.com/EdBgFva.jpg";

const String kAvaUrl4 = "https://i.imgur.com/SWt1EVV.jpg";

const String kBannerUrl = "https://i.imgur.com/3sVZz2e.jpg";

const String kProjectImage1 = "https://i.imgur.com/o5iHudS.jpg";

const String kProjectImage2 = "https://i.imgur.com/ZmU9vYg.jpg";

const String kProjectImage3 = "https://i.imgur.com/LEpFPq4.jpg";

const String kProjectImage4 = "https://i.imgur.com/cYcDvJe.jpg";

const sortAsc = 'Sort=[{ Column: "CreatedDate", Dir: "ASC" }]';

const sortDesc = 'Sort=[{ Column: "CreatedDate", Dir: "DESC" }]';

class ChartModel {
  ChartModel(this.name, this.value, {this.color});

  final String name;

  final num value;

  final Color? color;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'value': value,
    };
  }
}

Color getTabBadgeColor(tabName) {
  if (tabName == "Tất cả") {
    return const Color(0xFF5C33F0);
  } else if (tabName == "Tiềm năng") {
    return const Color(0xFF92F7A8);
  } else if (tabName == "Giao dịch") {
    return const Color(0xFFA4F3FF);
  } else if (tabName == "Không tiềm năng") {
    return const Color(0xFFFEC067);
  } else if (tabName == "Chưa xác định") {
    return const Color(0xFF9F87FF);
  }

  return const Color(0xFF9F87FF);
}

String getGenderName(int gender) {
  return gender == 1
      ? "Nam"
      : gender == 0
          ? "Nữ"
          : "Chưa xác định";
}

int calculateAge(String birthDateString) {
  DateTime birthDate = DateTime.parse(birthDateString);

  DateTime currentDate = DateTime.now();

  int age = currentDate.year - birthDate.year;

  if (currentDate.month < birthDate.month ||
      (currentDate.month == birthDate.month && currentDate.day < birthDate.day)) {
    age--;
  }

  return age;
}

bool isLastElement(Map data, String key) {
  List keys = data.keys.toList();

  int index = keys.indexOf(key);

  return index == keys.length - 1;
}

String capitalize(String input) {
  if (input.isEmpty) {
    return input;
  }

  return input[0].toUpperCase() + input.substring(1);
}

int getRoundedPercentage(Map data, String key) {
  if (data.containsKey(key)) {
    num total = 0;

    data.forEach((_, value) {
      total += value;
    });

    if (total == 0) {
      return 0;
    }

    double percentage = (data[key]! / total) * 100.0;

    return percentage.round();
  } else {
    // Trả về 0 nếu key không tồn tại trong map

    return 0;
  }
}

String getGroupNameFromKey(key) {
  if (key == "potential") {
    return "Tiềm năng";
  }

  if (key == "transaction") {
    return "Giao dịch";
  }

  if (key == "unpotential") {
    return "Không tiềm năng";
  }

  if (key == "undefined") {
    return "Không xác định";
  }

  if (key == "other") {
    return "Khác";
  }

  return "";
}

Color getColorFromKey(key) {
  if (key == "potential") {
    return const Color(0xFFA4F3FF);
  }

  if (key == "transaction") {
    return const Color(0xFF92F7A8);
  }

  if (key == "unpotential") {
    return const Color(0xFFFEBE99);
  }

  if (key == "undefined") {
    return const Color(0xFF9F87FF);
  }

  return const Color(0xFF9F87FF);
}

const stageGroupList = [
  {"id": "", "name": "Tất cả"},
  {"id": "47ae12c7-8203-42c2-9374-85d05dca862e", "name": "Tiềm năng"},
  {"id": "7504f2d7-c8af-41b5-9d7a-b327439cb1f7", "name": "Giao dịch"},
  {"id": "637c8daa-7bc8-4766-a254-2c2cfb449915", "name": "Không tiềm năng"},
  {"id": "e393d663-2d80-4d2e-8472-6c7e36ce2d53", "name": "Chưa xác định"}
];

const stageObject = {
  "47ae12c7-8203-42c2-9374-85d05dca862e": {
    "name": "Tiềm năng",
    "data": [
      {"id": "7393c211-d4fc-48db-8091-ddd70aa9004a", "name": "Gửi thông tin"},
      {"id": "76580f68-d4e2-4566-a3ef-7b4f693ec084", "name": "Quan tâm"},
      {"id": "9b6927e5-b6dc-4249-9e5f-1bab9750cd6c", "name": "Hẹn gặp"},
      {"id": "f0c1bd4f-a823-4521-b547-5eb0cf607f78", "name": "Tham quan dự án"},
      {"id": "f0c1bd4f-a823-4521-b547-5eb0cf607f79", "name": "Hẹn xem dự án"}
    ]
  },
  "637c8daa-7bc8-4766-a254-2c2cfb449915": {
    "name": "Không tiềm năng",
    "data": [
      {"id": "4fb8b6c4-be9a-47c2-8cb6-261f0649e285", "name": "Không có nhu cầu"},
      {"id": "8780f70c-db39-46bc-9354-184e8fbe3aaf", "name": "Sai số điện thoại"},
      {"id": "9b483dc8-a806-437a-be8f-8721b756508b", "name": "Không liên lạc được"},
      {"id": "e6a87dfa-a9dd-4c67-9a84-a9130ce12f9b", "name": "Không quan tâm"}
    ]
  },
  "7504f2d7-c8af-41b5-9d7a-b327439cb1f7": {
    "name": "Giao dịch",
    "data": [
      {"id": "5308d266-06b2-452f-84f6-f480bcc8e2d4", "name": "Đặt chỗ"},
      {"id": "6e852feb-e32b-40c7-9530-171bc2b38db8", "name": "Huỷ giao dịch"},
      {"id": "83d2fd99-2e15-4b27-ba7c-2157d4c02d7e", "name": "Đặt cọc"},
      {"id": "ae95f985-61ee-4fd9-b64c-53e1748c723e", "name": "Ký HĐMB"}
    ]
  },
  "e393d663-2d80-4d2e-8472-6c7e36ce2d53": {
    "name": "Chưa xác định",
    "data": [
      {"id": "54032f73-108e-41a2-8ba6-aa9de96ab47b", "name": "Mới"},
      {"id": "edd11358-a4c2-4b42-ab24-994a232a5eb8", "name": "Không bắt máy"},
      {
        "id": "fb0d9904-2d5a-4b2c-9d35-c1c13838d5ba",
        "name": "Gọi lại sau",
      }
    ]
  },
};

const stageList = [
  {
    "id": "4fb8b6c4-be9a-47c2-8cb6-261f0649e285",
    "name": "Không có nhu cầu",
    "group": {"id": "637c8daa-7bc8-4766-a254-2c2cfb449915", "name": "Không tiềm năng"}
  },
  {
    "id": "5308d266-06b2-452f-84f6-f480bcc8e2d4",
    "name": "Đặt chỗ",
    "group": {"id": "7504f2d7-c8af-41b5-9d7a-b327439cb1f7", "name": "Giao dịch"}
  },
  {
    "id": "54032f73-108e-41a2-8ba6-aa9de96ab47b",
    "name": "Mới",
    "group": {"id": "e393d663-2d80-4d2e-8472-6c7e36ce2d53", "name": "Chưa xác định"}
  },
  {
    "id": "6e852feb-e32b-40c7-9530-171bc2b38db8",
    "name": "Huỷ giao dịch",
    "group": {"id": "7504f2d7-c8af-41b5-9d7a-b327439cb1f7", "name": "Giao dịch"}
  },
  {
    "id": "7393c211-d4fc-48db-8091-ddd70aa9004a",
    "name": "Gửi thông tin",
    "group": {"id": "47ae12c7-8203-42c2-9374-85d05dca862e", "name": "Tiềm năng"}
  },
  {
    "id": "76580f68-d4e2-4566-a3ef-7b4f693ec084",
    "name": "Quan tâm",
    "group": {"id": "47ae12c7-8203-42c2-9374-85d05dca862e", "name": "Tiềm năng"}
  },
  {
    "id": "83d2fd99-2e15-4b27-ba7c-2157d4c02d7e",
    "name": "Đặt cọc",
    "group": {"id": "7504f2d7-c8af-41b5-9d7a-b327439cb1f7", "name": "Giao dịch"}
  },
  {
    "id": "8780f70c-db39-46bc-9354-184e8fbe3aaf",
    "name": "Sai số điện thoại",
    "group": {"id": "637c8daa-7bc8-4766-a254-2c2cfb449915", "name": "Không tiềm năng"}
  },
  {
    "id": "9b483dc8-a806-437a-be8f-8721b756508b",
    "name": "Không liên lạc được",
    "group": {"id": "637c8daa-7bc8-4766-a254-2c2cfb449915", "name": "Không tiềm năng"}
  },
  {
    "id": "9b6927e5-b6dc-4249-9e5f-1bab9750cd6c",
    "name": "Hẹn gặp",
    "group": {"id": "47ae12c7-8203-42c2-9374-85d05dca862e", "name": "Tiềm năng"}
  },
  {
    "id": "ae95f985-61ee-4fd9-b64c-53e1748c723e",
    "name": "Ký HĐMB",
    "group": {"id": "7504f2d7-c8af-41b5-9d7a-b327439cb1f7", "name": "Giao dịch"}
  },
  {
    "id": "e6a87dfa-a9dd-4c67-9a84-a9130ce12f9b",
    "name": "Không quan tâm",
    "group": {"id": "637c8daa-7bc8-4766-a254-2c2cfb449915", "name": "Không tiềm năng"}
  },
  {
    "id": "edd11358-a4c2-4b42-ab24-994a232a5eb8",
    "name": "Không bắt máy",
    "group": {"id": "e393d663-2d80-4d2e-8472-6c7e36ce2d53", "name": "Chưa xác định"}
  },
  {
    "id": "f0c1bd4f-a823-4521-b547-5eb0cf607f78",
    "name": "Tham quan dự án",
    "group": {"id": "47ae12c7-8203-42c2-9374-85d05dca862e", "name": "Tiềm năng"}
  },
  {
    "id": "f0c1bd4f-a823-4521-b547-5eb0cf607f79",
    "name": "Hẹn xem dự án",
    "group": {"id": "47ae12c7-8203-42c2-9374-85d05dca862e", "name": "Tiềm năng"}
  },
  {
    "id": "fb0d9904-2d5a-4b2c-9d35-c1c13838d5ba",
    "name": "Gọi lại sau",
    "group": {"id": "e393d663-2d80-4d2e-8472-6c7e36ce2d53", "name": "Chưa xác định"}
  }
];

const String defaultAvatar =
    "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";

bool isVersionOlder(String currentVersion, String newVersion) {
  List<int> currentVersionNumbers = currentVersion.split('.').map(int.parse).toList();

  List<int> newVersionNumbers = newVersion.split('.').map(int.parse).toList();

  // So sánh từng phần tử từ trái sang phải

  for (int i = 0; i < currentVersionNumbers.length; i++) {
    if (currentVersionNumbers[i] < newVersionNumbers[i]) {
      return true; // Phiên bản hiện tại nhỏ hơn phiên bản mới
    } else if (currentVersionNumbers[i] > newVersionNumbers[i]) {
      return false; // Phiên bản hiện tại lớn hơn phiên bản mới
    }

    // Nếu bằng nhau, tiếp tục so sánh phần tử tiếp theo
  }

  // Nếu đã so sánh hết mà không có kết quả, có thể là hai phiên bản giống nhau

  return false;
}

void hideKeyboard(BuildContext context) {
  FocusScopeNode currentFocus = FocusScope.of(context);

  if (!currentFocus.hasPrimaryFocus) {
    currentFocus.unfocus();
  }
}

bool isSuccessStatus(int number) {
  if (number == 0 || (number >= 200 && number <= 299)) {
    return true;
  } else {
    return false;
  }
}

Future<List<dynamic>?> fetchOrganList() async {
  final res = await OrganizationRepository(ApiClient()).getOrganizations();

  if (isSuccessStatus(res['code'])) {
    return res['content'];
  } else {
    errorAlert(title: 'Lỗi', desc: res['message']);
    return null;
  }
}

String diffFunc(DateTime dt2) {
  Duration diff = DateTime.now().difference(dt2);

  int timestamp = dt2.millisecondsSinceEpoch;

  if (diff.inDays < 1) {
    return timeStampToHour(timestamp);
  } else {
    return timeStampToDayMonth(timestamp);
  }
}

// ImageProvider getAvatarProvider(imgData) {
//   return imgData?.contains("https") ?? false
//       ? CachedNetworkImageProvider(
//           imgData,
//         )
//       : CachedNetworkImageProvider('${apiBaseUrl.replaceFirst("dev", "api")}$imgData');
// }

// Widget getAvatarWidget(imgData) {
//   return imgData?.contains("https") ?? false
//       ? CachedNetworkImage(
//           fit: BoxFit.cover,
//           errorWidget: (context, url, error) => const Icon(Icons.error),
//           imageUrl: imgData,
//         )
//       : CachedNetworkImage(
//           fit: BoxFit.cover,
//           errorWidget: (context, url, error) => const Icon(Icons.error),
//           imageUrl: '${apiBaseUrl.replaceFirst("dev", "api")}$imgData',
//         );
// }

Future<String?> getDeviceId() async {
  var deviceInfo = DeviceInfoPlugin();

  if (Platform.isIOS) {
    var iosDeviceInfo = await deviceInfo.iosInfo;

    return iosDeviceInfo.identifierForVendor; // unique ID on iOS
  } else if (Platform.isAndroid) {
    var androidDeviceInfo = await deviceInfo.androidInfo;

    return androidDeviceInfo.id; // unique ID on Android
  }

  return null;
}

bool isAdminOrOwner(homeController) {
  return (homeController.workGroupCardDataValue["type"] == "ADMIN" ||
      homeController.workGroupCardDataValue["type"] == "OWNER" ||
      homeController.oData["type"] == "ADMIN" ||
      homeController.oData["type"] == "OWNER");
}

// Future checkToken({Function? onDone}) async {
//   final prefs = await SharedPreferences.getInstance();

//   final String? refreshToken = prefs.getString("refreshToken");

//   try {
//     await AuthApi().refreshToken(refreshToken).then((res) async {
//       if (isSuccessStatus(res["code"])) {
//         prefs.setString("refreshToken", res["content"]["refreshToken"]);

//         prefs.setString("accessToken", res["content"]["accessToken"]);

//         onDone!();
//       } else if (res?["message"]?.contains("accessToken") ||
//           res?["message"]?.contains("Refresh Token") ||
//           res?["message"]?.contains("refreshToken") ||
//           res?["message"]?.contains("RefreshToken")) {
//         prefs.clear();

//         UserApi().updateFcmToken({
//           "deviceId": await getDeviceId(),
//           "version": await getVersion(),
//           "fcmToken": await FirebaseMessaging.instance.getToken(),
//           "status": 0
//         });

//         await FirebaseMessaging.instance.deleteToken();

//         Get.back();

//         Get.offAllNamed("/login");
//       }
//     });
//   } catch (e) {}
// }

Future getVersion() async {
  final prefs = await SharedPreferences.getInstance();

  return prefs.getString('version');
}

Future getOData() async {
  final organList = await fetchOrganList();
  // final prefs = await SharedPreferences.getInstance();
  if (organList == null || organList.isEmpty) {
    return Future.error('No organizations found');
  }

  return organList[0];
}

Future getAccessToken() async {
  const storage = FlutterSecureStorage();
  final token = await storage.read(key: 'access_token');
  return token ?? '';
}

Future getRefreshToken() async {
  final prefs = await SharedPreferences.getInstance();

  return prefs.getString('refreshToken');
}

// Future checkValidToken() async {
//   var res = await UserApi().getProfile();

//   final prefs = await SharedPreferences.getInstance();

//   if (res.toString() == 'null') {
//     prefs.clear();

//     return Get.offAllNamed('/login');
//   }

//   if (!isSuccessStatus(res['code'])) {
//     var refreshToken = await getRefreshToken();

//     AuthApi().refreshToken(refreshToken).then((res) async {
//       if (res['code'] == 0) {
//         prefs.setString('accessToken', res['content']['accessToken']);

//         prefs.setString('refreshToken', res['content']['refreshToken']);
//       } else if (res?["message"]?.contains("accessToken")) {
//         Get.offAllNamed('/login');
//       }
//     });
//   }
// }

Map groupDataByProvider(Map jsonData) {
  final Map dataByProvider = {};

  final List<Map<String, dynamic>> dataList = List<Map<String, dynamic>>.from(jsonData['content']);

  for (final Map<String, dynamic> data in dataList) {
    final String provider = (data['provider'] as String).toLowerCase();

    if (!dataByProvider.containsKey(provider)) {
      dataByProvider[provider] = <Map<String, dynamic>>[];
    }

    dataByProvider[provider]!.add(data);
  }

  return dataByProvider;
}

String getEmployee(String str) {
  if (str.toLowerCase() == "owner") {
    return "Chủ sở hữu";
  }

  if (str.toLowerCase() == "admin") {
    return "Quản trị viên";
  }

  if (str.toLowerCase() == "member") {
    return "Thành viên";
  }

  if (str.toLowerCase() == "fulltime") {
    return "Nhân viên";
  }

  if (str.toLowerCase() == "collaborator") {
    return "Công tác viên";
  }

  return "";
}

void updatePersonAvatarList(List objectList) {
  objectList.map((object) {
    String avatar = object["avatar"] ?? defaultAvatar;

    if (avatar.contains("https") || avatar.contains("theme")) {
      object["personAvatar"] = avatar;

      return object;
    }

    object["personAvatar"] = avatar;

    return object;
  }).toList();
}

void updatePageAvatarList(List objectList) {
  objectList.map((object) {
    String avatar = object["pageAvatar"] ?? defaultAvatar;

    object["pageAvatar"] = avatar;

    return object;
  }).toList();
}

String timeStampToHour(int timestamp) {
  DateTime date = DateTime.fromMillisecondsSinceEpoch(timestamp);

  String formattedTime = DateFormat('HH:mm').format(date);

  return formattedTime;
}

String timeStampToDate(int timestamp) {
  DateTime date = DateTime.fromMillisecondsSinceEpoch(timestamp);

  String formattedDate = DateFormat('dd/MM/yy', 'vi_VN').format(date);

  return formattedDate;
}

String timeStampToDayMonth(int timestamp) {
  DateTime date = DateTime.fromMillisecondsSinceEpoch(timestamp);

  String formattedDate = DateFormat('dd/MM', 'vi_VN').format(date);

  return formattedDate;
}

Map<String, int> getCounts(dataList) {
  Map<String, int> countMap = {
    'ALL': 0,
    'FORM': 0,
    'MESSAGE': 0,
    'AIDC': 0,
  };

  for (var item in dataList) {
    if (item['unreadCount'] > 0) {
      countMap['ALL'] = (countMap['ALL'] ?? 0) + 1;

      if (item['FORM'] == 'FORM') {
        countMap['FORM'] = (countMap['FORM'] ?? 0) + 1;
      } else if (item['type'] == 'MESSAGE') {
        countMap['MESSAGE'] = (countMap['MESSAGE'] ?? 0) + 1;
      } else if (item['type'] == 'AIDC') {
        countMap['AIDC'] = (countMap['AIDC'] ?? 0) + 1;
      }
    }
  }

  return countMap;
}

List<Map<String, dynamic>> formatOrList(List<dynamic> input) {
  List<Map<String, dynamic>> result = [];

  for (var item in input) {
    Map<String, dynamic> condition = {
      'conditions': [],
    };

    for (var i2 in item) {
      var currentCondition = i2['currentCondition'];

      var currentValue = i2['filterText'];

      var currentAction = i2['currentAction'];

      Map<String, dynamic> condition1 = {
        'key': currentAction['data'],
        'value': currentValue,
        'match': currentCondition['id'].replaceAll("not_", ""),
        'isNegative': currentCondition['id'].contains("not_") ? true : false,
      };

      condition['conditions'].add(condition1);
    }

    result.add(condition);
  }

  return result;
}

Map minimizeData(String jsonData) {
  var data = json.decode(jsonData);

  // Rút gọn dữ liệu trong đối tượng "content"

  var contentData = data;

  var minimizedData = {};

  contentData.forEach((key, value) {
    if (value is List) {
      for (var i = 0; i < value.length; i++) {
        var item = value[i];

        item.forEach((subKey, subValue) {
          var newKey = '$key[$i].$subKey';

          minimizedData[newKey] = subValue;
        });
      }
    } else if (value is Map) {
      value.forEach((subKey, subValue) {
        var newKey = '$key.$subKey';

        minimizedData[newKey] = subValue;
      });
    } else {
      var newKey = '$key';

      minimizedData[newKey] = value;
    }
  });

  print(minimizedData);

  return minimizedData;
}

String convertIndexToAlphabet(int index) {
  const int asciiOffset = 65; // Giá trị ASCII của ký tự 'A'

  if (index < 0 || index >= 26) {
    throw ArgumentError('Invalid index');
  }

  return String.fromCharCode(index + asciiOffset);
}

List<int> generateList(int n) {
  List<int> resultList = [];

  for (int i = 0; i < n; i++) {
    resultList.add(i);
  }

  return resultList;
}

String replaceKeyToId(data) {
  return "";
}

String staticURLFromURLString(String urlString) {
  try {
    Uri uri = Uri.parse(urlString);

    return uri.origin + uri.path;
  } catch (e) {
    return urlString;
  }
}

Map<String, dynamic> compareMaps(Map<String, dynamic> map1, Map<String, dynamic> map2) {
  Map<String, dynamic> differences = {};

  map1.forEach((key, value1) {
    if (map2.containsKey(key) &&
        key != "Team" &&
        key != "Stage" &&
        key != "Source" &&
        key != "CreatedBy" &&
        key != "LastModifiedBy" &&
        key != "LastModifiedDate" &&
        key != "Additional") {
      final value2 = map2[key];

      if (value1 != value2) {
        differences[key] = [value1, value2];
      }
    }
  });

  return differences;
}

List<bool> compareCategories(List categoryMenu, List initData) {
  List<bool> result = [];

  for (int i = 0; i < categoryMenu.length; i++) {
    bool existsInInitData = false;

    for (int j = 0; j < initData.length; j++) {
      if (categoryMenu[i].id == initData[j].id) {
        existsInInitData = true;

        break;
      }
    }

    result.add(existsInInitData);
  }

  return result;
}

bool isValidId(String id) {
  return false;

  List<String> validIds = [
    "9f6cc8bb-85c4-4650-9baa-31a0325e1168",
    "9e0fd577-c5ee-4910-a1f9-46d08d9675d2",
    "daafc56d-a61a-49a9-93e7-85f7bd31a628",
    "01023bf4-e14f-47f0-8187-f13652058e0a",
    "39785678-cf69-4859-a139-81a8360f010f"
  ];

  return validIds.contains(id);
}
