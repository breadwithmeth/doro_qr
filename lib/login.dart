import 'dart:convert';

import 'package:doro_qr/recieving_qr.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  var URL_API = 'doro.kz';
  final login = TextEditingController();
  final password = TextEditingController();
  Future<bool> loginTablet(String login, String password) async {
    var url = Uri.https(URL_API, '/api/login.php');
    var response = await http.post(
      url,
      body: json.encode({'login': login, 'password': password}),
      headers: {"Content-Type": "application/json"},
    );
    var data = jsonDecode(response.body);
    
    print(response.statusCode);
    print(data);
    if (response.statusCode != 200) {
      return false;
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', data['key']);
      await prefs.setString('logo', data['logo']);
      await prefs.setString('first_name', data['first_name']);
      await prefs.setString('last_name', data['last_name']);
      await prefs.setString('photo', data['photo']);



      final token = prefs.getString('token') ?? 0;
      print(token);
      return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
          child: Container(
        width: 400,
        height: 200,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            TextFormField(
              controller: login,
              decoration: InputDecoration(border: OutlineInputBorder()),
            ),
            Spacer(),
            TextFormField(
              controller: password,
              decoration: InputDecoration(border: OutlineInputBorder()),
            ),
            Spacer(),
            ElevatedButton(
                onPressed: (() async {
                  Future<bool> isLoggedIn =
                      loginTablet(login.text, password.text);
                  if (await isLoggedIn) {
                    Navigator.push(context,
                        MaterialPageRoute(builder: ((context) => RecieveQR())));
                  }
                  print(login.text);
                }),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [Text("Войти"), Icon(Icons.arrow_forward_ios)],
                ))
          ],
        ),
      )),
    );
  }
}
