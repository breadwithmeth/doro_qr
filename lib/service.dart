import 'dart:async';
import 'dart:convert';

import 'package:doro_qr/EnterPinCode.dart';
import 'package:doro_qr/cartQR.dart';
import 'package:doro_qr/recieving_qr.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:onesignal_flutter/onesignal_flutter.dart';

class Service extends StatefulWidget {
  const Service({super.key, required this.qrText});
  final String? qrText;
  @override
  State<Service> createState() => _ServiceState();
}

class _ServiceState extends State<Service> {
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

  String? summary = "";
  Widget serviceWidget = Container();
  Future<int> visitService(String session_id) async {
    final prefs = await SharedPreferences.getInstance();
    var url = Uri.https(URL_API, '/api/service/visitService.php');
    var response = await http.post(
      url,
      body: json.encode({"session_id": session_id}),
      headers: {
        "Content-Type": "application/json",
        "AUTH": prefs.getString('token')!
      },
    );
    print(response.statusCode);
    // print(response.body);
    getServiceSchedule();
    return response.statusCode;
  }

  Future<void> getServiceSchedule() async {
    final prefs = await SharedPreferences.getInstance();
    var url = Uri.https(URL_API, '/api/service/getServiceScheduleSingle.php');
    var response = await http.post(
      url,
      body: json.encode({"uuid": widget.qrText}),
      headers: {
        "Content-Type": "application/json",
        "AUTH": prefs.getString('token')!
      },
    );
    // var data = jsonDecode(response.body);
    Map<String, dynamic> data = json.decode(utf8.decode(response.bodyBytes));
    List customers = data['enrolled'];
    List<Widget> customersTemp = [];
    customers.forEach((element) {
      Widget status = Container();
      if (element['status'] == "1") {
        status = Icon(
          Icons.done,
          color: Colors.green,
        );
      } else {
        status = TextButton(
            onPressed: (() {
              visitService(element['session_id']);
            }),
            child: Text("Отметить"));
      }
      customersTemp.add(Container(
        padding: EdgeInsets.all(30),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              element['customer_name'],
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            status
          ],
        ),
      ));
    });
    Widget tempWidget = ListView(
      children: [
        Container(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data['service_name'],
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700),
              ),
              Text(data['provider_name'])
            ],
          ),
        ),
        Column(
          children: customersTemp,
        )
      ],
    );
    setState(() {
      serviceWidget = tempWidget;
    });
    print(data);
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    initPlatformState();
    getServiceSchedule();
    Timer.periodic(new Duration(seconds: 10), (timer) {
      getServiceSchedule();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: TextButton(
          onPressed: (() {
            Navigator.push(context,
                MaterialPageRoute(builder: ((context) => RecieveQR())));
          }),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Icon(Icons.cancel_outlined),
          )),
      floatingActionButtonLocation: FloatingActionButtonLocation.endTop,
      body: SafeArea(child: serviceWidget),
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
