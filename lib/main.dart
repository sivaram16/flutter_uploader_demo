import 'dart:io';

import 'package:background_uploader_demo/uploader.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_uploader/flutter_uploader.dart';

void backGroundHandler() {
  WidgetsFlutterBinding.ensureInitialized();
  final notifications = FlutterLocalNotificationsPlugin();
  if (Platform.isAndroid) {
    BackgroundUploader.uploader.progress.listen((progress) {
      notifications.show(
        progress.taskId.hashCode,
        'DemoApp',
        'Upload in Progress',
        NotificationDetails(
          android: AndroidNotificationDetails(
            'DemoTestChannel',
            'High Importance Notifications',
            progress: progress.progress ?? 0,
            icon: 'ic_launcher',
            enableVibration: false,
            importance: Importance.high,
            showProgress: true,
            onlyAlertOnce: true,
            maxProgress: 100,
            channelShowBadge: false,
          ),
          iOS: const IOSNotificationDetails(),
        ),
      );
    });
  }
  BackgroundUploader.uploader.result.listen((result) {
    notifications.cancel(result.taskId.hashCode);

    final successful = result.status == UploadTaskStatus.complete;

    String title = 'Upload Complete';
    if (result.status == UploadTaskStatus.failed) {
      title = 'Upload Failed';
    } else if (result.status == UploadTaskStatus.canceled) {
      title = 'Upload Canceled';
    }

    notifications
        .show(
          result.taskId.hashCode,
          'DemoApp',
          title,
          NotificationDetails(
            android: AndroidNotificationDetails(
              'DemoTestChannel',
              'High Importance Notifications',
              icon: 'ic_launcher',
              enableVibration: !successful,
              importance: result.status == UploadTaskStatus.failed
                  ? Importance.high
                  : Importance.min,
            ),
            iOS: const IOSNotificationDetails(
              presentAlert: true,
            ),
          ),
        )
        .catchError((e, stack) {});
  });
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  notificationListerner();
  runApp(const MyApp());
}

void notificationListerner() {
  BackgroundUploader.uploader.setBackgroundHandler(backGroundHandler);

  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  const initializationSettingsAndroid =
      AndroidInitializationSettings('ic_launcher');
  final initializationSettingsIOS = IOSInitializationSettings(
    requestSoundPermission: false,
    requestBadgePermission: false,
    onDidReceiveLocalNotification:
        (int id, String? title, String? body, String? payload) async {},
  );
  final initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid, iOS: initializationSettingsIOS);
  flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onSelectNotification: (payload) async {},
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  File? file;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Background Uploader Demo"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(onPressed: pickFile, child: const Text("Pick File")),
            const SizedBox(height: 40),
            if (file != null) Text(file!.path),
            const SizedBox(height: 40),
            ElevatedButton(
                onPressed: uploadFile, child: const Text("Upload File"))
          ],
        ),
      ),
    );
  }

  pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      setState(() {
        file = File(result.files.single.path!);
      });
    }
  }

  uploadFile() async {
    _prepareMediaUploadListener();
    String? taskId = await BackgroundUploader.uploadEnqueue(file!);
    if (taskId != null) {
    } else {
      BackgroundUploader.uploader.cancelAll();
    }
  }

  static void _prepareMediaUploadListener() {
    //listen
    BackgroundUploader.uploader.result.listen((UploadTaskResponse response) {
      BackgroundUploader.uploader.clearUploads();

      if (response.status == UploadTaskStatus.complete) {
      } else if (response.status == UploadTaskStatus.canceled) {
        BackgroundUploader.uploader.cancelAll();
      }
    }, onError: (error) {
      //handle failure
      BackgroundUploader.uploader.cancelAll();
    });
  }
}
