import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class EnterPinCode extends StatefulWidget {
  const EnterPinCode({super.key, this.qrText});
  final String? qrText;

  @override
  State<EnterPinCode> createState() => _EnterPinCodeState();
}

class _EnterPinCodeState extends State<EnterPinCode> {
  var URL_API = 'new.doro.kz';
  String? summary = "";
  String? password = null;

  Future<void> openShoppingCart() async {
    final prefs = await SharedPreferences.getInstance();
    var url =
        Uri.https(URL_API, '/api/shopping_cart/getShoppingCartTablet.php');
    var response = await http.post(
      url,
      body: json.encode({"uuid": widget.qrText}),
      headers: {
        "Content-Type": "application/json",
        "AUTH": prefs.getString('token')!
      },
    );
    var data = jsonDecode(response.body);

    setState(() {
      summary = data['summary'];
    });
  }

  Widget getButton(String value) {
    return TextButton(
      onPressed: (() {
        setState(() {
          if (password == null) {
            password = value;
          } else {
            if (password!.length < 6) {
              password = password! + value;
            }
          }
        });
      }),
      child: Container(
          height: MediaQuery.of(context).size.width * 0.2,
          width: MediaQuery.of(context).size.width * 0.2,
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(10)),
              color: Colors.grey.shade900),
          child: Text(
            value,
            style: TextStyle(
                color: Colors.white,
                fontSize: MediaQuery.of(context).size.width * 0.1,
                fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          )),
    );
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    openShoppingCart();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            password ?? "Введите свой пин-код",
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: MediaQuery.of(context).size.width * 0.1,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [getButton("7"), getButton("8"), getButton("9")]),
              Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [getButton("4"), getButton("5"), getButton("6")]),
              Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [getButton("1"), getButton("2"), getButton("3")]),
              Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextButton(
                      onPressed: (() {
                        setState(() {
                          password = null;
                        });
                      }),
                      child: Container(
                          height: MediaQuery.of(context).size.width * 0.2,
                          width: MediaQuery.of(context).size.width * 0.2,
                          padding: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(10)),
                              color: Colors.grey.shade900),
                          child: Icon(
                            Icons.cancel_outlined,
                            size: MediaQuery.of(context).size.width * 0.1,
                          )),
                    ),
                    getButton("0"),
                    TextButton(
                      onPressed: (() {}),
                      child: Container(
                          height: MediaQuery.of(context).size.width * 0.2,
                          width: MediaQuery.of(context).size.width * 0.2,
                          padding: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(10)),
                              color: Colors.grey.shade900),
                          child: Icon(
                            Icons.arrow_forward_ios,
                            size: MediaQuery.of(context).size.width * 0.1,
                          )),
                    ),
                  ]),
            ],
          )
        ],
      )),
    );
  }
}
