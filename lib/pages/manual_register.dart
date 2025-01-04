import 'package:flutter/material.dart';

class ManualRegister extends StatefulWidget {
  const ManualRegister({Key? key}) : super(key: key);

  @override
  _ManualRegisterState createState() => _ManualRegisterState();
}

class _ManualRegisterState extends State<ManualRegister> {
  final _nameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrar Ascenso')),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            child: const Text(
              "Ingresa tus datos de registro manual",
              style: TextStyle(fontSize: 20),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            child: TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: "Código de registro",
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              //
            },
            child: const Text("Registrar"),
          ),
        ],
      ),
    );
  }
}
