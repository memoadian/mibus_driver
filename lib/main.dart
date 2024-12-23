import 'package:mibusconductor/pages/manual_register.dart';

import '/pages/route_guide.dart';
import '/services/socket.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'pages/login.dart';
import 'pages/qr_scanner.dart';
import 'providers/directions_provider.dart';

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late SharedPreferences prefs;

  Future<String> _getShared() async {
    prefs = await SharedPreferences.getInstance();

    if (prefs.getBool('isLoggedIn') == true) {
      return 'home';
    } else {
      return 'login';
    }
  }

  @override
  void initState() {
    super.initState();
    _getShared();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => DirectionProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => SocketService(),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'MiBus Conductor',
        routes: {
          'login': (context) => const Login(),
          'route_guide': (context) => const RouteGuide(),
          'qr': (context) => const QRScanner(),
          'manual': (context) => const ManualRegister(),
          //'qr_down': (context) => const QRReaderDown(),
          //'qr_reader': (context) => const QRReader(),
        },
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: _getInitialPage(),
      ),
    );
  }

  Widget _getInitialPage() {
    return FutureBuilder(
      future: _getShared(),
      builder: (context, snapshot) {
        switch (snapshot.data) {
          case 'home':
            return const RouteGuide();
          case 'login':
            return const Login();
          default:
            return Scaffold(
              body: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    CircularProgressIndicator(),
                    Text('Comprobando...'),
                  ],
                ),
              ),
            );
        }
      },
    );
  }
}
