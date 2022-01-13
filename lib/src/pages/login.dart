import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_auth/flutter_web_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

const String BASE_URL = "https://crawling-weak-canid.glitch.me";
const String clientIdForKakao = "6da88371e19967925299e460a5a07470";
const String clientIdForNaver = "hMEIdUcn1A2IYZmO35T4";
const String clientSecretForNaver = "PDGJp8FPsb";
const String callbackUrlScheme = 'callback';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool? isChecked = false;

  Future<UserCredential> _signInWithGoogle() async {
    final GoogleSignInAccount? _googleUser = await GoogleSignIn().signIn();
    final GoogleSignInAuthentication _googleAuth = await _googleUser!.authentication;
    final OAuthCredential credential = GoogleAuthProvider.credential(
      accessToken: _googleAuth.accessToken,
      idToken: _googleAuth.idToken,
    );
    return await FirebaseAuth.instance.signInWithCredential(credential);
  }

  Future<UserCredential> _signInWithKakao() async {
    final clientState = const Uuid().v4();
    final authUri = Uri.https('kauth.kakao.com', '/oauth/authorize', {
      'response_type': 'code',
      'client_id': clientIdForKakao,
      'response_mode': 'form_post',
      'redirect_uri': '${BASE_URL}/callbacks/kakao/sign_in',
      'scope': 'account_email profile_image profile_nickname',
      'state': clientState,
    });

    // 인증 요청 - kakao 인증 화면 뜬다
    final authResponse = await FlutterWebAuth.authenticate(
        url: authUri.toString(),
        callbackUrlScheme: callbackUrlScheme
    );
    final code = Uri.parse(authResponse).queryParameters['code'];
    print(code);

    // body에 들은 code값을 인증 API에 호출
    final tokenUrl = Uri.parse('https://kauth.kakao.com/oauth/token');
    final tokenResponse = await http.post(
        tokenUrl,
        body: {
          'grant_type': 'authorization_code',
          'client_id': clientIdForKakao,
          'redirect_uri': '${BASE_URL}/callbacks/kakao/sign_in',
          'code': code
        });

    // JSON decode
    Map<String, dynamic> tokenResponseBody = json.decode(tokenResponse.body);

    // 내 도메인으로 카카오 토큰 전송
    final sendTokenUri = Uri.parse('${BASE_URL}/callbacks/kakao/token');
    final response = await http.post(
        sendTokenUri,
        body: {
          "accessToken": tokenResponseBody['access_token']
        });
    return FirebaseAuth.instance.signInWithCustomToken(response.body);
  }

  Future<UserCredential> _signInWithNaver() async {
    final clientState = const Uuid().v4();
    final url = Uri.https('nid.naver.com', '/oauth2.0/authorize', {
      'response_type': 'code',
      'client_id': clientIdForNaver,
      'redirect_uri': '${BASE_URL}/callbacks/naver/sign_in',
      'state': clientState,
    });

    // 인증 요청 - naver 인증 화면 뜬다
    final authResponse = await FlutterWebAuth.authenticate(
        url: url.toString(),
        callbackUrlScheme: callbackUrlScheme);
    final code = Uri.parse(authResponse).queryParameters["code"];
    //
    final tokenUrl = Uri.parse('https://nid.naver.com/oauth2.0/token');
    final tokenResponse = await http.post(
        tokenUrl,
        body: {
          'grant_type': 'authorization_code',
          'client_id': clientIdForNaver,
          'client_secret': clientSecretForNaver,
          'code': code,
          'state': clientState,
        });

    // JSON decode
    Map<String, dynamic> tokenResponseBody = json.decode(tokenResponse.body);

    // 내 도메인으로 카카오 토큰 전송
    final sendTokenUri = Uri.parse('${BASE_URL}/callbacks/naver/token');
    final response = await http.post(
        sendTokenUri,
        body: {
          "accessToken": tokenResponseBody['access_token']
        });
    return FirebaseAuth.instance.signInWithCustomToken(response.body);
  }

  Future<UserCredential> _signInWithApple() async {
    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
    );
    final oauthCredential = OAuthProvider("apple.com").credential(
      idToken: appleCredential.identityToken,
      accessToken: appleCredential.authorizationCode,
    );
    return await FirebaseAuth.instance.signInWithCredential(oauthCredential);
  }

  Widget _buildLogoButton({
    required String image,
    required VoidCallback onPressed,
  }) {
    return FloatingActionButton(
      backgroundColor: Colors.white,
      onPressed: onPressed,
      child: SizedBox(
        height: 30,
        child: Image.asset(image),
      ),
    );
  }

  Widget _buildSocialButtons() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildLogoButton(
          image: 'assets/images/kakao_logo.png',
          onPressed: _signInWithKakao,
        ),
        _buildLogoButton(
          image: 'assets/images/naver_logo.png',
          onPressed: _signInWithNaver,
        ),
        _buildLogoButton(
          image: 'assets/images/google_logo.png',
          onPressed: _signInWithGoogle,
        ),
        _buildLogoButton(
          image: 'assets/images/apple_logo.png',
          onPressed: _signInWithApple,
        ),
      ],
    );
  }

  Widget _buildSignUpQuestion() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Don\t have an Account? ',
          style: TextStyle(
            fontFamily: 'PT-Sans',
            fontSize: 16,
            color: Colors.white,
          ),
        ),
        InkWell(
          child: const Text(
            'Sing Up',
            style: TextStyle(
              fontFamily: 'PT-Sans',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          onTap: () {},
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF5967ff),
                Color(0xFF5374ff),
                Color(0xFF5180ff),
                Color(0xFF538bff),
                Color(0xFF5995ff),
              ],
            ),
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
              ).copyWith(top: 20),
              child: Column(
                children: [
                  Container(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      color: Colors.white,
                      iconSize: 30,
                      icon: const Icon(Icons.close),
                      tooltip: '종료',
                      onPressed: () {
                        SystemNavigator.pop();
                      },
                    ),
                  ),
                  const Text(
                    '로그인',
                    style: TextStyle(
                      fontFamily: 'PT-Sans',
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(
                    height: 40,
                  ),
                  _buildSocialButtons(),
                  const SizedBox(
                    height: 30,
                  ),
                  _buildSignUpQuestion()
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}