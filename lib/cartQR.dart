import 'dart:convert';

import 'package:doro_qr/EnterPinCode.dart';
import 'package:doro_qr/recieving_qr.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:onesignal_flutter/onesignal_flutter.dart';

class CartQR extends StatefulWidget {
  const CartQR({super.key, required this.qrText});
  final String? qrText;
  @override
  State<CartQR> createState() => _CartQRState();
}

class _CartQRState extends State<CartQR> {
  var URL_API = 'new.doro.kz';
  bool _requireConsent = true;
  String _debugLabelString = "";
  String? _emailAddress;
  String? _smsNumber;
  String? _externalUserId;
  String? _language;
  bool _enableConsentButton = false;
  String? player_id = '';
  String? qrText = '';
  String? qrType = '';
  Map<String, dynamic> data = {};
  String? summary = "";
  List<Widget> goods = [];

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
    Map<String, dynamic> dataT = json.decode(utf8.decode(response.bodyBytes));
    print(data);
    List goodsArr = dataT['goods'];
    List<Widget> goodsTemp = [];
    goodsArr.forEach((element) {
      goodsTemp.add(Container(
        padding: EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(element['name'] +"-"+element['amount'] + "x" + element['price'], style: TextStyle(fontWeight: FontWeight.w500, fontSize: 20),),
            Text(element['price_total'], style: TextStyle(fontWeight: FontWeight.w900, fontSize: 30),)
          ],
        ),
      ));
    });
    setState(() {
      data = dataT;
      goods = goodsTemp;
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    initPlatformState();
    openShoppingCart();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: TextButton(onPressed: (() {
        Navigator.push(context,
                MaterialPageRoute(builder: ((context) => RecieveQR())));
      }), child: Container(child: Icon(Icons.cancel_outlined), padding: EdgeInsets.symmetric(vertical: 20),),),
      floatingActionButtonLocation: FloatingActionButtonLocation.endTop,
      body: SafeArea(
          child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
            //     gradient: LinearGradient(colors: [
            //   Color(0xFFFC9842),
            //   Color(0xFFFE5F75),
            // ], transform: GradientRotation(-1))
            ),
        child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.7,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                      offset: Offset.fromDirection(10),
                      blurRadius: 10,
                      color: Colors.white)
                ],
                color: Colors.white,
                borderRadius: BorderRadius.all(Radius.circular(20))),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "?????????? ?????????? ??????????????:",
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 20,
                              color: Colors.black),
                        ),
                        Text(
                          data['summary'] ?? "0",
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 60,
                              color: Colors.black),
                        )
                      ],
                    ),
                    Column(
                      children: [
                        Container(
                          padding: EdgeInsets.all(0),
                          decoration: BoxDecoration(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(30)),
                              color: Colors.white.withOpacity(0.5)),
                          child: QrImage(
                            data: widget.qrText ?? "123123123",
                            version: QrVersions.auto,
                            size: 200,
                          ),
                        )
                      ],
                    ),
                    // Row(
                    //   mainAxisAlignment: MainAxisAlignment.center,
                    //   children: [
                    //     TextButton(
                    //       onPressed: (() {}),
                    //       child: Container(
                    //         padding: EdgeInsets.all(10),
                    //         decoration: BoxDecoration(
                    //             borderRadius: BorderRadius.all(Radius.circular(30)),
                    //             color: Colors.red),
                    //         child: Text(
                    //           "????????????",
                    //           style: TextStyle(
                    //               fontWeight: FontWeight.w400,
                    //               fontSize: 20,
                    //               color: Colors.white),
                    //         ),
                    //       ),
                    //     ),
                    //     TextButton(
                    //       onPressed: (() {
                    //         Navigator.push(
                    //             context,
                    //             MaterialPageRoute(
                    //                 builder: ((context) =>
                    //                     EnterPinCode(qrText: widget.qrText))));
                    //       }),
                    //       child: Container(
                    //         padding: EdgeInsets.all(10),
                    //         decoration: BoxDecoration(
                    //             borderRadius: BorderRadius.all(Radius.circular(30)),
                    //             color: Colors.white),
                    //         child: Text(
                    //           "??????-??????",
                    //           style: TextStyle(
                    //               fontWeight: FontWeight.w400,
                    //               fontSize: 20,
                    //               color: Colors.black),
                    //         ),
                    //       ),
                    //     )
                    //   ],
                    // )
                  ],
                ),
                Column(children: goods,)
              ],
            )),
      )),
    );
  }

  Future<void> initPlatformState() async {
    if (!mounted) return;

    OneSignal.shared.setLogLevel(OSLogLevel.verbose, OSLogLevel.none);

    OneSignal.shared.setRequiresUserPrivacyConsent(_requireConsent);

    OneSignal.shared
        .setNotificationOpenedHandler((OSNotificationOpenedResult result) {
      print('NOTIFICATION OPENED HANDLER CALLED WITH: ${result}');
      this.setState(() {
        _debugLabelString =
            "Opened notification: \n${result.notification.jsonRepresentation().replaceAll("\\n", "\n")}";
      });
    });

    OneSignal.shared.setNotificationWillShowInForegroundHandler(
        (OSNotificationReceivedEvent event) {
      print('FOREGROUND HANDLER CALLED WITH: ${event}');

      /// Display Notification, send null to not display
      print(event.notification.additionalData!['type']);
      event.complete(null);
      print("======================================================");
      // Map<String, dynamic> data = json.decode(event.notification.body!);
      // print(data['custom']);
      this.setState(() {
        _debugLabelString = event.notification.jsonRepresentation();
        qrText = event.notification.additionalData!['uuid'];
        qrType = event.notification.additionalData!['type'];
      });
      if (qrType == "sell_cart") {
        Navigator.push(context,
            MaterialPageRoute(builder: ((context) => CartQR(qrText: qrText))));
      }
      if (qrType == "close") {
        print(123);
        setState(() {
          Navigator.push(
              context, MaterialPageRoute(builder: ((context) => RecieveQR())));
        });
      }
    });

    OneSignal.shared
        .setInAppMessageClickedHandler((OSInAppMessageAction action) {
      this.setState(() {
        _debugLabelString =
            "In App Message Clicked: \n${action.jsonRepresentation().replaceAll("\\n", "\n")}";
      });
    });

    OneSignal.shared
        .setSubscriptionObserver((OSSubscriptionStateChanges changes) {
      print("SUBSCRIPTION STATE CHANGED: ${changes.jsonRepresentation()}");
    });

    OneSignal.shared.setPermissionObserver((OSPermissionStateChanges changes) {
      print("PERMISSION STATE CHANGED: ${changes.jsonRepresentation()}");
    });

    OneSignal.shared.setEmailSubscriptionObserver(
        (OSEmailSubscriptionStateChanges changes) {
      print("EMAIL SUBSCRIPTION STATE CHANGED ${changes.jsonRepresentation()}");
    });

    OneSignal.shared
        .setSMSSubscriptionObserver((OSSMSSubscriptionStateChanges changes) {
      print("SMS SUBSCRIPTION STATE CHANGED ${changes.jsonRepresentation()}");
    });

    OneSignal.shared.setOnWillDisplayInAppMessageHandler((message) {
      print("ON WILL DISPLAY IN APP MESSAGE ${message.messageId}");
    });

    OneSignal.shared.setOnDidDisplayInAppMessageHandler((message) {
      print("ON DID DISPLAY IN APP MESSAGE ${message.messageId}");
    });

    OneSignal.shared.setOnWillDismissInAppMessageHandler((message) {
      print("ON WILL DISMISS IN APP MESSAGE ${message.messageId}");
    });

    OneSignal.shared.setOnDidDismissInAppMessageHandler((message) {
      print("ON DID DISMISS IN APP MESSAGE ${message.messageId}");
    });

    // NOTE: Replace with your own app ID from https://www.onesignal.com
    await OneSignal.shared.setAppId("084f7684-70b9-440a-b775-68de73f2680a");
    final status = await OneSignal.shared.getDeviceState();
    final String? osUserID = status?.userId;
    print("===================");
    print(osUserID);
    setState(() {
      player_id = osUserID;
    });
    // final prefs = await SharedPreferences.getInstance();
    // final player_id = await prefs.getString('player_id') ?? false;
    // if (player_id == false) {
    //   print("player code is false");
    //   await prefs.setString('player_id', osUserID!);
    //   var url = Uri.https('new.doro.kz', 'api/tablet/addTablet.php');
    //   var response = await http.post(url, body: {'tablet_uuid': osUserID});
    //   print(response.statusCode);
    // } else {
    //   print(await prefs.getString("player_id"));
    //   print("player code is true");
    // }
    OneSignal.shared.setLaunchURLsInApp(false);

    bool requiresConsent = await OneSignal.shared.requiresUserPrivacyConsent();

    this.setState(() {
      _enableConsentButton = requiresConsent;
    });

    // Some examples of how to use In App Messaging public methods with OneSignal SDK
    oneSignalInAppMessagingTriggerExamples();

    OneSignal.shared.disablePush(false);

    // Some examples of how to use Outcome Events public methods with OneSignal SDK
    oneSignalOutcomeEventsExamples();

    bool userProvidedPrivacyConsent =
        await OneSignal.shared.userProvidedPrivacyConsent();
    print("USER PROVIDED PRIVACY CONSENT: $userProvidedPrivacyConsent");
    _handleConsent();
  }

  void _handleGetTags() {
    OneSignal.shared.getTags().then((tags) {
      if (tags == null) return;

      setState((() {
        _debugLabelString = "$tags";
      }));
    }).catchError((error) {
      setState(() {
        _debugLabelString = "$error";
      });
    });
  }

  void _handlePromptForPushPermission() {
    print("Prompting for Permission");
    OneSignal.shared.promptUserForPushNotificationPermission().then((accepted) {
      print("Accepted permission: $accepted");
    });
  }

  void _handleGetDeviceState() async {
    print("Getting DeviceState");
    OneSignal.shared.getDeviceState().then((deviceState) {
      print("DeviceState: ${deviceState?.jsonRepresentation()}");
      this.setState(() {
        _debugLabelString =
            deviceState?.jsonRepresentation() ?? "Device state null";
      });
    });
  }

  void _handleConsent() {
    print("Setting consent to true");
    OneSignal.shared.consentGranted(true);

    print("Setting state");
    this.setState(() {
      _enableConsentButton = false;
    });
  }

  void _handleSetLocationShared() {
    print("Setting location shared to true");
    OneSignal.shared.setLocationShared(true);
  }

  void _handleDeleteTag() {
    print("Deleting tag");
    OneSignal.shared.deleteTag("test2").then((response) {
      print("Successfully deleted tags with response $response");
    }).catchError((error) {
      print("Encountered error deleting tag: $error");
    });

    print("Deleting tags array");
    OneSignal.shared.deleteTags(['test']).then((response) {
      print("Successfully sent tags with response: $response");
    }).catchError((error) {
      print("Encountered an error sending tags: $error");
    });
  }

  void _handleSetExternalUserId() {
    print("Setting external user ID");
    if (_externalUserId == null) return;

    OneSignal.shared.setExternalUserId(_externalUserId!).then((results) {
      if (results == null) return;

      this.setState(() {
        _debugLabelString = "External user id set: $results";
      });
    });
  }

  void _handleRemoveExternalUserId() {
    OneSignal.shared.removeExternalUserId().then((results) {
      if (results == null) return;

      this.setState(() {
        _debugLabelString = "External user id removed: $results";
      });
    });
  }

  void _handleSendNotification() async {
    var deviceState = await OneSignal.shared.getDeviceState();

    if (deviceState == null || deviceState.userId == null) return;

    var playerId = deviceState.userId!;

    var imgUrlString =
        "http://cdn1-www.dogtime.com/assets/uploads/gallery/30-impossibly-cute-puppies/impossibly-cute-puppy-2.jpg";

    var notification = OSCreateNotification(
        playerIds: [playerId],
        content: "this is a test from OneSignal's Flutter SDK",
        heading: "Test Notification",
        iosAttachments: {"id1": imgUrlString},
        bigPicture: imgUrlString,
        buttons: [
          OSActionButton(text: "test1", id: "id1"),
          OSActionButton(text: "test2", id: "id2")
        ]);

    var response = await OneSignal.shared.postNotification(notification);

    this.setState(() {
      _debugLabelString = "Sent notification with response: $response";
    });
  }

  void _handleSendSilentNotification() async {
    var deviceState = await OneSignal.shared.getDeviceState();

    if (deviceState == null || deviceState.userId == null) return;

    var playerId = deviceState.userId!;

    var notification = OSCreateNotification.silentNotification(
        playerIds: [playerId], additionalData: {'test': 'value'});

    var response = await OneSignal.shared.postNotification(notification);

    this.setState(() {
      _debugLabelString = "Sent notification with response: $response";
    });
  }

  oneSignalInAppMessagingTriggerExamples() async {
    /// Example addTrigger call for IAM
    /// This will add 1 trigger so if there are any IAM satisfying it, it
    /// will be shown to the user
    OneSignal.shared.addTrigger("trigger_1", "one");

    /// Example addTriggers call for IAM
    /// This will add 2 triggers so if there are any IAM satisfying these, they
    /// will be shown to the user
    Map<String, Object> triggers = Map<String, Object>();
    triggers["trigger_2"] = "two";
    triggers["trigger_3"] = "three";
    OneSignal.shared.addTriggers(triggers);

    // Removes a trigger by its key so if any future IAM are pulled with
    // these triggers they will not be shown until the trigger is added back
    OneSignal.shared.removeTriggerForKey("trigger_2");

    // Get the value for a trigger by its key
    Object? triggerValue =
        await OneSignal.shared.getTriggerValueForKey("trigger_3");
    print("'trigger_3' key trigger value: ${triggerValue?.toString()}");

    // Create a list and bulk remove triggers based on keys supplied
    List<String> keys = ["trigger_1", "trigger_3"];
    OneSignal.shared.removeTriggersForKeys(keys);

    // Toggle pausing (displaying or not) of IAMs
    OneSignal.shared.pauseInAppMessages(false);
  }

  oneSignalOutcomeEventsExamples() async {
    // Await example for sending outcomes
    outcomeAwaitExample();

    // Send a normal outcome and get a reply with the name of the outcome
    OneSignal.shared.sendOutcome("normal_1");
    OneSignal.shared.sendOutcome("normal_2").then((outcomeEvent) {
      print(outcomeEvent.jsonRepresentation());
    });

    // Send a unique outcome and get a reply with the name of the outcome
    OneSignal.shared.sendUniqueOutcome("unique_1");
    OneSignal.shared.sendUniqueOutcome("unique_2").then((outcomeEvent) {
      print(outcomeEvent.jsonRepresentation());
    });

    // Send an outcome with a value and get a reply with the name of the outcome
    OneSignal.shared.sendOutcomeWithValue("value_1", 3.2);
    OneSignal.shared.sendOutcomeWithValue("value_2", 3.9).then((outcomeEvent) {
      print(outcomeEvent.jsonRepresentation());
    });
  }

  Future<void> outcomeAwaitExample() async {
    var outcomeEvent = await OneSignal.shared.sendOutcome("await_normal_1");
    print(outcomeEvent.jsonRepresentation());
  }

//   Future<void> addTablet() async {
//     // var url = Uri.https('new.doro.kz', 'api/tablet/addTablet.php');
//     // var response = await http.post(url);
//     // print('Response status: ${response.statusCode}');
//     // print('Response body: ${response.body}');
//     // var decodedResponse = jsonDecode(utf8.decode(response.bodyBytes)) as Map;
//     // print(decodedResponse['uuid']);
//     // final prefs = await SharedPreferences.getInstance();
//     // await prefs.setString('uuid', decodedResponse['uuid'].toString());
//     // setState(() {
//     //   _externalUserId = decodedResponse['uuid'].toString();
//     // });

//     _handleSetExternalUserId();
//   }
}
