
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(MaterialApp(
    home: MainApp(),
    debugShowCheckedModeBanner: false,
  ));
}

//메인 화면 전환 및 메뉴 관리 
class MainApp extends StatefulWidget {
  @override
  _MainAppState createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  int _selectedIndex = 0; //  할일 목록,타이머

  final List<Widget> _pages = [
    TodoListApp(),
    TimerApp(),
  ];

  // 사이드 메뉴 선택 시 화면 전환 로직
  void _onMenuTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
    Navigator.pop(context); // 메뉴 닫기
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedIndex == 0 ? 'ToDo List' : 'Timer'),
        backgroundColor: Color(0xFFFFB6C1),
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(child: Text('menu', style: TextStyle(fontSize: 24))),
            ListTile(
              title: Text('ToDo List'),
              onTap: () => _onMenuTap(0),
            ),
            ListTile(
              title: Text('Timer'),
              onTap: () => _onMenuTap(1),
            ),
          ],
        ),
      ),
      body: _pages[_selectedIndex], // 선택된 페이지 표시
    );
  }
}

//데이터 저장되는 todolist

class TodoListApp extends StatefulWidget {
  @override
  _TodoListAppState createState() => _TodoListAppState();
}

class _TodoListAppState extends State<TodoListApp> {
  List<String> _todos = [];
  TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTodos(); // 앱 시작 시 저장된 데이터 로드
  }

  //로컬 저장소(SharedPreferences)에서 데이터 불러오기
  Future<void> _loadTodos() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _todos = (jsonDecode(prefs.getString('todos') ?? '[]')).cast<String>();
    });
  }

  // 데이터 변경 시 로컬 저장소에 영구 저장
  Future<void> _saveTodos() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('todos', jsonEncode(_todos));
  }

  // 할 일 추가 및 저장
  void _addTodo(String todo) {
    if (todo.trim().isEmpty) return;
    setState(() {
      _todos.add(todo);
      _controller.clear();
    });
    _saveTodos();
  }

  // 할 일 삭제 및 저장
  void _deleteTodo(int index) {
    setState(() {
      _todos.removeAt(index);
    });
    _saveTodos();
  }

  // 할 일 수정 팝업 및 저장
  void _editTodoDialog(int index) {
    final editController = TextEditingController(text: _todos[index]);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('할 일 수정'),
        content: TextField(
          controller: editController,
          decoration: InputDecoration(hintText: '수정할 내용을 입력하세요'),
        ),
        actions: [
          TextButton(
            child: Text('취소'),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: Text('저장'),
            onPressed: () {
              setState(() {
                _todos[index] = editController.text;
              });
              _saveTodos(); // 수정 내용 반영
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(hintText: '할 일을 입력하세요'),
                ),
              ),
              IconButton(
                icon: Icon(Icons.add),
                onPressed: () => _addTodo(_controller.text),
              )
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _todos.length,
            itemBuilder: (context, index) => ListTile(
              title: Text(_todos[index]),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit, color: Colors.brown),
                    onPressed: () => _editTodoDialog(index),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.brown),
                    onPressed: () => _deleteTodo(index),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

//timer 

class TimerApp extends StatefulWidget {
  @override
  _TimerAppState createState() => _TimerAppState();
}

class _TimerAppState extends State<TimerApp> {
  late Timer _timer;
  int _seconds = 0;
  bool _isRunning = false;

  // 1초 간격으로 반복 실행
  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _seconds++;
      });
    });
    setState(() {
      _isRunning = true;
    });
  }

  void _stopTimer() {
    _timer.cancel(); // 타이머 중지
    setState(() {
      _isRunning = false;
    });
  }

  void _resetTimer() {
    if (_isRunning) _timer.cancel();
    setState(() {
      _seconds = 0; // 시간 초기화
      _isRunning = false;
    });
  }

  // 초(int) == 00:00:00 형식 문자열로 변환
  String _formatTime(int totalSeconds) {
    int hours = totalSeconds ~/ 3600;
    int minutes = (totalSeconds % 3600) ~/ 60;
    int seconds = totalSeconds % 60;
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return "${twoDigits(hours)}:${twoDigits(minutes)}:${twoDigits(seconds)}";
  }

  // 메모리 누수 방지를 위해 화면 종료 시 타이머 해제 
  @override
  void dispose() {
    if (_isRunning) _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _formatTime(_seconds),
            style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: _isRunning ? _stopTimer : _startTimer,
                child: Text(_isRunning ? 'Stop' : 'Start'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  textStyle: TextStyle(fontSize: 20),
                ),
              ),
              SizedBox(width: 20),
              ElevatedButton(
                onPressed: _resetTimer,
                child: Text('Reset'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  textStyle: TextStyle(fontSize: 20),
                  backgroundColor: Colors.redAccent,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}

