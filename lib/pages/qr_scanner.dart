import 'package:flutter/material.dart';
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';

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
          Padding(
            padding: const EdgeInsets.only(top: 10, left: 20, right: 20),
            child: ElevatedButton.icon(
              onPressed: () async {
                String? res = await SimpleBarcodeScanner.scanBarcode(
                  context,
                  barcodeAppBar: const BarcodeAppBar(
                    appBarTitle: 'Test',
                    centerTitle: false,
                    enableBackButton: true,
                    backButtonIcon: Icon(Icons.arrow_back_ios),
                  ),
                  isShowFlashIcon: true,
                  delayMillis: 500,
                  cameraFace: CameraFace.back,
                  scanFormat: ScanFormat.ONLY_BARCODE,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[400],
                fixedSize: Size(MediaQuery.of(context).size.width, 50),
              ),
              label: const Text(
                'Registrar Ascenso',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              icon: const Icon(
                Icons.upload,
                color: Colors.white,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 20, left: 20, right: 20),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, 'manual');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[100],
                fixedSize: Size(MediaQuery.of(context).size.width, 50),
              ),
              label: const Text(
                'Registro Manual',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              icon: const Icon(
                Icons.keyboard,
                color: Colors.white,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 20, left: 20, right: 20),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, 'qr_down');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[100],
                fixedSize: Size(MediaQuery.of(context).size.width, 50),
              ),
              label: const Text(
                'Registrar Descenso',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              icon: const Icon(
                Icons.download,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
