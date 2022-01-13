import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:login_app/src/pages/login.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Widget _buildContainer(BuildContext context, snapshot) {
    // login 정보 체크
    if (snapshot.hasData) {
      // TODO: 메인 화면 구성
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("${snapshot.data.displayName}님 환영합니다."),
            TextButton(onPressed: () {
              FirebaseAuth.instance.signOut();
            }, child: const Text("로그아웃"))
          ],
        ),
      );
    } else {
      // auth 없음
      return const LoginScreen();
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: StreamBuilder(
          stream: FirebaseAuth.instance.authStateChanges(),
          //builder: (BuildContext context, AsyncSnapshot<User> snapshot) {
          builder: (context, snapshot) {
            return _buildContainer(context, snapshot);
          }
      )
    );
  }
}