import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

Future<void> requestStoragePermission() async {
  // Với Android 13 trở lên, nên xin quyền tương ứng
  if (await Permission.storage.isGranted) {
    print('Đã có quyền lưu trữ');
    return;
  }

  var status = await Permission.storage.request();

  if (status.isGranted) {
    print('Quyền được cấp');
  } else if (status.isDenied) {
    print('Người dùng từ chối quyền');
  } else if (status.isPermanentlyDenied) {
    print('Quyền bị từ chối vĩnh viễn - mở cài đặt');
    openAppSettings();
  }
}

Future<void> downloadFile(BuildContext context, String url, String fileName) async {
  final dio = Dio();

  // Yêu cầu quyền lưu trữ (nếu cần - Android)
  if (Platform.isAndroid) {
    var status = await Permission.storage.request();
    if (!status.isGranted) {
      // ScaffoldMessenger.of(context).showSnackBar(
      //   const SnackBar(content: Text('Bạn cần cấp quyền lưu trữ')),
      // );
      requestStoragePermission();
    }
  }

  try {
    // Lấy thư mục tải xuống

    Directory? downloadsDir;
    if (Platform.isAndroid) {
      downloadsDir =
          Directory('/storage/emulated/0/Download'); // Đường dẫn thư mục Downloads thật sự
    } else if (Platform.isIOS) {
      downloadsDir = await getApplicationDocumentsDirectory(); // iOS không có thư mục Downloads
    }

    final savePath = '${downloadsDir!.path}/$fileName';

    // Bắt đầu tải xuống
    await dio.download(
      url,
      savePath,
      onReceiveProgress: (received, total) {
        if (total != -1) {
          double progress = received / total * 100;
          print('Downloading: ${progress.toStringAsFixed(0)}%');
        }
      },
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Tải xuống hoàn tất: $savePath'),
        action: SnackBarAction(
          label: 'MỞ',
          onPressed: () {
            OpenFile.open(savePath);
          },
        ),
      ),
    );
  } catch (e) {
    print('Download failed: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Lỗi khi tải xuống')),
    );
  }
}
