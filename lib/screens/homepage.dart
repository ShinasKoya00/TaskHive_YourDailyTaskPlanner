import 'dart:convert';
import 'dart:developer';
import 'package:daily_planner_flutter_app/widgets/circular_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/task.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  late TextEditingController _taskController;
  late List<Task> _tasks;
  late List<bool> _taskDone;

  late AnimationController animationController;
  late Animation<double> degOneTranslationAnimation, degTwoTranslationAnimation, degThreeTranslationAnimation;
  late Animation<double> rotationAnimation;

  double getRadianFromDegree(double degree) {
    double unitRadian = 57.2958;
    return degree / unitRadian;
  }

  Future<void> saveData() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();

    Task t = Task.fromString(_taskController.text);
    String? tasks = preferences.getString('task');
    List<dynamic> taskList = (tasks != null) ? json.decode(tasks) : [];
    taskList.add(json.encode(t.getMap()));
    preferences.setString('task', json.encode(taskList));
    _taskController.clear();
    log(taskList.toString());
    if (mounted) {
      Navigator.of(context).pop();
    }
    _getTasks();
  }

  void _getTasks() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    String? tasks = preferences.getString('task');
    List<dynamic> taskList = (tasks != null) ? json.decode(tasks) : [];
    _tasks = taskList.map((task) => Task.fromMap(json.decode(task))).toList();
    _taskDone = List.generate(_tasks.length, (index) => false);
    setState(() {});
  }

  void updatePendingTaskList() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    List<Task> pendingList = [];
    for (var i = 0; i < _tasks.length; i++) {
      if (!_taskDone[i]) {
        pendingList.add(_tasks[i]);
      }
    }
    var pendingListEncoded = List.generate(
      pendingList.length,
      (i) => json.encode(pendingList[i].getMap()),
    );
    preferences.setString('task', json.encode(pendingListEncoded));
    _getTasks();
  }

  void _deleteAllTask() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    preferences.setString('task', json.encode([]));
    _getTasks();
  }

  @override
  void initState() {
    super.initState();
    _taskController = TextEditingController();
    _tasks = [];
    _taskDone = [];
    _getTasks();
    animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    degOneTranslationAnimation = TweenSequence([
      TweenSequenceItem<double>(tween: Tween<double>(begin: 0.0, end: 1.2), weight: 75.0),
      TweenSequenceItem<double>(tween: Tween<double>(begin: 1.2, end: 1.0), weight: 25.0),
    ]).animate(animationController);
    degTwoTranslationAnimation = TweenSequence([
      TweenSequenceItem<double>(tween: Tween<double>(begin: 0.0, end: 1.4), weight: 50.0),
      TweenSequenceItem<double>(tween: Tween<double>(begin: 1.4, end: 1.0), weight: 50.0),
    ]).animate(animationController);
    degThreeTranslationAnimation = TweenSequence([
      TweenSequenceItem<double>(tween: Tween<double>(begin: 0.0, end: 1.7), weight: 25.0),
      TweenSequenceItem<double>(tween: Tween<double>(begin: 1.7, end: 1.0), weight: 75.0),
    ]).animate(animationController);
    rotationAnimation = Tween(begin: 180.0, end: 0.0)
        .animate(CurvedAnimation(parent: animationController, curve: Curves.easeOut));
    animationController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _taskController.dispose(); // Fixed call to dispose method
    animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    Color primaryPurple = const Color.fromARGB(255, 235, 221, 255);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "TaskHive: Your Daily Task Planner",
          style: TextStyle(fontSize: 21, fontWeight: FontWeight.w500),
        ),
        centerTitle: true,
        backgroundColor: primaryPurple,
      ),
      body: Stack(
        children: [
          (_tasks.isEmpty)
              ? const Center(child: Text("No tasks yet!"))
              : ListView(
                  children: _tasks
                      .map(
                        (e) => Container(
                          height: 70,
                          width: width,
                          margin: const EdgeInsets.only(left: 15, right: 15, top: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                          alignment: Alignment.centerLeft,
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.black)),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                e.task!,
                                style: const TextStyle(fontSize: 17),
                              ),
                              Checkbox(
                                value: _taskDone[_tasks.indexOf(e)],
                                onChanged: (val) {
                                  setState(() {
                                    _taskDone[_tasks.indexOf(e)] = val!;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
          Positioned(
            bottom: 15,
            right: 15,
            child: SizedBox(
              height: height,
              width: width,
              child: Stack(
                alignment: Alignment.bottomRight,
                children: <Widget>[
                  addTaskButton(primaryPurple, context, width),
                  saveTaskButton(primaryPurple),
                  deleteTaskButton(primaryPurple),
                  moreTaskButton(primaryPurple),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Transform moreTaskButton(Color primaryPurple) {
    return Transform(
      transform: Matrix4.rotationZ(getRadianFromDegree(rotationAnimation.value)),
      alignment: Alignment.center,
      child: CircularFloatingButton(
        height: 55,
        width: 55,
        color: primaryPurple,
        buttonName: "More",
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(opacity: animation, child: child);
          },
          child: Icon(
            animationController.isCompleted ? CupertinoIcons.xmark : CupertinoIcons.add,
            key: ValueKey<bool>(animationController.isCompleted),
          ),
        ),
        onClick: () {
          if (animationController.isCompleted) {
            animationController.reverse();
            log("Drawer closing");
          } else {
            animationController.forward();
            log("Drawer opening");
          }
        },
      ),
    );
  }

  Transform deleteTaskButton(Color primaryPurple) {
    return Transform.translate(
      offset: Offset.fromDirection(getRadianFromDegree(180), degThreeTranslationAnimation.value * 100),
      child: Transform(
        transform: Matrix4.rotationZ(getRadianFromDegree(rotationAnimation.value))
          ..scale(degThreeTranslationAnimation.value),
        alignment: Alignment.center,
        child: CircularFloatingButton(
          height: 45,
          width: 45,
          color: primaryPurple,
          buttonName: "Delete",
          child: const Icon(CupertinoIcons.trash_fill, size: 20),
          onClick: () {
            log("delete button is pressed");
            _deleteAllTask();
          },
        ),
      ),
    );
  }

  Transform saveTaskButton(Color primaryPurple) {
    return Transform.translate(
      offset: Offset.fromDirection(getRadianFromDegree(225), degTwoTranslationAnimation.value * 100),
      child: Transform(
        transform: Matrix4.rotationZ(getRadianFromDegree(rotationAnimation.value))
          ..scale(degTwoTranslationAnimation.value),
        alignment: Alignment.center,
        child: CircularFloatingButton(
          height: 45,
          width: 45,
          color: primaryPurple,
          buttonName: "Save",
          child: const Icon(CupertinoIcons.floppy_disk, size: 20),
          onClick: () {
            log("Save button is pressed");
            updatePendingTaskList();
          },
        ),
      ),
    );
  }

  Transform addTaskButton(Color primaryPurple, BuildContext context, double width) {
    return Transform.translate(
      offset: Offset.fromDirection(getRadianFromDegree(270), degOneTranslationAnimation.value * 100),
      child: Transform(
        transform: Matrix4.rotationZ(getRadianFromDegree(rotationAnimation.value))
          ..scale(degOneTranslationAnimation.value),
        alignment: Alignment.center,
        child: CircularFloatingButton(
          height: 45,
          width: 45,
          color: primaryPurple,
          buttonName: "Add",
          child: const Icon(CupertinoIcons.add, size: 20),
          onClick: () {
            log("add button is pressed");
            showDialog(
              context: context,
              builder: (BuildContext context) => AlertDialog(
                title: const Text("Add Task"),
                content: TextField(
                  controller: _taskController,
                  decoration: const InputDecoration(hintText: "Enter task here"),
                ),
                actions: <Widget>[
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text("Cancel"),
                  ),
                  TextButton(
                    onPressed: saveData,
                    child: const Text("Save"),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
