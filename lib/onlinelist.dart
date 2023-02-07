import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:flutter_downloader/flutter_downloader.dart';

class OffLineList extends StatefulWidget {
  const OffLineList({super.key});

  @override
  State<OffLineList> createState() => _OffLineListState();
}

class _OffLineListState extends State<OffLineList> {
  List<Map> downloadsListMaps = [];
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
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
      body: downloadsListMaps.length == 0
          ? Center(
              child: Text("No Downloads yet"),
            )
          : Container(
              child: ListView.builder(itemBuilder: (context, int i) {
                Map map = downloadsListMaps[i];
                String fileName = map['filename'];
                int progress = map['progress'];
                DownloadTaskStatus status = map['status'];
                String id = map['id'];
                String saveDir = map['savedDirectory'];
                return Card(
                  elevation: 10,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        isThreeLine: false,
                        title: Text(fileName.toString()),
                        subtitle: downloadStatusWidget(status),
                      )
                    ],
                  ),
                );
              }),
            ),
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
    return status== DownloadTaskStatus.canceled ?
    GestureDetector(
      onTap: (){
        FlutterDownloader.retry(taskId: taskId).then((newTaskId) => changeTaskID(taskId, newTaskId!));
      },
      child: Icon(Icons.cached, size: 20, color: Colors.green)):status==DownloadTaskStatus.failed? GestureDetector(
        onTap: (){
          FlutterDownloader.retry(taskId: taskId).then((newTaskID) {changeTaskID(taskid, newTaskID);} )
        },
        child: Icon(Icons.cached, size: 20, color: Colors.green)):,
  }
}
