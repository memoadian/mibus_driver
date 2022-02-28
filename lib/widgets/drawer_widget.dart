import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DrawerWidget extends StatefulWidget {
  const DrawerWidget({Key? key}) : super(key: key);

  @override
  State<DrawerWidget> createState() => _DrawerWidgetState();
}

class _DrawerWidgetState extends State<DrawerWidget> {
  final _storage = const FlutterSecureStorage();
  late SharedPreferences _prefs;

  String _name = '';
  String _email = '';
  String _image = '';
  String version = '';
  String buildNumber = '';

  @override
  void initState() {
    _getPrefs();
    _getData();
    _getInfoApp();
    super.initState();
  }

  void _getInfoApp() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();

    version = packageInfo.version;
    buildNumber = packageInfo.buildNumber;
  }

  void _getPrefs() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<void> _getData() async {
    _name = await _storage.read(key: 'name') ?? '';
    _email = await _storage.read(key: 'email') ?? '';
    _image = await _storage.read(key: 'image') ?? '';

    setState(() {
      _name = _name;
      _email = _email;
      _image = _image;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          UserAccountsDrawerHeader(
            currentAccountPicture: CircleAvatar(
              backgroundImage: (_image != "")
                  ? NetworkImage(
                      'https://apimedicapp.memoadian.com/uploads/images/$_image')
                  : const AssetImage('assets/logo.png') as ImageProvider,
            ),
            accountName: Text(_name),
            decoration: const BoxDecoration(
              color: Color(0xFF007AFE),
              image: DecorationImage(
                image: AssetImage('assets/background.png'),
                fit: BoxFit.cover,
              ),
            ),
            accountEmail: Text(_email),
          ),
          ListView(
            shrinkWrap: true,
            children: ListTile.divideTiles(
              context: context,
              tiles: [
                ListTile(
                  leading: const Icon(Icons.help),
                  title: const Text(
                    "Ayuda",
                    style: TextStyle(
                      color: Color(0xFF666666),
                    ),
                  ),
                  trailing: const Icon(Icons.arrow_right),
                  onTap: () => {},
                ),
                ListTile(
                  leading: const Icon(Icons.settings),
                  title: const Text(
                    "Configuración",
                    style: TextStyle(
                      color: Color(0xFF666666),
                    ),
                  ),
                  trailing: const Icon(Icons.arrow_right),
                  onTap: () => {},
                ),
                ListTile(
                  leading: const Icon(Icons.contact_page),
                  title: const Text(
                    "Contacto",
                    style: TextStyle(
                      color: Color(0xFF666666),
                    ),
                  ),
                  trailing: const Icon(Icons.arrow_right),
                  onTap: () => {},
                ),
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('Cerrar Sesión'),
                  onTap: () {
                    Navigator.pop(context);
                    _closeDialog(context);
                  },
                ),
                ListTile(
                  subtitle: Text(
                    "Versión: $version - Build: $buildNumber",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF666666),
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ).toList(),
          )
        ],
      ),
    );
  }

  void _closeDialog(context) {
    if (Platform.isAndroid) {
      showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text("Cerrar Sesión"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text(
                    "Confirma para cerrar tu sesión en este dispositivo",
                  )
                ],
              ),
              actions: [
                MaterialButton(
                  child: const Text('Aceptar'),
                  elevation: 5,
                  textColor: Colors.blue,
                  onPressed: () => {
                    _closeSession(context),
                  },
                ),
              ],
            );
          });
    } else {
      showCupertinoDialog(
        context: context,
        builder: (context) {
          return CupertinoAlertDialog(
            title: const Text("Cerrar sesión"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  "Confirma para cerrar tu sesión en este dispositivo",
                ),
              ],
            ),
            actions: [
              CupertinoDialogAction(
                isDestructiveAction: true,
                child: const Text("Cancelar"),
                onPressed: () => Navigator.pop(context),
              ),
              CupertinoDialogAction(
                isDefaultAction: true,
                child: const Text('Aceptar'),
                onPressed: () => {
                  Navigator.pop(context),
                  _closeSession(context),
                },
              ),
            ],
          );
        },
      );
    }
  }

  void _closeSession(context) {
    _storage.deleteAll();
    _prefs.clear();
    Navigator.of(context).pushNamedAndRemoveUntil(
      'login',
      (Route<dynamic> route) => false,
    );
  }
}
