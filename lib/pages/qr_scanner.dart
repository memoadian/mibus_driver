import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
//import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:http/http.dart' as http;
import '../consts/consts.dart' as consts;

class QRScanner extends StatelessWidget {
  const QRScanner({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrar Ascenso')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(
                top: 50, left: 100, right: 100, bottom: 60),
            child: Image.asset("assets/qr-code.png"),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, 'qr_reader');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[400],
              fixedSize: const Size(300, 50),
              textStyle: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            label: const Text('Registrar Ascenso'),
            icon: const Icon(Icons.upload),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 40),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, 'qr_down');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple[400],
                fixedSize: const Size(300, 50),
                textStyle: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              label: const Text('Registrar Descenso'),
              icon: const Icon(Icons.download),
            ),
          ),
        ],
      ),
    );
  }
}
