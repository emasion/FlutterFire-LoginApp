
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:login_app/src/pages/home.dart';
import '../firebase_options.dart';

class AppPage extends StatelessWidget {
  const AppPage({Key? key}) : super(key: key);


  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform
      ),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Text("firebase load fail"),
          );
        }
        // firebase 사용 준비?
        if (snapshot.connectionState == ConnectionState.done) {
          // 완료 - home으로 보낸다.
          return const HomePage();
        }

        // progress 출력
        return const CircularProgressIndicator();
      },
    );
  }
}