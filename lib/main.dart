import 'dart:async';
import 'dart:convert';
import 'package:dynamic_color_demo/service_pages/Cumulated_report.dart';
import 'package:dynamic_color_demo/service_pages/analysis_page.dart';
import 'package:dynamic_color_demo/service_pages/my_info.dart';
import 'package:dynamic_color_demo/widgets/circular_border_avatar.dart';
import 'package:dynamic_color_demo/widgets/my_container.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:web_socket_channel/io.dart';
import 'config.dart';
import 'long_polling_service.dart';
import 'user_model.dart';
import 'notifications_model.dart';
import 'bottombar_pages/notification_page.dart';
import 'bottombar_pages/settings_page.dart';
import 'bottombar_pages/bookmark_page.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Config.init();
  final notificationModel = NotificationModel();
  final userModel = UserModel();
  final notificationChannel =
      IOWebSocketChannel.connect('ws://your-server.com/ws');

  notificationChannel.stream.listen((message) {
    notificationModel.addNotification(message);
    showNotification(message);
  });

  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => userModel),
      ChangeNotifierProvider(create: (_) => notificationModel),
      Provider(
        create: (_) => LongPollingService(
          serverUrl:
              "http://192.168.0.13:5000/long_polling/1/2024-04-24T03:00:00Z",
          userId: '111', // 예시 ID
          notificationModel: NotificationModel(), // 의존성 주입
        ),
      ),
    ],
    child: DynamicColorDemo(notificationChannel: notificationChannel),
  ));
}

// final IOWebSocketChannel channel = IOWebSocketChannel.connect('ws://your-server.com/ws');

// void listenToWebSocket() {
//   channel.stream.listen((message) {
//     final decodedMessage = jsonDecode(message);
//     Provider.of<NotificationModel>(context, listen: false)
//         .addNotification({
//       'message': decodedMessage['message'],
//       'time': DateTime.now().toString()
//     });
//   });
// }

FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void setupNotifications() async {
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
}

void showNotification(String message) async {
  const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
    'your channel id',
    'your channel name',
    channelDescription: 'your channel description',
    importance: Importance.max,
    priority: Priority.high,
    showWhen: false,
  );

  const NotificationDetails platformChannelSpecifics =
      NotificationDetails(android: androidPlatformChannelSpecifics);

  await flutterLocalNotificationsPlugin.show(
    0, // Notification ID
    'New Notification', // Notification Title
    message, // Notification Body
    platformChannelSpecifics,
  );
}

// -----------------------------------------------

const seedColor = Colors.white;
const outPadding = 25.0;

class DynamicColorDemo extends StatelessWidget {
  final IOWebSocketChannel notificationChannel;

  DynamicColorDemo({Key? key, required this.notificationChannel})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: seedColor,
        brightness: Brightness.dark,
        textTheme: GoogleFonts.notoSansNKoTextTheme(
          Theme.of(context).textTheme,
        ),
      ),
      home: SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    setupNotifications();
    Timer(Duration(seconds: 10), () {
      Navigator.of(context)
          .pushReplacement(MaterialPageRoute(builder: (_) => LoginPage()));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: Color.fromRGBO(20, 20, 20, 0),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 90),
                Image.network(
                  'https://i.ibb.co/TPx3NmK/logo-final.png',
                  width: 300,
                  height: 300,
                  fit: BoxFit.contain,
                ),
                SizedBox(height: 20),
                Text(
                  "Getting ready to run...",
                  style: GoogleFonts.nanumGothic(color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// 로그인 화면
class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // 로그인 성공 여부 판단
  void _attemptLogin() async {
    var response = await http.get(
      Uri.parse('${Config.serverUrl}'), // 서버에서 모든 사용자 데이터를 가져오는 API 주소
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      // 서버에서 받은 모든 사용자 목록
      List<dynamic> userDataList = json.decode(response.body);

      // 입력한 ID와 Password를 가진 사용자를 찾기
      var userData = userDataList.firstWhere(
          (user) =>
              user['identifier'] == _idController.text &&
              user['password'] == _passwordController.text,
          orElse: () => null);

      if (userData != null) {
        // 사용자 데이터를 찾았으면 UserModel에 저장하고 메인 화면으로 이동합니다.
        Provider.of<UserModel>(context, listen: false).setUser(userData);
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => MainScreen()));
      } else {
        // 일치하는 사용자가 없을 경우 로그인 실패 메시지를 보여줍니다.
        _showErrorMessage(context, "Invalid identifier or password.");
      }
    } else {
      // 서버 연결 실패 시 메시지 표시
      _showErrorMessage(context, "Failed to connect to the server.");
    }
  }

  // 로그인 실패시 알람 띄우는 함수
  void _showErrorMessage(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            "로그인 실패",
            style: GoogleFonts.nanumGothic(
              color: Colors.white,
            ),
          ),
          content: Text(
            message,
            style: GoogleFonts.nanumGothic(
              color: Colors.white,
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("확인"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Color.fromRGBO(20, 20, 20, 0),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(50.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(
                  height: 160,
                ),
                // ID 입력
                Padding(
                  padding: const EdgeInsets.all(3.0),
                  child: Text(
                    "ID",
                    style: GoogleFonts.nanumGothic(
                      color: Colors.white,
                      fontSize: 20,
                    ),
                  ),
                ),
                Container(
                  width: 330,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.rectangle,
                    borderRadius: BorderRadius.circular(18),
                    color: Colors.grey.withOpacity(0.6),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 2,
                  ), // TextField 내부에 약간의 여백을 제공
                  child: TextField(
                    controller: _idController,
                    style: GoogleFonts.nanumGothic(
                        color: Colors.white), // 텍스트 필드 내의 글자 색상 설정
                    decoration: InputDecoration(
                      hintText: "아이디를 입력하세요", // 사용자에게 힌트 제공
                      hintStyle: GoogleFonts.nanumGothic(
                          color: Colors.white.withOpacity(0.3)), // 힌트 텍스트 스타일
                      border: InputBorder.none, // 테두리 없앰
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 10), // 세로 방향 패딩 조절
                    ),
                  ),
                ),

                const SizedBox(
                  height: 40,
                ),

                // Password 입력
                Padding(
                  padding: const EdgeInsets.all(3.0),
                  child: Text(
                    "Password",
                    style: GoogleFonts.nanumGothic(
                      color: Colors.white,
                      fontSize: 20,
                    ),
                  ),
                ),
                Container(
                  width: 330,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.rectangle,
                    borderRadius: BorderRadius.circular(18),
                    color: Colors.grey.withOpacity(0.6),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 2,
                  ), // TextField 내부에 약간의 여백을 제공
                  child: TextField(
                    controller: _passwordController,
                    obscureText: true, // 비밀번호 입력 필드로 만듦
                    style: GoogleFonts.nanumGothic(
                        color: Colors.white), // 텍스트 필드 내의 글자 색상 설정
                    decoration: InputDecoration(
                      hintText: "비밀번호를 입력하세요", // 사용자에게 힌트 제공
                      hintStyle: GoogleFonts.nanumGothic(
                          color: Colors.white.withOpacity(0.3)), // 힌트 텍스트 스타일
                      border: InputBorder.none, // 테두리 없앰
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 10), // 세로 방향 패딩 조절
                    ),
                  ),
                ),

                const SizedBox(
                  height: 80,
                ),

                // 로그인 버튼
                Padding(
                  padding: const EdgeInsets.only(left: 100),
                  child: Container(
                    width: 100,
                    height: 40,
                    child: ElevatedButton(
                      onPressed: _attemptLogin,
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(1),
                        ),
                        backgroundColor: Color.fromRGBO(255, 94, 0, 1),
                      ),
                      child: Text(
                        '로그인',
                        style: GoogleFonts.nanumGothic(
                          color: Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Main Page - BottomBar Navigation
class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selected = 0;

  final List<Widget> _pages = [
    HomeScreen(),
    BookmarkScreen(),
    NotificationPage(),
    SettingsScreen(), // 설정 페이지 나중 구현
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromRGBO(22, 22, 22, 1),
      body: IndexedStack(
        index: _selected,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selected,
        elevation: 0,
        onTap: (selected) {
          setState(() {
            _selected = selected;
          });
        },
        selectedItemColor: Color.fromRGBO(255, 94, 0, 1),
        unselectedItemColor: Colors.white,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(
                Icons.home_outlined,
                size: 35,
              ),
              label: "Home",
              backgroundColor: Color.fromRGBO(20, 20, 20, 0)),
          BottomNavigationBarItem(
              icon: Icon(
                Icons.bookmark_outline_outlined,
                size: 35,
              ),
              label: "Bookmarks",
              backgroundColor: Color.fromRGBO(20, 20, 20, 0)),
          BottomNavigationBarItem(
              icon: Icon(
                Icons.notifications_outlined,
                size: 35,
              ),
              label: "Notifications",
              backgroundColor: Color.fromRGBO(20, 20, 20, 0)),
          BottomNavigationBarItem(
              icon: Icon(
                Icons.settings_outlined,
                size: 35,
              ),
              label: "Settings",
              backgroundColor: Color.fromRGBO(20, 20, 20, 0)),
        ],
      ),
    );
  }
}

// 진짜 main home
class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final userModel = Provider.of<UserModel>(context);
    final name = userModel.name; // 사용자 이름 가져오기

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(outPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.directions_run_outlined,
                  color: Color(0xFFFF5E00),
                  size: 35,
                ),
                Text(
                  " Run Po Insight",
                  style: GoogleFonts.nanumGothic(
                    color: Color.fromRGBO(255, 94, 0, 1),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Expanded(child: Container()),
                CircularBorderAvatar(
                  'https://i.ibb.co/YjNpQq7/cloudJ.jpg',
                  borderColor: Color.fromRGBO(22, 22, 22, 1),
                  size: 45,
                )
              ],
            ),
            const SizedBox(
              height: outPadding,
            ),
            Text(
              '안녕하세요! $name 님,',
              style: GoogleFonts.nanumGothic(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 28),
            ),
            const SizedBox(height: 5),
            Text(
              '오늘도 달릴 준비되셨나요?',
              style: GoogleFonts.nanumGothic(
                color: Colors.grey,
                fontSize: 17,
              ),
            ),
            const SizedBox(
              height: 25,
            ),
            const _TopCard(),
            const SizedBox(
              height: 30,
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '$name 님의 러닝 일지',
                    style: Theme.of(context).textTheme.titleLarge!.copyWith(
                          fontSize: 22,
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                _ActionBtn()
              ],
            ),
            const SizedBox(
              height: 12,
            ),
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Flexible(
                          flex: 3,
                          child: MyContainer(
                            color: Color.fromRGBO(22, 22, 22, 1),
                            border: Border.all(
                                color: Color.fromRGBO(219, 102, 24, 1),
                                width: 4),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const CumulReport()),
                              );
                            },
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '누적 기록',
                                  style: GoogleFonts.nanumGothic(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w600,
                                    color: Color.fromARGB(255, 250, 230, 206),
                                  ),
                                ),
                                Text(
                                  " ",
                                  style: GoogleFonts.nanumGothic(fontSize: 4),
                                ),
                                Text(
                                  '최고기록을 향해!',
                                  style: GoogleFonts.nanumGothic(
                                    color: Color.fromARGB(255, 250, 230, 206),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(
                    width: 15,
                  ),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Flexible(
                          flex: 2,
                          child: MyContainer(
                            color: Color.fromRGBO(22, 22, 22, 1),
                            border: Border.all(
                              color: Color.fromRGBO(219, 102, 24, 1),
                              width: 4,
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const MyInfo()),
                              );
                            },
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '내 정보',
                                  style: GoogleFonts.nanumGothic(
                                    color: Color.fromARGB(255, 250, 230, 206),
                                    fontSize: 22,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  " ",
                                  style: GoogleFonts.nanumGothic(fontSize: 4),
                                ),
                                Text(
                                  '맞춤 분석에 사용돼요',
                                  style: GoogleFonts.nanumGothic(
                                    color: Color.fromARGB(255, 250, 230, 206),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 35),
            Row(
              children: [
                Container(
                    height: 60,
                    width: 334,
                    decoration: BoxDecoration(
                      color: Colors.white,
                    ),
                    child: Image.asset(
                      "assets/images/AD.png",
                      fit: BoxFit.contain,
                    )),
              ],
            ),
            const SizedBox(height: 5),
          ],
        ),
      ),
    );
  }
}

// 도움말 버튼
class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 26,
      width: 26,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Color.fromRGBO(255, 94, 0, 1),
          width: 2.0,
        ),
      ),
      child: Icon(
        Icons.question_mark_rounded,
        color: Color.fromRGBO(255, 94, 0, 1),
        size: 20,
      ),
    );
  }
}

// 자세분석결과 조회 버튼
class _TopCard extends StatelessWidget {
  const _TopCard({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MyContainer(
      // color: Color.fromRGBO(255, 130, 29, 1),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AnalysisPage()),
        );
      },
      gradient: LinearGradient(
        begin: Alignment.bottomRight,
        end: Alignment.topLeft,
        colors: [
          Colors.orange[800]!,
          Colors.orange[600]!,
          Colors.orange[500]!,
          Colors.orange[400]!,
          Colors.orange[300]!,
          Colors.orange[200]!,
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(
            height: 40,
          ),
          Text(
            '자세 분석 결과 조회',
            style: GoogleFonts.nanumGothic(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Colors.black,
            ),
          ),
          Text(
            '나의 러닝 습관을 알아보세요',
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(
            height: 40,
          ),
        ],
      ),
    );
  }
}
