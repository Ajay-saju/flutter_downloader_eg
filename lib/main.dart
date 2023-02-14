// ignore_for_file: unrelated_type_equality_checks

import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:dowloader/homepage.dart';
import 'package:dowloader/onlinelist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await FlutterDownloader.initialize(
      debug:
          true, // optional: set to false to disable printing logs to console (default: true)
      ignoreSsl:
          true // option: set to false to disable working with http links (default: false)
      );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget with WidgetsBindingObserver {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final urls = [
    "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4",
    "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4",
    "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4",
    "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4",
  ];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListView.builder(
            itemCount: urls.length,
            itemBuilder: (context, int i) {
              String fileName = 'File ${i + 1}';
              return Card(
                elevation: 10,
                child: Column(
                  children: [
                    const SizedBox(
                      height: 10,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(fileName),
                        ),
                        RawMaterialButton(
                          textStyle: const TextStyle(color: Colors.blueGrey),
                          onPressed: () => requiestDownload(urls[i], fileName),
                          child: const Icon(Icons.file_download),
                        )
                      ],
                    )
                  ],
                ),
              );
            }),
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const OffLineList(),
            ),
          );
        },
        // tooltip: 'download',
        label: const Text(
          'Downloads',
        ),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  Future<bool> _checkPermission() async {
    if (Platform.isIOS) {
      return true;
    }

    if (Platform.isAndroid) {
      final info = await DeviceInfoPlugin().androidInfo;
      if (info.version.sdkInt > 28) {
        return true;
      }

      final status = await Permission.storage.status;
      if (status == PermissionStatus.granted) {
        return true;
      }

      final result = await Permission.storage.request();
      return result == PermissionStatus.granted;
    }

    throw StateError('unknown platform');
  }

  Future<void> requiestDownload(String url, String name) async {
    final dir = await getApplicationDocumentsDirectory();
    var local_path = dir.path + name;
    final saveDir = Directory(local_path);
    await saveDir.create(recursive: true).then((value) async {
      String? taskId = await FlutterDownloader.enqueue(
          url: url,
          savedDir: local_path,
          showNotification: true,
          openFileFromNotification: true);
      print(taskId);
    });
  }
}
