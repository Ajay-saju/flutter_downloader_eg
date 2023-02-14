import 'dart:io';
import 'dart:isolate';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';

class OffLineList extends StatefulWidget {
  const OffLineList({super.key});

  @override
  State<OffLineList> createState() => _OffLineListState();
}

class _OffLineListState extends State<OffLineList> {
  List<Map> downloadsListMaps = [];
  ReceivePort port = ReceivePort();
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    task();
    bindBackgroundIsolate();
    FlutterDownloader.registerCallback(downloadCallback);
  }

  @override
  void dispose() {
    unbindBackgroundIsolate();
    // TODO: implement dispose
    super.dispose();
  }

  Future task() async {
    List<DownloadTask>? getTasks = await FlutterDownloader.loadTasks();
    getTasks!.forEach((task) {
      Map map = {};
      map['status'] = task.status;
      map['progress'] = task.progress;
      map['id'] = task.taskId;
      map['filename'] = task.filename;
      map['savedDirectory'] = task.savedDir;
      downloadsListMaps.add(map);
    });
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Offline Downloads'),
      ),
      body: downloadsListMaps.isEmpty
          ? const Center(
              child: Text("No Downloads yet"),
            )
          : ListView.builder(
              itemCount: downloadsListMaps.length,
              itemBuilder: (context, int i) {
                Map _map = downloadsListMaps[i];
                String? fileName = _map['filename'];
                int progress = _map['progress'];
                DownloadTaskStatus status = _map['status'];
                String id = _map['id'];
                String saveDir = _map['savedDirectory'];
                List<FileSystemEntity> directories =
                    Directory(saveDir).listSync(followLinks: true);
                FileSystemEntity? file =
                    directories.isNotEmpty ? directories.first : null;
                return GestureDetector(
                  onTap: () {
                    if (status == DownloadTaskStatus.complete) {
                      showDialg(file!);
                    }
                  },
                  child: Card(
                    elevation: 10,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          isThreeLine: false,
                          title: Text(fileName.toString()),
                          subtitle: downloadStatusWidget(status),
                          trailing: SizedBox(
                            child: buttons(status, id, i),
                            width: 60,
                          ),
                        ),
                        status == DownloadTaskStatus.complete
                            ? Container()
                            : SizedBox(height: 5),
                        status == DownloadTaskStatus.complete
                            ? Container()
                            : Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  children: [
                                    Text('$progress%'),
                                    Row(
                                      children: [
                                        Expanded(
                                            child: LinearProgressIndicator(
                                          value: progress / 100,
                                        ))
                                      ],
                                    )
                                  ],
                                ),
                              ),
                        SizedBox(height: 10)
                      ],
                    ),
                  ),
                );
              }),
    );
  }

  Widget downloadStatusWidget(DownloadTaskStatus status) {
    return status == DownloadTaskStatus.canceled
        ? const Text('Download canceled')
        : status == DownloadTaskStatus.complete
            ? const Text('Download Completed')
            : status == DownloadTaskStatus.failed
                ? const Text('Download failed')
                : status == DownloadTaskStatus.paused
                    ? const Text('Download paused')
                    : status == DownloadTaskStatus.running
                        ? const Text('Downloading...')
                        : const Text('Download waiting');
  }

  Widget buttons(DownloadTaskStatus status, String taskId, int index) {
    void changeTaskID(String taskid, String newTaskID) {
      Map task = downloadsListMaps.firstWhere(
        (element) => element['taskId'] == taskId,
        orElse: () => {},
      );
      task['taskId'] = newTaskID;
      setState(() {});
    }

    return status == DownloadTaskStatus.canceled
        ? GestureDetector(
            onTap: () {
              FlutterDownloader.retry(taskId: taskId)
                  .then((newTaskId) => changeTaskID(taskId, newTaskId!));
            },
            child: Icon(Icons.cached, size: 20, color: Colors.green))
        : status == DownloadTaskStatus.failed
            ? GestureDetector(
                onTap: () {
                  FlutterDownloader.retry(taskId: taskId).then((newTaskID) {
                    changeTaskID(taskId, newTaskID!);
                  });
                },
                child: Icon(Icons.cached, size: 20, color: Colors.green))
            : status == DownloadTaskStatus.paused
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () {
                          FlutterDownloader.resume(taskId: taskId)
                              .then((newTaskId) {
                            changeTaskID(taskId, newTaskId!);
                          });
                        },
                        child: Icon(Icons.play_arrow,
                            size: 20, color: Colors.blue),
                      ),
                      GestureDetector(
                          onTap: () {
                            FlutterDownloader.cancel(taskId: taskId);
                          },
                          child:
                              Icon(Icons.close, size: 20, color: Colors.red)),
                    ],
                  )
                : status == DownloadTaskStatus.running
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            child: Icon(Icons.pause,
                                size: 20, color: Colors.green),
                            onTap: () {
                              FlutterDownloader.pause(taskId: taskId);
                            },
                          ),
                          GestureDetector(
                              onTap: () {
                                FlutterDownloader.cancel(taskId: taskId);
                              },
                              child: Icon(Icons.close,
                                  size: 20, color: Colors.red)),
                        ],
                      )
                    : status == DownloadTaskStatus.complete
                        ? GestureDetector(
                            onTap: () {
                              downloadsListMaps.removeAt(index);
                              FlutterDownloader.remove(
                                  taskId: taskId, shouldDeleteContent: true);
                              setState(() {});
                            },
                            child:
                                Icon(Icons.delete, size: 20, color: Colors.red))
                        : Container();
  }

  void bindBackgroundIsolate() {
    bool isSuccess = IsolateNameServer.registerPortWithName(
        port.sendPort, 'downloader_send_port');
    if (!isSuccess) {
      unbindBackgroundIsolate();
      bindBackgroundIsolate();
      return;
    }
    port.listen((dynamic data) {
      String id = data[0];
      DownloadTaskStatus status = data[1];
      int progress = data[2];
      var task = downloadsListMaps.where((element) => element['id'] == id);
      task.forEach((element) {
        element['progress'] = progress;
        element['status'] = status;
        setState(() {});
      });
    });
  }

  static void downloadCallback(
      String id, DownloadTaskStatus status, int progress) {
    final SendPort? send =
        IsolateNameServer.lookupPortByName('downloader_send_port');
    send!.send([id, status, progress]);
  }

  void unbindBackgroundIsolate() {
    IsolateNameServer.removePortNameMapping('downloader_send_port');
  }

  showDialg(FileSystemEntity file) {
    return showDialog(
        context: context,
        builder: (context) {
          return Dialog(
            child: Container(
              child: Text("OK"),
            ),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(8))),
          );
        });
  }
}
