import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart'; // Add this import

void main() {
  runApp(MyApp());
}

class Task {
  String title;
  String description;
  double progress; // changed to double for percentage
  String assignee;
  String period;
  String urgency;

  Task(this.title, this.description, this.progress, this.assignee, this.period, this.urgency);
}

class TaskProvider with ChangeNotifier {
  List<Task> _tasks = [
    Task('Lorem', 'lorem ipsum...', 0.15, 'Ipsum', '01.07.2023 - 31.07.2023', 'High'),
    Task('Loremm', 'lorem ipsmum...', 0.3, 'Ipsmum', '11.07.2023 - 31.07.2023', 'High'),
  ];

  List<Task> get tasks => _tasks;

  void updateTask(int index, Task task) {
    _tasks[index] = task;
    notifyListeners();
  }

  void addTask(Task task) {
    _tasks.add(task);
    notifyListeners();
  }

  void deleteTask(int index) {
    _tasks.removeAt(index);
    notifyListeners();
  }

  void duplicateTask(int index) {
    if (index >= 0 && index < _tasks.length) {
      final originalTask = _tasks[index];
      final duplicatedTask = Task(
        originalTask.title + ' (Copy)', // Example: Append '(Copy)' to the title
        originalTask.description,
        originalTask.progress,
        originalTask.assignee,
        originalTask.period,
        originalTask.urgency,
      );
      _tasks.insert(index + 1, duplicatedTask); // Insert duplicated task after the original
      notifyListeners();
    }
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TaskProvider(),
      child: MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            title: Text('Task List'),
          ),
          body: TaskTable(),
        ),
      ),
    );
  }
}

class TaskTable extends StatefulWidget {
  @override
  _TaskTableState createState() => _TaskTableState();
}

class _TaskTableState extends State<TaskTable> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);
    final tasks = taskProvider.tasks;
    int pageCount = (tasks.length / 15).ceil(); // Assuming 15 tasks per page

    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (page) {
              setState(() {
                _currentPage = page;
              });
            },
            itemCount: pageCount,
            itemBuilder: (context, pageIndex) {
              final start = pageIndex * 15;
              final end = (pageIndex + 1) * 15;
              final pageTasks = tasks.sublist(start, end > tasks.length ? tasks.length : end);

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: DataTable(
                    columns: [
                      DataColumn(label: Text('Title')),
                      DataColumn(label: Text('Description')),
                      DataColumn(label: Text('Progress')),
                      DataColumn(label: Text('Assignee')),
                      DataColumn(label: Text('Period')),
                      DataColumn(label: Text('Urgency')),
                      DataColumn(label: Text('Actions')),
                    ],
                    rows: List.generate(pageTasks.length, (index) {
                      final task = pageTasks[index];
                      final taskIndex = start + index;

                      return DataRow(
                        cells: [
                          DataCell(Text(task.title), onTap: () => _editTask(context, taskProvider, taskIndex, 'Title')),
                          DataCell(Text(task.description), onTap: () => _editTask(context, taskProvider, taskIndex, 'Description')),
                          DataCell(
                            Stack(
                              children: [
                                LinearProgressIndicator(
                                  value: task.progress,
                                  backgroundColor: Colors.grey,
                                  valueColor: AlwaysStoppedAnimation(Colors.blue),
                                ),
                                Center(child: Text('${(task.progress * 100).toInt()}%')),
                              ],
                            ),
                            onTap: () => _editTask(context, taskProvider, taskIndex, 'Progress'),
                          ),
                          DataCell(
                            GestureDetector(
                              onTap: () => _editAssignee(context, taskProvider, taskIndex),
                              child: Tooltip(
                                message: task.assignee,
                                child: CircleAvatar(
                                  child: Text(task.assignee.substring(0, 1)),
                                ),
                              ),
                            ),
                          ),
                          DataCell(
                            GestureDetector(
                              onTap: () => _editPeriod(context, taskProvider, taskIndex),
                              child: Text(task.period),
                            ),
                          ),
                          DataCell(
                            GestureDetector(
                              onTap: () => _editUrgency(context, taskProvider, taskIndex),
                              child: Text(task.urgency),
                            ),
                          ),
                          DataCell(
                            PopupMenuButton(
                              onSelected: (value) {
                                if (value == 'duplicate') {
                                  taskProvider.duplicateTask(taskIndex);
                                } else if (value == 'delete') {
                                  taskProvider.deleteTask(taskIndex);
                                }
                              },
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: 'duplicate',
                                  child: Text('Duplicate'),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Text('Delete'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                ),
              );
            },
          ),
        ),
        Container(
          padding: EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton(
                onPressed: () {
                  _addTask(context, taskProvider);
                },
                child: Text('Add Task'),
              ),
              Text('Page ${_currentPage + 1} of $pageCount'),
            ],
          ),
        ),
      ],
    );
  }

  void _addTask(BuildContext context, TaskProvider taskProvider) {
    final task = Task('', '', 0, '', '', ''); // Initialize an empty task

    showDialog(
      context: context,
      builder: (context) {
        final TextEditingController titleController = TextEditingController();
        final TextEditingController descriptionController = TextEditingController();
        final TextEditingController progressController = TextEditingController();
        final TextEditingController assigneeController = TextEditingController();
        DateTimeRange? period;
        String urgency = 'Low';

        return AlertDialog(
          title: Text('Add Task'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(labelText: 'Title'),
                ),
                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(labelText: 'Description'),
                ),
                TextField(
                  controller: progressController,
                  decoration: InputDecoration(labelText: 'Progress (1-100)'),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    TextInputFormatter.withFunction((oldValue, newValue) {
                      if (newValue.text.isNotEmpty) {
                        final progress = int.parse(newValue.text);
                        if (progress < 1 || progress > 100) {
                          return oldValue;
                        }
                      }
                      return newValue;
                    }),
                  ],
                ),
                TextField(
                  controller: assigneeController,
                  decoration: InputDecoration(labelText: 'Assignee'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    period = await showDateRangePicker(
                      context: context,
                      initialEntryMode: DatePickerEntryMode.input,
                      firstDate: DateTime(2022),
                      lastDate: DateTime(2024),
                    );
                  },
                  child: Text('Select Period'),
                ),
                period != null
                    ? Text('${DateFormat('dd.MM.yyyy').format(period!.start)} - ${DateFormat('dd.MM.yyyy').format(period!.end)}')
                    : Text('No period selected'),
                DropdownButton<String>(
                  value: urgency,
                  onChanged: (String? newValue) {
                    urgency = newValue!;
                  },
                  items: <String>['Low', 'Medium', 'High']
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final progress = double.tryParse(progressController.text) ?? 0 / 100;
                final newTask = Task(
                  titleController.text,
                  descriptionController.text,
                  progress,
                  assigneeController.text,
                  period != null
                      ? '${DateFormat('dd.MM.yyyy').format(period!.start)} - ${DateFormat('dd.MM.yyyy').format(period!.end)}'
                      : '',
                  urgency,
                );
                taskProvider.addTask(newTask);
                Navigator.of(context).pop();
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _editTask(BuildContext context, TaskProvider taskProvider, int index, String field) {
    final task = taskProvider.tasks[index];
    final TextEditingController controller = TextEditingController();

    switch (field) {
      case 'Title':
        controller.text = task.title;
        break;
      case 'Description':
        controller.text = task.description;
        break;
      case 'Progress':
        controller.text = (task.progress * 100).toInt().toString();
        break;
      default:
        return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit $field'),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(labelText: field),
            keyboardType: field == 'Progress' ? TextInputType.number : TextInputType.text,
            inputFormatters: field == 'Progress'
                ? [
                    FilteringTextInputFormatter.digitsOnly,
                    TextInputFormatter.withFunction((oldValue, newValue) {
                      if (newValue.text.isNotEmpty) {
                        final progress = int.parse(newValue.text);
                        if (progress < 1 || progress > 100) {
                          return oldValue;
                        }
                      }
                      return newValue;
                    }),
                  ]
                : [],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                switch (field) {
                  case 'Title':
                    task.title = controller.text;
                    break;
                  case 'Description':
                    task.description = controller.text;
                    break;
                  case 'Progress':
                    task.progress = double.parse(controller.text) / 100;
                    break;
                }
                taskProvider.updateTask(index, task);
                Navigator.of(context).pop();
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _editAssignee(BuildContext context, TaskProvider taskProvider, int index) {
    final task = taskProvider.tasks[index];
    final TextEditingController controller = TextEditingController();
    controller.text = task.assignee;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Assignee'),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(labelText: 'Assignee'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                task.assignee = controller.text;
                taskProvider.updateTask(index, task);
                Navigator.of(context).pop();
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _editPeriod(BuildContext context, TaskProvider taskProvider, int index) async {
    final task = taskProvider.tasks[index];
    DateTimeRange? period = await showDateRangePicker(
      context: context,
      initialEntryMode: DatePickerEntryMode.input,
      firstDate: DateTime(2022),
      lastDate: DateTime(2024),
    );

    if (period != null) {
      task.period = '${DateFormat('dd.MM.yyyy').format(period.start)} - ${DateFormat('dd.MM.yyyy').format(period.end)}';
      taskProvider.updateTask(index, task);
    }
  }

  void _editUrgency(BuildContext context, TaskProvider taskProvider, int index) {
    final task = taskProvider.tasks[index];
    String urgency = task.urgency;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Urgency'),
          content: DropdownButton<String>(
            value: urgency,
            onChanged: (String? newValue) {
              urgency = newValue!;
            },
            items: <String>['Low', 'Medium', 'High'].map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                task.urgency = urgency;
                taskProvider.updateTask(index, task);
                Navigator.of(context).pop();
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }
}
