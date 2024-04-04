import 'dart:convert';

import 'package:background_sms/background_sms.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:rflutter_alert/rflutter_alert.dart';

class SendSms extends StatefulWidget {
  const SendSms({Key? key}) : super(key: key);

  @override
  State<SendSms> createState() => _SendSmsState();
}

class _SendSmsState extends State<SendSms> {
  bool sendDirect = false;
  bool _isLoading = false;
  int sended2 = 0;
  int notSend2 = 0;
  bool _permissionStatus = false;
  TextEditingController _controllerApi = TextEditingController();
  TextEditingController _controllerMessage = TextEditingController();

  List<Map<String, dynamic>> ordersData = [];

  Future<void> fetchData(String url, String message) async {
    var status = await Permission.sms.status;
    final connectivityResult = await (Connectivity().checkConnectivity());

    if (status.isDenied) {
      await Permission.sms.request();
      return; // Exit early if permission is not granted
    }

    if (connectivityResult == ConnectivityResult.none) {
      _internetError2(context);
      return; // Exit if there's no internet connectivity
    }

    setState(() {
      _isLoading = true;
    });

    http.Response response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      var data = json.decode(response.body);

      if (data.isEmpty) {
        setState(() {
          _isLoading = false;
        });
        _numbersError2(context);
        return; // Exit if there are no numbers to send SMS
      }

      int sendedCount = 0;
      int notSendCount = 0;

      for (int i = 0; i < data.length; i++) {
        var result = await BackgroundSms.sendMessage(
          phoneNumber: "+998${data[i]}",
          message: message,
        );

        if (result == SmsStatus.sent) {
          sendedCount++;
        } else {
          notSendCount++;
        }

        if ((i + 1) % 20 == 0) {
          // If 20 SMS sent, wait for 10 seconds
          await Future.delayed(Duration(seconds: 10));
        }
      }

      setState(() {
        _isLoading = false;
      });

      _sendedAlert(context, sendedCount, notSendCount);
    } else {
      setState(() {
        _isLoading = false;
      });
      _apiError2(context);
    }
  }


  @override
  void initState() {
    super.initState();
    _checkPermissionStatus();
  }

  Future<void> _checkPermissionStatus() async {
    final status = await Permission.sms.status;
    if (status.isGranted) {
      setState(() {
        _permissionStatus = true;
      });
    }
  }

  Future<void> _requestPermission() async {
    final status = await Permission.sms.request();
    if (status.isGranted) {
      setState(() {
        _permissionStatus = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.width;
    var height = MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Auto SMS sender by Samandar',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: width * 0.05),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: height * 0.05,
              ),
              TextField(
                controller: _controllerApi,
                decoration: const InputDecoration(
                  labelText: "API url",
                  suffixIcon: Icon(Icons.link),
                  border: OutlineInputBorder(),
                  helperMaxLines: 3,
                ),
              ),
              SizedBox(
                height: height * 0.01,
              ),
              Text(
                '▪ O\'zbekiston Respublikasi hududi ishlaydi',
                style: TextStyle(fontSize: width * 0.04),
              ),
              Text(
                '▪ URL manzili http bilan boshlansin',
                style: TextStyle(fontSize: width * 0.04),
              ),
              Text(
                '▪ Raqamlar davlat kodisiz (+998) kelsin',
                style: TextStyle(fontSize: width * 0.04),
              ),
              Text(
                '▪ API example: ["901234567","971234567"]',
                style: TextStyle(fontSize: width * 0.04),
              ),
              SizedBox(
                height: height * 0.05,
              ),
              TextField(
                controller: _controllerMessage,
                decoration: const InputDecoration(
                  labelText: "SMS matni",
                  suffixIcon: Icon(Icons.chat_bubble_outline),
                  border: OutlineInputBorder(),
                  helperMaxLines: 3,
                ),
                maxLines: 3,
                maxLength: 70,
              ),
              SizedBox(
                height: height * 0.04,
              ),
              _permissionStatus
                  ? Container(
                      padding: EdgeInsets.symmetric(horizontal: width * 0.04),
                      child: ElevatedButton(
                        onPressed: () async {
                          fetchData(
                              _controllerApi.text, _controllerMessage.text);
                        },
                        style: ElevatedButton.styleFrom(
                          // elevation: 20,
                          backgroundColor: Colors.blue,
                          minimumSize: const Size.fromHeight(60),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : Text(
                                "Yuborish",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: width * 0.05),
                              ),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "SMS yuborish uchun\nqurilmada ruxsat berilmagan",
                          style: TextStyle(color: Colors.red),
                        ),
                        ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                            ),
                            onPressed: () async {
                              await _requestPermission();
                            },
                            child: Text(
                              "Ruxsat berish",
                              style: TextStyle(color: Colors.white),
                            ))
                      ],
                    ),
              SizedBox(
                height: height * 0.2,
              ),
              Text("Dasturchi: Samandar Sariboyev", textAlign: TextAlign.center,),
              Text("Websayt: goldapps.uz", textAlign: TextAlign.center,),
              Text("Telegram: @Samandar_developer", textAlign: TextAlign.center,),
            ],
          ),
        ),
      ),
    );
  }
}

_numbersError2(context) {
  Alert(
    context: context,
    type: AlertType.error,
    title: "Xatolik!",
    desc: "Raqamlar soni 0 ta",
    buttons: [
      DialogButton(
        child: Text(
          "OK",
          style: TextStyle(color: Colors.white, fontSize: 14),
        ),
        onPressed: () => Navigator.pop(context),
        color: Colors.black,
        radius: BorderRadius.circular(0.0),
      ),
    ],
  ).show();
}

_permissionError2(context) {
  Alert(
    context: context,
    type: AlertType.error,
    title: "Xatolik!",
    desc: "SMS yuborish uchun qurilmada ruxsat berilmagan",
    buttons: [
      DialogButton(
        child: Text(
          "OK",
          style: TextStyle(color: Colors.white, fontSize: 14),
        ),
        onPressed: () => Navigator.pop(context),
        color: Colors.black,
        radius: BorderRadius.circular(0.0),
      ),
    ],
  ).show();
}

_apiError2(context) {
  Alert(
    context: context,
    type: AlertType.error,
    title: "Xatolik!",
    desc: "API da nosozlik",
    buttons: [
      DialogButton(
        child: Text(
          "OK",
          style: TextStyle(color: Colors.white, fontSize: 14),
        ),
        onPressed: () => Navigator.pop(context),
        color: Colors.black,
        radius: BorderRadius.circular(0.0),
      ),
    ],
  ).show();
}

_sendedAlert(context, int sended, int notSend) {
  Alert(
    context: context,
    type: AlertType.success,
    title: "Xabar yuborildi!",
    desc: "Yuborildi: ${sended}\nYuborilmadi: ${notSend}",
    buttons: [
      DialogButton(
        child: Text(
          "OK",
          style: TextStyle(color: Colors.white, fontSize: 14),
        ),
        onPressed: () => Navigator.pop(context),
        color: Colors.black,
        radius: BorderRadius.circular(0.0),
      ),
    ],
  ).show();
}

_internetError2(context) {
  Alert(
    context: context,
    type: AlertType.error,
    title: "Xatolik!",
    desc: "Internetga ulanmagansiz",
    buttons: [
      DialogButton(
        child: Text(
          "OK",
          style: TextStyle(color: Colors.white, fontSize: 14),
        ),
        onPressed: () => Navigator.pop(context),
        color: Colors.black,
        radius: BorderRadius.circular(0.0),
      ),
    ],
  ).show();
}
