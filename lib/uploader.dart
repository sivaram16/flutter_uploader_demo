import 'dart:async';
import 'dart:io';

import 'package:flutter_uploader/flutter_uploader.dart';

class BackgroundUploader {
  BackgroundUploader._();

  static final uploader = FlutterUploader();

  static Future<String?> uploadEnqueue(File file) async {
    final String? taskId = await uploader.enqueue(
      MultipartFormDataUpload(
        url: 'YOUR_URL',
        method: UploadMethod.POST,
        headers: {"Authorization": "YOUR_TOKEN"},
        files: [FileItem(path: file.path, field: "file")],
        tag: "Media Uploading",
      ),
    );

    return taskId;
  }
}
