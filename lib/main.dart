import 'dart:convert';
import 'package:doro_qr/login.dart';
import 'package:doro_qr/qr.dart';
import 'package:doro_qr/recieving_qr.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
//import OneSignal
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:wakelock/wakelock.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _debugLabelString = "";
  String? tablet_uuid = "";
  String? _emailAddress;
  String? _smsNumber;
  String? _externalUserId;
  String? _language;
  bool _enableConsentButton = false;
  Widget redir = Login();
  // CHANGE THIS parameter to true if you want to test GDPR privacy consent
  bool _requireConsent = true;

  @override
  void initState() {
    super.initState();
    Wakelock.disable();
    Wakelock.enable();
    Wakelock.toggle(enable: true);
    checkIfUserLoggedIn();
  }

  Future<void> checkIfUserLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? false;
    print(token);
    if (token != false) {
      setState(() {
        redir = RecieveQR();
      });
      redir = RecieveQR();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: redir,
      // Scaffold(
      //   body: Stack(
      //     alignment: Alignment.center,
      //     children: [
      //       Text(_debugLabelString),
      //       Center(
      //         child: checkTablet(),
      //       ),
      //     ],
      //   ),
      // ),
    );
  }

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       home: Scaffold(
//           appBar: AppBar(
//             title: const Text('OneSignal Flutter Demo'),
//             backgroundColor: Color.fromARGB(255, 212, 86, 83),
//           ),
//           body: Container(
//             padding: EdgeInsets.all(10.0),
//             child: SingleChildScrollView(
//               child: Table(
//                 children: [
//                   TableRow(children: [
//                     OneSignalButton("Prompt for Push Permission",
//                         _handlePromptForPushPermission, !_enableConsentButton)
//                   ]),
//                   TableRow(children: [
//                     OneSignalButton("Provide GDPR Consent", _handleConsent,
//                         _enableConsentButton)
//                   ]),
//                   TableRow(children: [
//                     TextField(
//                       textAlign: TextAlign.center,
//                       decoration: InputDecoration(
//                           hintText: "External User ID",
//                           labelStyle: TextStyle(
//                             color: Color.fromARGB(255, 212, 86, 83),
//                           )),
//                       onChanged: (text) {
//                         this.setState(() {
//                           _externalUserId = text == "" ? null : text;
//                         });
//                       },
//                     )
//                   ]),
//                   TableRow(children: [
//                     Container(
//                       height: 8.0,
//                     )
//                   ]),
//                   TableRow(children: [
//                     OneSignalButton("Set External User ID",
//                         _handleSetExternalUserId, !_enableConsentButton)
//                   ]),
//                   TableRow(children: [
//                     OneSignalButton("Remove External User ID",
//                         _handleRemoveExternalUserId, !_enableConsentButton)
//                   ]),
//                   TableRow(children: [
//                     TextField(
//                       textAlign: TextAlign.center,
//                       decoration: InputDecoration(
//                           hintText: "Language",
//                           labelStyle: TextStyle(
//                             color: Color.fromARGB(255, 212, 86, 83),
//                           )),
//                       onChanged: (text) {
//                         this.setState(() {
//                           _language = text == "" ? null : text;
//                         });
//                       },
//                     )
//                   ]),
//                   TableRow(children: [
//                     Container(
//                       height: 8.0,
//                     )
//                   ]),
//                   TableRow(children: [
//                     Container(
//                       child: Text(_debugLabelString),
//                       alignment: Alignment.center,
//                     )
//                   ]),
//                 ],
//               ),
//             ),
//           )),
//     );
//   }
// }

// typedef void OnButtonPressed();

// class OneSignalButton extends StatefulWidget {
//   final String title;
//   final OnButtonPressed onPressed;
//   final bool enabled;

//   OneSignalButton(this.title, this.onPressed, this.enabled);

//   State<StatefulWidget> createState() => OneSignalButtonState();
// }

// class OneSignalButtonState extends State<OneSignalButton> {
//   @override
//   Widget build(BuildContext context) {
//     // TODO: implement build
//     return Table(
//       children: [
//         TableRow(children: [
//           ElevatedButton(
//             child: Text(widget.title),
//             onPressed: widget.enabled ? widget.onPressed : null,
//           )
//         ]),
//         TableRow(children: [
//           Container(
//             height: 8.0,
//           )
//         ]),
//       ],
//     );
//   }
}
//