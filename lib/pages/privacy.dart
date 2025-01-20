import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class PrivacyPolicy extends StatelessWidget {
  const PrivacyPolicy({Key? key}) : super(key: key);

  void _launchUrl(String url) async {
    if (!await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    )) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Política de Privacidad'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Política de Privacidad',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'En MiBus Conductor, respetamos y protegemos la privacidad de nuestros usuarios. Esta Política de Privacidad explica cómo recopilamos, usamos y protegemos la información personal que usted nos proporciona al usar nuestra aplicación.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            _sectionTitle('1. Responsable del Tratamiento de Datos'),
            const Text(
              'MiBus Conductor, desarrollador de la aplicación a cargo de Juan Carlos Limon Nieto. MiBus, con domicilio en Cda Fresnillo 134, Col. San José, México, es el responsable del tratamiento de sus datos personales. Si tiene alguna pregunta sobre este Aviso de Privacidad, puede contactarnos en:',
            ),
            InkWell(
              onTap: () => _launchUrl('mailto:contacto@mytrackingbus.com'),
              child: const Text(
                'contacto@mytrackingbus.com',
                style: TextStyle(
                    color: Colors.blue, decoration: TextDecoration.underline),
              ),
            ),
            const SizedBox(height: 24),
            _sectionTitle('2. Datos Personales que Recopilamos'),
            const Text(
              'MiBus Conductor recopila los siguientes datos personales para garantizar el funcionamiento adecuado de la aplicación:',
            ),
            _bulletPoints([
              'Nombre completo',
              'Número de teléfono',
              'Dirección de origen y destino',
              'Ubicación en tiempo real',
              'Correo electrónico',
            ]),
            const SizedBox(height: 24),
            _sectionTitle('3. Finalidad del Tratamiento de Datos'),
            const Text(
              'Los datos recopilados se utilizan exclusivamente para los siguientes fines:',
            ),
            _bulletPoints([
              'Proporcionar el servicio de transporte solicitado.',
              'Monitorear el trayecto de los autobuses en tiempo real.',
              'Garantizar la seguridad de los usuarios durante el viaje.',
              'Comunicar actualizaciones importantes sobre el servicio.',
            ]),
            const SizedBox(height: 24),
            _sectionTitle('4. Transferencia de Datos'),
            const Text(
              'MiBus Conductor no comparte tus datos personales con terceros sin tu consentimiento, salvo cuando sea requerido por ley o regulaciones aplicables.',
            ),
            const SizedBox(height: 24),
            _sectionTitle('5. Derechos del Usuario'),
            const Text(
              'Tienes derecho a acceder, rectificar, cancelar u oponerte al tratamiento de tus datos personales, conforme a la legislación vigente (Derechos ARCO). Para ejercer estos derechos, escríbenos a:',
            ),
            InkWell(
              onTap: () => _launchUrl('mailto:contacto@mytrackingbus.com'),
              child: const Text(
                'contacto@mytrackingbus.com',
                style: TextStyle(
                    color: Colors.blue, decoration: TextDecoration.underline),
              ),
            ),
            const SizedBox(height: 24),
            _sectionTitle('6. Seguridad de los Datos'),
            const Text(
              'Implementamos medidas técnicas, administrativas y físicas para proteger sus datos personales contra acceso no autorizado, pérdida o alteraciones.',
            ),
            const SizedBox(height: 24),
            _sectionTitle('7. Cambios al Aviso de Privacidad'),
            const Text(
              'Podemos actualizar este Aviso de Privacidad periódicamente para reflejar cambios en nuestras prácticas o en la legislación aplicable. Notificaremos cualquier modificación a través de nuestra aplicación.',
            ),
            const SizedBox(height: 24),
            _sectionTitle('8. Política de Retención y Eliminación de Datos'),
            const Text(
              'Conservamos tus datos personales únicamente durante el tiempo necesario para cumplir con los fines mencionados en este aviso o conforme a lo que la ley establezca. Si decides eliminar tu cuenta, tus datos serán eliminados de forma permanente, salvo que deban conservarse por requerimientos legales.',
            ),
            const SizedBox(height: 24),
            _sectionTitle('9. Contacto'),
            const Text(
              'Si tienes dudas o inquietudes sobre este Aviso de Privacidad o el manejo de tus datos personales, por favor contáctanos a través de:',
            ),
            InkWell(
              onTap: () => _launchUrl('mailto:contacto@mytrackingbus.com'),
              child: const Text(
                'contacto@mytrackingbus.com',
                style: TextStyle(
                    color: Colors.blue, decoration: TextDecoration.underline),
              ),
            ),
            InkWell(
              onTap: () =>
                  _launchUrl('https://mytrackingbus.com/privacy-policy'),
              child: const Text(
                'https://mytrackingbus.com/privacy-policy',
                style: TextStyle(
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Al usar nuestra aplicación, usted acepta este Aviso de Privacidad y el tratamiento de sus datos personales conforme a los términos aquí descritos.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  Widget _bulletPoints(List<String> points) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: points
          .map((point) => Padding(
                padding: const EdgeInsets.only(left: 16.0, bottom: 4.0),
                child: Row(
                  children: [
                    const Text('• ', style: TextStyle(fontSize: 16)),
                    Expanded(
                        child:
                            Text(point, style: const TextStyle(fontSize: 16))),
                  ],
                ),
              ))
          .toList(),
    );
  }
}
