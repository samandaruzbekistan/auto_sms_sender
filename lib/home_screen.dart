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
  String _canSendSMSMessage = 'Check is not run.';
  bool sendDirect = false;
  bool _isLoading = false;
  bool _apiError = false;
  bool _internetError = false;
  TextEditingController _controllerApi = TextEditingController();
  TextEditingController _controllerMessage = TextEditingController();

  List<Map<String, dynamic>> ordersData = [];


  Future<void> fetchData(String url, String message) async {
    var status = await Permission.sms.status;
    int sended = 0;
    int notSend = 0;
    var request = http.Request('GET', Uri.parse(url));
    final connectivityResult = await (Connectivity().checkConnectivity());
    if(status.isDenied){
      await Permission.sms.request();
    }
    else{
      if (connectivityResult != ConnectivityResult.none) {
        setState(() {
          _isLoading = true;
        });
        http.StreamedResponse response = await request.send();
        if (response.statusCode == 200) {
          var data = await response.stream.bytesToString();
          List<dynamic> numbers = json.decode(data);
          if(numbers.length == 0){
            setState(() {
              _isLoading = false;
            });
            _numbersError2(context);
          }
          else{
            numbers.forEach((number) async {
              var result = await BackgroundSms.sendMessage(phoneNumber: "+998${number}", message: message);
              if (result == SmsStatus.sent) {
                sended++;
              } else {
                notSend++;
              }
            });
            setState(() {
              _isLoading = false;
            });
            _sendedAlert(context, sended, notSend);
          }
        } else {
          setState(() {
            _isLoading = false;
          });
          _apiError2(context);
        }
      } else {
        setState(() {
          _isLoading = false;
        });
        _internetError2(context);
      }
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
                  suffixIcon: Icon(Icons.text_fields),
                  border: OutlineInputBorder(),
                  helperMaxLines: 3,
                ),
                maxLines: 3,
                maxLength: 70,
              ),
              SizedBox(
                height: height * 0.01,
              ),
              SwitchListTile(
                  title: const Text("To'g'ridan-to'g'ri yuborish"),
                  subtitle: const Text(
                      "Qo'shimcha dialog oynasini o'tkazib yuborishimiz kerakmi?"),
                  value: sendDirect,
                  onChanged: (bool newValue) {
                    setState(() {
                      sendDirect = newValue;
                    });
                  }),
              SizedBox(
                height: height * 0.04,
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: width*0.04),
                child: ElevatedButton(
                  onPressed: () async {
                    fetchData(_controllerApi.text, _controllerMessage.text);
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
                        fontSize: width*0.05),
                  ),
                ),
              )
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