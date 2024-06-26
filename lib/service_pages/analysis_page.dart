import 'dart:ffi';

import 'package:dynamic_color_demo/widgets/my_container.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../user_model.dart';

// 중간 내용에 무릎 각도 추가

// 총 분석
// 1. 케이던스
// 2. 무릎 각도, 착지
// 3. 상체 기울기

class AnalysisPage extends StatefulWidget {
  const AnalysisPage({Key? key}) : super(key: key);

  @override
  _AnalysisPageState createState() => _AnalysisPageState();
}

class _AnalysisPageState extends State<AnalysisPage> {
  // default
  String landingType = '훌륭'; // '훌륭', '주의'
  String strikeType = '정상'; // '힐', '포어', '정상'
  String balanceType = '균형'; // '균형', '불균형'
  String footType = '정상'; // '요족', '정상', '평발'
  late VideoPlayerController _controller;
  String l1_message = '';
  String l2_message = '';
  String l3_message = '';
  String cad = "";

  String img_url = '';

  @override
  void initState() {
    super.initState();
    fetchLatestDataAndPlayVideo();
  }

  @override
  void dispose() {
    if (_controller != null && _controller.value.isInitialized) {
      _controller.dispose();
    }
    super.dispose();
  }

  Future<void> fetchLatestDataAndPlayVideo() async {
    UserModel userModel = Provider.of<UserModel>(context, listen: false);

    // UserModel에서 데이터 사용
    footType = userModel.footType; // 'foot_type' 데이터 사용

    if (userModel.datas.isNotEmpty) {
      final latestData = userModel.datas.first;
      final footPos = latestData['foot_pos'];
      final shldImb = latestData['shld_imb'];
      final videoUrl = latestData['video_url'];
      final l1_mes = latestData['l1_mes'];
      final l2_mes = latestData['l2_mes'];
      final l3_mes = latestData['l3_mes'];
      final cad_now = latestData['cad'];
      final img = latestData['analysis_img'];

      // strikeType 설정
      if (footPos == 'mid') {
        strikeType = '정상';
        landingType = '훌륭';
      } else if (footPos == 'heel') {
        strikeType = '힐';
        landingType = '주의';
      } else if (footPos == 'toe') {
        strikeType = '포어';
        landingType = '주의';
      }

      // balanceType 설정
      balanceType = shldImb == 'TRUE' ? '불균형' : '균형';

      l1_message = l1_mes;
      l2_message = l2_mes;
      l3_message = l3_mes;

      cad = cad_now;

      img_url = img;

      // VideoPlayerController 초기화 및 리스너 설정
      _controller = VideoPlayerController.network(videoUrl)
        ..initialize().then((_) {
          setState(() {
            if (_controller.value.isInitialized) {
              _controller.play();
            }
          });
          // 오류 리스너 추가
          _controller.addListener(() {
            final error = _controller.value.errorDescription;
            if (error != null) {
              // 로그 출력 또는 사용자에게 알림
              print("Playback error: $error");
              // 오류가 발생하면 다시 초기화 및 재생 시도
              _controller.initialize().then((_) {
                _controller.play();
              }).catchError((e) {
                print("Error reinitializing the video: $e");
              });
            }
          });
        }).catchError((e) {
          print("Error initializing video: $e");
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromRGBO(22, 22, 22, 1),
        leading: IconButton(
          icon: Icon(Icons.navigate_before),
          iconSize: 40,
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        elevation: 0,
      ),
      body: Container(
        color: Color.fromRGBO(22, 22, 22, 1),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // 제목
                Text(
                  "나의 러닝 습관\n알아보기",
                  style: GoogleFonts.nanumGothic(
                      color: Colors.white,
                      fontSize: 45,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                      height: 1.1),
                ),
                SizedBox(height: 60),

                // 영상
                Center(
                  child: Text(
                    "최신 대회에서 회원님의 자세를 분석한 결과예요",
                    style: GoogleFonts.nanumGothic(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.2,
                        height: 1.0),
                  ),
                ),
                SizedBox(height: 20),
                Center(
                  child: _controller.value.isInitialized
                      ? Container(
                          width: 330,
                          height: 330,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(50),
                            border: Border.all(
                              color: Color.fromARGB(255, 255, 100, 0),
                              width: 10,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(40),
                            child: AspectRatio(
                              aspectRatio: _controller.value.aspectRatio,
                              child: VideoPlayer(_controller),
                            ),
                          ),
                        )
                      : Container(
                          width: 330,
                          height: 330,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(50),
                            border: Border.all(
                              color: Color.fromARGB(255, 255, 100, 0),
                              width: 7,
                            ),
                          ),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                ),
                SizedBox(height: 50),

                // 착지 관련 내용
                Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                  RichText(
                    text: TextSpan(
                      style: GoogleFonts.nanumGothic(
                        color: Colors.white,
                        fontSize: 33,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
                      children: <TextSpan>[
                        TextSpan(
                          text: "착지",
                          style: GoogleFonts.nanumGothic(
                            color: Color.fromARGB(255, 255, 100, 0),
                            fontSize: 33,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.2,
                          ),
                        ),
                        TextSpan(
                          text: landingType == '훌륭' ? "가 " : "에 ",
                        ),
                        TextSpan(
                          text: landingType == '훌륭' ? "훌륭" : "주의",
                          style: GoogleFonts.nanumGothic(
                            color: Color.fromARGB(255, 255, 100, 0),
                            fontSize: 33,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.2,
                          ),
                        ),
                        TextSpan(
                          text: landingType == '훌륭' ? "해요!" : "하세요!",
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 3,
                  )
                ]),
                SizedBox(
                  height: 2,
                ),
                Container(
                  width: 420,
                  height: 300,
                  decoration: BoxDecoration(
                    color: Color.fromARGB(255, 51, 51, 51),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Stack(
                    children: [
                      // 이미지
                      Positioned(
                        top: 11.0,
                        left: 23.0,
                        right: 23.0,
                        child: Image.network(
                          "https://i.ibb.co/HHSt4Yk/Footstrike-patterns.jpg",
                          height: 130, // 이미지 높이 조정
                        ),
                      ),
                      // 조건에 따른 다른 강조 표시
                      if (strikeType == '힐')
                        Positioned(
                          top: 26.0,
                          left: 40,
                          child: Container(
                            width: 105,
                            height: 100,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.red,
                                width: 5,
                              ),
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                        ),
                      if (strikeType == '정상')
                        Positioned(
                          top: 26.0,
                          left: 130,
                          child: Container(
                            width: 90,
                            height: 100,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.red,
                                width: 5,
                              ),
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                        ),
                      if (strikeType == '포어')
                        Positioned(
                          top: 26.0,
                          left: 215,
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.red,
                                width: 5,
                              ),
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                        ),
                      Positioned(
                        top: 135,
                        // bottom: 10.0,
                        left: 20.0,
                        right: 20.0,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: Column(
                            children: [
                              if (strikeType == '힐')
                                fillcontext(
                                  "착지 시 뒤꿈치로 착지하고 있습니다. 지면에 뒤꿈치가 먼저 닿는 힐 스트라이크는 무릎 통증과 햄스트링 부상을 유발할 위험성이 큽니다. 미드풋 스트라이크로  착지하는 연습을 해보는 것을 추천합니다. 알맞은 무릎 각도와 함께 안전한 러닝하세요!",
                                ),
                              if (strikeType == '정상')
                                fillcontext(
                                  "정상 문구",
                                ),
                              if (strikeType == '포어')
                                fillcontext(
                                  "착지 시 앞꿈치로 착지하고 있습니다. 지면에 앞꿈치가 먼저 닿는 힐 스트라이크는 무릎 통증과 햄스트링 부상을 유발할 위험성이 큽니다. 미드풋 스트라이크로  착지하는 연습을 해보는 것을 추천합니다. 알맞은 무릎 각도와 함께 안전한 러닝하세요!",
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 50,
                ),

                // 좌우 균형
                Row(mainAxisAlignment: MainAxisAlignment.start, children: [
                  SizedBox(
                    width: 3,
                  ),
                  RichText(
                    text: TextSpan(
                      style: GoogleFonts.nanumGothic(
                        color: Colors.white,
                        fontSize: 33,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
                      children: <TextSpan>[
                        TextSpan(
                          text: "상체 균형",
                          style: GoogleFonts.nanumGothic(
                            color: Color.fromARGB(255, 255, 100, 0),
                            fontSize: 31,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.2,
                          ),
                        ),
                        TextSpan(
                          text: "이 ",
                          style: GoogleFonts.nanumGothic(
                            fontSize: 31,
                          ),
                        ),
                        TextSpan(
                          text: balanceType == '균형' ? "안정적" : "불안정",
                          style: GoogleFonts.nanumGothic(
                            color: Color.fromARGB(255, 255, 100, 0),
                            fontSize: 31,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.2,
                          ),
                        ),
                        TextSpan(
                          text: balanceType == '균형' ? "이에요" : "해요",
                          style: GoogleFonts.nanumGothic(
                            fontSize: 31,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 3,
                  )
                ]),
                Padding(
                  padding: const EdgeInsets.only(top: 5.0),
                  child: Container(
                    width: 420,
                    height: 330,
                    decoration: BoxDecoration(
                      color: Color.fromARGB(255, 51, 51, 51),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          top: 20.0,
                          left: 50.0,
                          right: 50.0,
                          child: Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.grey.withAlpha(160),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.network(
                                  "https://i.ibb.co/pPGZC4f/running-balance.png",
                                  height: 190, // 이미지 높이 조정
                                ),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 10.0,
                          left: 20.0,
                          right: 20.0,
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Column(
                              children: [
                                if (balanceType == '균형')
                                  fillcontext(
                                    "",
                                  ),
                                if (balanceType == '불균형')
                                  fillcontext(
                                    "러닝 중 상체가 휘거나 흔들릴 경우 허리와 어깨에 부하가 가해져 부상으로 이어질 수 있습니다. 코어에 집중해 바른 자세로 러닝하세요.",
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 족형
                Container(
                  height: 50,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "족형에 따른 주의사항",
                      style: GoogleFonts.nanumGothic(
                          color: Colors.white,
                          fontSize: 29,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.2),
                    ),
                  ],
                ),
                Container(
                  height: 5,
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 5.0),
                  child: Container(
                    width: 420,
                    height: 330,
                    decoration: BoxDecoration(
                      color: Color.fromARGB(255, 51, 51, 51),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          top: 22.0,
                          left: 22.0,
                          // right: 50.0,
                          child: Row(
                            children: [
                              Container(
                                width: 150,
                                height: 150,
                                decoration: BoxDecoration(
                                  shape: BoxShape.rectangle,
                                  color: Colors.grey.withAlpha(160),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    // API 이미지
                                    Image.network(
                                      "https://i.ibb.co/YQNKLpX/foot-heatmap1.png",
                                      height: 150, // 이미지 높이 조정
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(
                                width: 7,
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          top: 16,
                          left: 175.0,
                          child: Padding(
                            padding: const EdgeInsets.all(5.0),
                            child: Text(
                              "회원님의 족형은...",
                              style: GoogleFonts.nanumGothic(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 35,
                          left: 175.0,
                          child: Padding(
                            padding: const EdgeInsets.all(5.0),
                            child: Column(
                              children: [
                                if (footType == 'flat')
                                  Text(
                                    "평발",
                                    style: GoogleFonts.nanumGothic(
                                      color: Colors.white,
                                      fontSize: 35,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                if (footType == 'normal')
                                  Text(
                                    "정상",
                                    style: GoogleFonts.nanumGothic(
                                      color: Colors.white,
                                      fontSize: 35,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                if (footType == 'high')
                                  Text(
                                    "요족",
                                    style: GoogleFonts.nanumGothic(
                                      color: Colors.white,
                                      fontSize: 35,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          top: 90,
                          left: 172.0,
                          right: 13,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Column(
                              children: [
                                if (footType == 'flat')
                                  Text(
                                    "평발은 충격 흡수 능력이 낮아 피로 골절 및 신부전 증후군의 위험이 높습니다.",
                                    textAlign: TextAlign.justify,
                                    style: GoogleFonts.nanumGothic(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w200,
                                      letterSpacing: 0.2,
                                      height: 1.2,
                                    ),
                                  ),
                                if (footType == 'normal')
                                  Text(
                                    "평발은 충격 흡수 능력이 낮아 피로 골절 및 신부전 증후군의 위험이 높습니다.",
                                    textAlign: TextAlign.justify,
                                    style: GoogleFonts.nanumGothic(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w200,
                                      letterSpacing: 0.2,
                                      height: 1.2,
                                    ),
                                  ),
                                if (footType == 'high')
                                  Text(
                                    "요족은 체중의 앞력이 앞뒤로 집중되어 지간 신경종 및 아킬레스건 파손 위험이 있습니다.",
                                    textAlign: TextAlign.justify,
                                    style: GoogleFonts.nanumGothic(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w200,
                                      letterSpacing: 0.2,
                                      height: 1.2,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          top: 185,
                          left: 15,
                          right: 20,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Column(
                              children: [
                                if (footType == 'flat')
                                  Text(
                                    "발을 더 잘 지지해주는 러닝화를 선택하는 것이 중요합니다. 충격을 흡수하는 지지대가 있는 신발을 찾는 것이 좋습니다. 러닝 후 충분한 휴식과 스트레칭을 통해 발과 다리 근육을 풀어 부상을 예방하세요.",
                                    textAlign: TextAlign.justify,
                                    style: GoogleFonts.nanumGothic(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w200,
                                      letterSpacing: 0.2,
                                      height: 1.2,
                                    ),
                                  ),
                                if (footType == 'normal')
                                  Text(
                                    "발을 더 잘 지지해주는 러닝화를 선택하는 것이 중요합니다. 충격을 흡수하는 지지대가 있는 신발을 찾는 것이 좋습니다. 러닝 후 충분한 휴식과 스트레칭을 통해 발과 다리 근육을 풀어 부상을 예방하세요.",
                                    textAlign: TextAlign.justify,
                                    style: GoogleFonts.nanumGothic(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w200,
                                      letterSpacing: 0.2,
                                      height: 1.2,
                                    ),
                                  ),
                                if (footType == 'high')
                                  Text(
                                    "요족임요",
                                    textAlign: TextAlign.justify,
                                    style: GoogleFonts.nanumGothic(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w200,
                                      letterSpacing: 0.2,
                                      height: 1.2,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  height: 30,
                ),

                // 족형 상세 내용 확인 버튼
                Center(
                  child: Text(
                    "족형에 대해 더 자세히 알고싶나요?",
                    style: GoogleFonts.nanumGothic(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.05,
                    ),
                  ),
                ),
                Container(
                  height: 5,
                ),
                Center(
                  child: Container(
                    width: 280,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Color.fromARGB(255, 255, 100, 0),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "▷ 상세 내용 확인",
                              style: GoogleFonts.nanumGothic(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.01,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                          height: 1,
                        ),
                      ],
                    ),
                  ),
                ),

                // 케이던스
                Container(
                  height: 50,
                ),
                Text(
                  "케이던스 관련 주의사항",
                  style: GoogleFonts.nanumGothic(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
                SizedBox(
                  height: 8,
                ),
                MyContainer(
                  color: Color.fromARGB(255, 51, 51, 51),
                  borderRadius: BorderRadius.circular(30),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 350, // 칸 가로 확보 용
                          ),
                          Container(
                            child: Image.network(
                              "$img_url",
                            ),
                            height: 150,
                            width: 300,
                          ),
                          SizedBox(
                            height: 5, // 칸 가로 확보 용
                          ),
                          Text(
                            "이번 대회 케이던스: $cad",
                            style: GoogleFonts.nanumGothic(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            "평균 케이던스 보다 낮습니다.",
                            style: GoogleFonts.nanumGothic(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ]),
                  ),
                ),

                // 총분석
                Container(
                  height: 50,
                ),
                Text(
                  "총 분석 결과",
                  style: GoogleFonts.nanumGothic(
                    color: Color.fromARGB(255, 255, 100, 0),
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
                SizedBox(
                  height: 8,
                ),
                MyContainer(
                  color: Color.fromARGB(255, 51, 51, 51),
                  borderRadius: BorderRadius.circular(30),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 350, // 칸 가로 확보 용
                          ),
                          Text(
                            "1. $l1_message",
                            style: GoogleFonts.nanumGothic(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(
                            height: 4,
                          ),
                          Text(
                            "2. $l2_message",
                            style: GoogleFonts.nanumGothic(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(
                            height: 4,
                          ),
                          Text(
                            "3. $l3_message",
                            style: GoogleFonts.nanumGothic(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget sectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.nanumGothic(
        fontWeight: FontWeight.bold,
        fontSize: 22,
      ),
    );
  }

  Widget fillcontext(String text) {
    return Text(
      text,
      textAlign: TextAlign.justify,
      style: GoogleFonts.nanumGothic(
          color: Colors.white.withAlpha(220),
          fontWeight: FontWeight.w700,
          fontSize: 16,
          letterSpacing: 0.3),
    );
  }

  Widget roundedContainer(BuildContext context, String text) {
    return Container(
      padding: EdgeInsets.all(16),
      margin: EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text, style: GoogleFonts.nanumGothic(fontSize: 18)),
    );
  }
}
