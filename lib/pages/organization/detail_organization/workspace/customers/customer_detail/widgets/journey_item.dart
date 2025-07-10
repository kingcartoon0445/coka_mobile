import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_html_audio/flutter_html_audio.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:coka/shared/widgets/avatar_widget.dart';

String getIconPath(type, isSource) {
  if (isSource) {
    if (type == "FORM") {
      return "assets/images/form_icon.png";
    }
    if (type == "NHẬP VÀO") {
      return "assets/images/pencil.png";
    }
  }
  if (type == "UPDATE_RATING") {
    return "assets/images/review.png";
  }
  if (type == "CALL") {
    return "assets/images/journey_phone.png";
  }
  if (type == "UPDATE_AVATAR" || type == "UPDATE_INFO") {
    return "assets/images/pencil.png";
  }
  if (type == "UPDATE_STAGE" || type == "CREATE_NOTE") {
    return "assets/images/sticky-notes.png";
  }
  if (type == "UPDATE_ASSIGNTEAM" || type == "UPDATE_ASSIGNTO") {
    return "assets/images/change.png";
  }

  return "assets/images/bot.png";
}

String translateCallStatus(status) {
  if (status == "CANCEL") {
    return "Hủy cuộc gọi";
  }
  if (status == "ANSWER") {
    return "Thành công";
  }
  if (status == "BUSY") {
    return "Máy bận";
  }
  return "Không xác định";
}

Map<String, List<dynamic>> compareMaps(
    Map<String, dynamic> oldMap, Map<String, dynamic> newMap) {
  Map<String, List<dynamic>> differences = {};

  newMap.forEach((key, value) {
    if (oldMap[key] != value) {
      differences[key] = [oldMap[key], value];
    }
  });

  return differences;
}

String? getValue(String key, dynamic value) {
  if (value == null) return null;

  switch (key) {
    case "Gender":
      return value == 1 ? "Nam" : "Nữ";
    case "Phone":
      return value.toString().startsWith("84")
          ? "0${value.toString().substring(2)}"
          : value.toString();
    case "Dob":
      try {
        return DateFormat('dd/MM/yyyy').format(DateTime.parse(value));
      } catch (e) {
        return value;
      }
    default:
      return value.toString();
  }
}

String staticURLFromURLString(String url) {
  try {
    final uri = Uri.parse(url);
    return uri.host;
  } catch (e) {
    return url;
  }
}

String? getSubtitle(type, oldValue, newValue) {
  try {
    if (type == "UPDATE_RATING" || type == "UPDATE_AVATAR") {
      return null;
    }

    final oldData = jsonDecode(oldValue == "" ? "{}" : oldValue ?? "{}");
    final newData = jsonDecode(newValue == "" ? "{}" : newValue ?? "{}");

    if (type == "UPDATE_INFO") {
      final diff = compareMaps(oldData, newData);

      String htmlString = "";
      for (var x in diff.entries) {
        if (x.key == "FullName") {
          htmlString +=
              "Tên: <a>${x.value[0]}</a> sang <a>${x.value[1]}</a><br/>";
        } else if (x.key == "Phone") {
          htmlString +=
              "Số điện thoại: <a>${getValue(x.key, x.value[0])}</a> sang <a>${getValue(x.key, x.value[1])}</a><br/>";
        } else if (x.key == "Dob") {
          htmlString +=
              "Ngày sinh: <a>${getValue(x.key, x.value[0]) ?? "Chưa có"}</a> sang <a>${getValue(x.key, x.value[1])}</a><br/>";
        } else if (x.key == "Gender") {
          htmlString +=
              "Giới tính: <a>${getValue(x.key, x.value[0])}</a> sang <a>${getValue(x.key, x.value[1])}</a><br/>";
        } else if (x.key == "Email") {
          htmlString +=
              "Email: <a>${x.value[0] ?? "Chưa có"}</a> sang <a>${x.value[1]}</a><br/>";
        } else if (x.key == "Work") {
          htmlString +=
              "Nghề nghiệp: <a>${x.value[0] ?? "Chưa có"}</a> sang <a>${x.value[1]}</a><br/>";
        } else if (x.key == "Address") {
          htmlString +=
              "Nơi ở: <a>${x.value[0] ?? "Chưa có"}</a> sang <a>${x.value[1]}</a><br/>";
        } else if (x.key == "PhysicalId") {
          htmlString +=
              "CMND/CCCD: <a>${x.value[0] ?? "Chưa có"}</a> sang <a>${x.value[1]}</a><br/>";
        }
      }
      if (htmlString.length > 6) {
        htmlString = htmlString.replaceRange(
            htmlString.length - 6, htmlString.length - 1, "");
      }
      return htmlString;
    }
    if (type == "UPDATE_STAGE") {
      return "Sang: <a>${newData["Name"]}.</a>${newData["Note"] != "" && newData["Note"] != null ? "<br/>Nội dung: <a>${newData["Note"]}</a>" : ""}";
    }
    if (type == "CREATE_NOTE") return "\nNội dung: <a>${newData["Note"]}</a>";
    if (type == "UPDATE_ASSIGNTEAM") {
      return "<a>${newData["Team"]?["Name"] ?? "Sang: Nhóm làm việc"}</a>";
    }
    if (type == "UPDATE_ASSIGNTO") {
      return "<a>${newData["User"]["FullName"]}</a>";
    }
    if (type == "CALL") {
      return "<div class='column'>Trạng thái: <a>${translateCallStatus(newData["CallStatus"])}</a>${newData["RecordingFile"] != null && newData["RecordingFile"] != "" ? "\n<audio controls> <source src='${newData["RecordingFile"]}' type='audio/mpeg'>Audio</audio>" : ""}</div>";
    }
  } catch (e) {
    print(e);
  }

  return null;
}

String _getTimeAgo(DateTime date) {
  final now = DateTime.now();
  final difference = now.difference(date);

  if (difference.inDays > 0) {
    return '${difference.inDays} ngày trước';
  } else if (difference.inHours > 0) {
    return '${difference.inHours} giờ trước';
  } else if (difference.inMinutes > 0) {
    return '${difference.inMinutes} phút trước';
  } else {
    return 'Vừa xong';
  }
}

class JourneyItem extends StatelessWidget {
  final Map<String, dynamic> dataItem;
  final bool isLast;

  const JourneyItem({
    super.key,
    required this.dataItem,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final date = DateTime.parse(dataItem['date']);
    final snipTime = _getTimeAgo(date);
    final fullTime = DateFormat('dd-MM-yyyy HH:mm:ss').format(date);

    final isSource = dataItem["type"] == "SOURCE";
    final type =
        isSource ? dataItem["data"]["sourceName"] : dataItem["data"]["type"];
    final title = dataItem["data"]["title"] ??
        "Data được thêm vào bởi ${dataItem["data"]["sourceName"]}";

    final oldValue = dataItem["data"]["oldValue"];
    final newValue = dataItem["data"]["newValue"];
    final noteText = dataItem["data"]["note"];

    final utmSrc = dataItem["data"]["utmSource"]?.toUpperCase();
    final website = dataItem["data"]["website"];
    String subTitle = getSubtitle(type, oldValue, newValue) ??
        ((utmSrc == null || utmSrc == "") ? "" : "Nguồn: <a>$utmSrc</a>");

    if (website != null && website != '') {
      subTitle +=
          "</br>Đích: <a href='$website'>${staticURLFromURLString(website)}</a>";
    }
    if (noteText != null && noteText != '') {
      subTitle += "</br>Nội dung: <a>$noteText</a>";
    }

    final name = dataItem["createdBy"]["fullName"];
    final avatar = dataItem["createdBy"]["avatar"];
    final iconPath = getIconPath(type?.toUpperCase(), isSource);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Stack(
        children: [
          if (!isLast)
            Positioned(
              left: 20,
              top: 40,
              bottom: 0,
              child: Container(
                width: 1,
                color: const Color(0x66000000),
              ),
            ),
          Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Column(
                    children: [
                      CircleAvatar(
                        backgroundColor: const Color(0xFFE3DFFF),
                        radius: 20,
                        child: Image.asset(iconPath, width: 24, height: 24),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 50),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: 2),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      title,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF1F2329),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Tooltip(
                                    message: fullTime,
                                    triggerMode: TooltipTriggerMode.tap,
                                    waitDuration: const Duration(seconds: 2),
                                    child: Text(
                                      snipTime,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (subTitle.isNotEmpty)
                                    SizedBox(
                                      width: double.infinity,
                                      child: Material(
                                        color: Colors.transparent,
                                        child: Html(
                                          data: "<p>$subTitle</p>",
                                          onLinkTap:
                                              (url, attributes, element) async {
                                            if (url != null &&
                                                url.contains("http")) {
                                              if (!await launchUrl(
                                                  Uri.parse(url))) {
                                                throw Exception(
                                                    'Could not launch $url');
                                              }
                                            }
                                          },
                                          extensions: const [
                                            AudioHtmlExtension(),
                                          ],
                                          style: {
                                            "body": Style(margin: Margins.zero),
                                            ".column": Style(
                                              display: Display.block,
                                              backgroundColor: Colors.transparent,
                                            ),
                                            "a": Style(
                                              textDecoration: TextDecoration.none,
                                              color: const Color(0xFF554FE8),
                                              fontWeight: FontWeight.bold,
                                            ),
                                            "p": Style(
                                              padding: HtmlPaddings.zero,
                                              margin:
                                                  Margins.symmetric(vertical: 2),
                                            ),
                                          },
                                        ),
                                      ),
                                    ),
                                  if (type == "UPDATE_RATING")
                                    Padding(
                                      padding: const EdgeInsets.only(left: 8.0),
                                      child: RatingBar.builder(
                                        initialRating:
                                            double.parse(newValue ?? "0"),
                                        itemBuilder: (context, _) => const Icon(
                                          Icons.star,
                                          color: Color(0xFFF27B21),
                                        ),
                                        itemSize: 20,
                                        onRatingUpdate: (value) {},
                                        ignoreGestures: true,
                                      ),
                                    ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Spacer(),
                                      Text(
                                        name,
                                        style: const TextStyle(
                                          color: Colors.black54,
                                          fontSize: 10,
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      AppAvatar(
                                        imageUrl: avatar,
                                        fallbackText: name,
                                        size: 18,
                                        fallbackTextColor: Colors.black87,
                                        fallbackBackgroundColor: Colors.grey[300],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ],
      ),
    );
  }
}
