import 'dart:async';
import 'dart:convert'; // Para decodificar los bytes del ESP32 a String
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_bluetooth/flutter_web_bluetooth.dart'; // Paquete BLE Web

class MonitoringScreen extends StatefulWidget {
  final DocumentSnapshot patient;

  const MonitoringScreen({
    super.key,
    required this.patient,
  });

  @override
  State<MonitoringScreen> createState() => _MonitoringScreenState();
}

class _MonitoringScreenState extends State<MonitoringScreen> {
  Timer? timerDuracion;
  int segundos = 0;
  
  int frActual = 0; // Empezamos en 0 hasta recibir el primer dato
  final List<int> valoresFR = [];
  bool monitoreando = false;

  // Variables de Bluetooth
  bool bleSoportado = false;
  bool dispositivoConectado = false;
  BluetoothDevice? _dispositivoBLE;
  StreamSubscription? _suscripcionDatos;
  final List<double> datosGrafica = [];
  // UUIDs exactos de tu código ESP32
  final String serviceUUID = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
  final String characteristicUUID = "beb5483e-36e1-4688-b7f5-ea07361b26a8";

  @override
  void initState() {
    super.initState();
    _verificarSoporteBLE();
  }

  // Verifica si el navegador soporta Web Bluetooth
  Future<void> _verificarSoporteBLE() async {
    final isAvailable = await FlutterWebBluetooth.instance.isAvailable.first;
    setState(() {
      bleSoportado = isAvailable;
    });
  }

  // Función que se ejecuta al presionar "Conectar Banda"
  Future<void> conectarBandaBLE() async {
    if (!bleSoportado) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tu navegador no soporta Web Bluetooth (Usa Chrome o Edge).')),
      );
      return;
    }

    try {
      // 1. Pedir al navegador que busque dispositivos con nuestro Servicio UUID
      final device = await FlutterWebBluetooth.instance.requestDevice(
        RequestOptionsBuilder([
          RequestFilterBuilder(services: [serviceUUID])
        ]),
      );

      // 2. Conectar al dispositivo
      await device.connect();
      
      setState(() {
        _dispositivoBLE = device;
        dispositivoConectado = true;
        monitoreando = true;
      });

      // Iniciar el cronómetro de duración de la sesión
      _iniciarCronometro();

      // 3. Buscar el servicio y la característica
      final services = await device.discoverServices();
      final service = services.firstWhere((s) => s.uuid == serviceUUID);
      final characteristic = await service.getCharacteristic(characteristicUUID);

      // 4. Suscribirse a las notificaciones (pCharacteristic->notify() en el ESP32)
      await characteristic.startNotifications();
      
      _suscripcionDatos = characteristic.value.listen((data) {
        final textoRecibido = utf8.decode(data.buffer.asUint8List()).trim();

        // Si el texto empieza con "V:", es un punto para la gráfica
        if (textoRecibido.startsWith('V:')) {
          final valorOnda = double.tryParse(textoRecibido.substring(2));
          if (valorOnda != null) {
            setState(() {
              datosGrafica.add(valorOnda);
              // Mantenemos solo los últimos 100 puntos para que la gráfica avance
              if (datosGrafica.length > 100) {
                datosGrafica.removeAt(0);
              }
            });
          }
        } 
        // Si el texto empieza con "F:", es la Frecuencia Respiratoria
        else if (textoRecibido.startsWith('F:')) {
          final frRecibida = int.tryParse(textoRecibido.substring(2));
          if (frRecibida != null && frRecibida > 0) {
            setState(() {
              frActual = frRecibida;
              valoresFR.add(frActual);
            });
          }
        }
      });

    } catch (e) {
      debugPrint("Error conectando BLE: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al conectar o conexión cancelada.')),
      );
    }
  }

  void _iniciarCronometro() {
    timerDuracion = Timer.periodic(const Duration(seconds: 1), (_) {
      if (monitoreando) {
        setState(() {
          segundos++;
        });
      }
    });
  }

  double get frPromedio {
    if (valoresFR.isEmpty) return 0;
    final suma = valoresFR.reduce((a, b) => a + b);
    return suma / valoresFR.length;
  }

  int get frMinima {
    if (valoresFR.isEmpty) return 0;
    return valoresFR.reduce(min);
  }

  int get frMaxima {
    if (valoresFR.isEmpty) return 0;
    return valoresFR.reduce(max);
  }

  String get tiempoFormateado {
    final minutos = segundos ~/ 60;
    final segundosRestantes = segundos % 60;
    return '${minutos.toString().padLeft(2, '0')}:${segundosRestantes.toString().padLeft(2, '0')}';
  }

  void finalizarSesion() {
    timerDuracion?.cancel();
    _suscripcionDatos?.cancel();
    _dispositivoBLE?.disconnect();

    setState(() {
      monitoreando = false;
      dispositivoConectado = false;
    });

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => FeedbackScreen(
          patient: widget.patient,
          frPromedio: frPromedio,
          frMinima: frMinima,
          frMaxima: frMaxima,
          duracion: segundos,
        ),
      ),
    );
  }

  @override
  void dispose() {
    timerDuracion?.cancel();
    _suscripcionDatos?.cancel();
    _dispositivoBLE?.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final datos = widget.patient.data() as Map<String, dynamic>;
    final nombre = datos['nombre'] ?? 'Sin nombre';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Nueva sesión',
          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF12355B)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(30),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 950),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // PACIENTE
                Card(
                  elevation: 0,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  child: Padding(
                    padding: const EdgeInsets.all(22),
                    child: Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE7F0FF),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Icon(Icons.person, size: 32, color: Color(0xFF2D7FF9)),
                        ),
                        const SizedBox(width: 18),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Paciente', style: TextStyle(color: Colors.grey)),
                            const SizedBox(height: 4),
                            Text(
                              nombre.toString(),
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF12355B),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                // BOTÓN DE CONEXIÓN BLE (Solo se muestra si no está conectado)
                if (!dispositivoConectado)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 25),
                    child: ElevatedButton.icon(
                      onPressed: conectarBandaBLE,
                      icon: const Icon(Icons.bluetooth_searching),
                      label: const Text('Conectar Banda Respiratoria'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2D7FF9),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(20),
                        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),

                // TITULO
                const Text(
                  'Monitorización respiratoria',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF12355B)),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Frecuencia respiratoria durante la sesión',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
                const SizedBox(height: 25),

                // FR PRINCIPAL
                Card(
                  elevation: 0,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                  child: Padding(
                    padding: const EdgeInsets.all(35),
                    child: Column(
                      children: [
                        Container(
                          width: 145,
                          height: 145,
                          decoration: BoxDecoration(
                            color: dispositivoConectado ? const Color(0xFFEAF7F1) : Colors.grey.shade100,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: dispositivoConectado ? const Color(0xFF20A86B) : Colors.grey,
                              width: 4,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                frActual > 0 ? '$frActual' : '--',
                                style: TextStyle(
                                  fontSize: 52,
                                  fontWeight: FontWeight.bold,
                                  color: dispositivoConectado ? const Color(0xFF20A86B) : Colors.grey,
                                ),
                              ),
                              const Text('rpm', style: TextStyle(fontSize: 17, color: Colors.grey)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Frecuencia respiratoria',
                          style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                          decoration: BoxDecoration(
                            color: dispositivoConectado ? const Color(0xFFE6F7EF) : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: dispositivoConectado ? Colors.green : Colors.grey,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                dispositivoConectado ? 'Recibiendo datos BLE' : 'Esperando conexión...',
                                style: TextStyle(
                                  color: dispositivoConectado ? Colors.green : Colors.grey,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                // GRAFICA SIMULADA (Se mueve con el tiempo)
                Card(
                  elevation: 0,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                  child: Padding(
                    padding: const EdgeInsets.all(25),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Señal respiratoria',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          height: 180,
                          width: double.infinity,
                          child: CustomPaint(
                            painter: _BreathingPainter(
                              datosReales: datosGrafica, // <--- NUEVO
                              activo: dispositivoConectado,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                // RESUMEN
                Row(
                  children: [
                    Expanded(child: _StatCard(title: 'Promedio', value: '${frPromedio.toStringAsFixed(1)} rpm', icon: Icons.analytics_outlined)),
                    const SizedBox(width: 15),
                    Expanded(child: _StatCard(title: 'Mínima', value: '$frMinima rpm', icon: Icons.arrow_downward)),
                    const SizedBox(width: 15),
                    Expanded(child: _StatCard(title: 'Máxima', value: '$frMaxima rpm', icon: Icons.arrow_upward)),
                    const SizedBox(width: 15),
                    Expanded(child: _StatCard(title: 'Duración', value: tiempoFormateado, icon: Icons.timer_outlined)),
                  ],
                ),

                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: monitoreando ? finalizarSesion : null,
                    icon: const Icon(Icons.stop_circle_outlined),
                    label: const Text('Finalizar sesión'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD94B4B),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(18),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =====================================================
// TARJETA DE ESTADÍSTICA
// =====================================================
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _StatCard({required this.title, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF2D7FF9), size: 28),
            const SizedBox(height: 10),
            Text(value, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

// =====================================================
// GRÁFICA DE RESPIRACIÓN REAL
// =====================================================
class _BreathingPainter extends CustomPainter {
  final List<double> datosReales;
  final bool activo;

  _BreathingPainter({required this.datosReales, required this.activo});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = activo ? const Color(0xFF2D7FF9) : Colors.grey.shade300
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;

    final path = Path();

    // Línea central de referencia
    final linePaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.2)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, size.height / 2), Offset(size.width, size.height / 2), linePaint);

    if (!activo || datosReales.isEmpty) {
      // Si no hay datos, dibujamos una línea plana en el centro
      path.moveTo(0, size.height / 2);
      path.lineTo(size.width, size.height / 2);
      canvas.drawPath(path, paint);
      return;
    }

    // Encontrar el valor máximo y mínimo para escalar la gráfica automáticamente
    double maxVal = datosReales.reduce(max);
    double minVal = datosReales.reduce(min);
    
    // Si la diferencia es muy pequeña, forzamos un rango para que no se vea ruido gigante
    if (maxVal - minVal < 100) {
      maxVal += 50;
      minVal -= 50;
    }

    // Dibujar los puntos reales
    final double anchoPaso = size.width / 99; // 100 puntos = 99 espacios

    for (int i = 0; i < datosReales.length; i++) {
      final double x = i * anchoPaso;
      
      // Normalizar el valor entre 0 y 1, y luego mapearlo a la altura del Canvas
      // Invertimos la Y porque en Canvas el 0 está arriba
      double valorNormalizado = (datosReales[i] - minVal) / (maxVal - minVal);
      final double y = size.height - (valorNormalizado * size.height);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _BreathingPainter oldDelegate) {
    return true; // Siempre repintar cuando lleguen nuevos datos
  }
}

// =====================================================
// FEEDBACK
// =====================================================

class FeedbackScreen extends StatefulWidget {
  final DocumentSnapshot patient;
  final double frPromedio;
  final int frMinima;
  final int frMaxima;
  final int duracion;

  const FeedbackScreen({
    super.key,
    required this.patient,
    required this.frPromedio,
    required this.frMinima,
    required this.frMaxima,
    required this.duracion,
  });

  @override
  State<FeedbackScreen> createState() =>
      _FeedbackScreenState();
}

class _FeedbackScreenState
    extends State<FeedbackScreen> {

  String? nivelAnsiedad;

  final feedbackController =
      TextEditingController();

  bool guardando = false;

  Future<void> guardarSesion() async {
    if (nivelAnsiedad == null ||
        feedbackController.text
            .trim()
            .isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        const SnackBar(
          content: Text(
            'Completa el nivel de ansiedad y el feedback.',
          ),
        ),
      );

      return;
    }

    setState(() {
      guardando = true;
    });

    try {
      final user =
          FirebaseAuth.instance.currentUser;

      await FirebaseFirestore.instance
          .collection('sesiones')
          .add({
        'patientId':
            widget.patient.id,
        'dentistId':
            user?.uid,
        'frPromedio':
            widget.frPromedio,
        'frMinima':
            widget.frMinima,
        'frMaxima':
            widget.frMaxima,
        'duracionSegundos':
            widget.duracion,
        'nivelAnsiedad':
            nivelAnsiedad,
        'feedback':
            feedbackController.text.trim(),
        'fecha':
            FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          const SnackBar(
            content: Text(
              'Sesión guardada correctamente.',
            ),
          ),
        );

        Navigator.popUntil(
          context,
          (route) => route.isFirst,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          SnackBar(
            content: Text(
              'Error al guardar la sesión: $e',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          guardando = false;
        });
      }
    }
  }

  @override
  void dispose() {
    feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor:
          const Color(0xFFF4F8FC),

      appBar: AppBar(
        backgroundColor:
            Colors.white,
        elevation: 0,

        title: const Text(
          'Finalizar sesión',
          style: TextStyle(
            fontWeight:
                FontWeight.bold,
            color:
                Color(0xFF12355B),
          ),
        ),
      ),

      body: Center(
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.all(30),

          child: ConstrainedBox(
            constraints:
                const BoxConstraints(
              maxWidth: 700,
            ),

            child: Card(
              elevation: 0,
              color: Colors.white,

              shape:
                  RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(
                  22,
                ),
              ),

              child: Padding(
                padding:
                    const EdgeInsets.all(
                  30,
                ),

                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [

                    const Text(
                      'Resumen de la sesión',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight:
                            FontWeight.bold,
                        color:
                            Color(0xFF12355B),
                      ),
                    ),

                    const SizedBox(height: 25),

                    Row(
                      children: [

                        Expanded(
                          child:
                              _ResultCard(
                            title:
                                'FR promedio',
                            value:
                                '${widget.frPromedio.toStringAsFixed(1)} rpm',
                            icon:
                                Icons.air,
                          ),
                        ),

                        const SizedBox(
                            width: 15),

                        Expanded(
                          child:
                              _ResultCard(
                            title:
                                'FR mínima',
                            value:
                                '${widget.frMinima} rpm',
                            icon:
                                Icons
                                    .arrow_downward,
                          ),
                        ),

                        const SizedBox(
                            width: 15),

                        Expanded(
                          child:
                              _ResultCard(
                            title:
                                'FR máxima',
                            value:
                                '${widget.frMaxima} rpm',
                            icon:
                                Icons
                                    .arrow_upward,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),

                    const Text(
                      'Nivel de ansiedad observado',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 15),

                    DropdownButtonFormField<
                        String>(
                      initialValue:
                          nivelAnsiedad,

                      decoration:
                          const InputDecoration(
                        border:
                            OutlineInputBorder(),
                        prefixIcon:
                            Icon(
                          Icons
                              .sentiment_satisfied_alt_outlined,
                        ),
                      ),

                      items: const [
                        DropdownMenuItem(
                          value: 'Bajo',
                          child:
                              Text('Bajo'),
                        ),
                        DropdownMenuItem(
                          value: 'Moderado',
                          child:
                              Text('Moderado'),
                        ),
                        DropdownMenuItem(
                          value: 'Alto',
                          child:
                              Text('Alto'),
                        ),
                      ],

                      onChanged:
                          (value) {
                        setState(() {
                          nivelAnsiedad =
                              value;
                        });
                      },
                    ),

                    const SizedBox(height: 25),

                    const Text(
                      'Feedback del odontólogo',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 15),

                    TextField(
                      controller:
                          feedbackController,

                      maxLines: 5,

                      decoration:
                          const InputDecoration(
                        hintText:
                            'Describe brevemente cómo fue la sesión y el nivel de ansiedad observado...',
                        border:
                            OutlineInputBorder(),
                        alignLabelWithHint:
                            true,
                      ),
                    ),

                    const SizedBox(height: 30),

                    SizedBox(
                      width:
                          double.infinity,

                      child:
                          ElevatedButton.icon(
                        onPressed:
                            guardando
                                ? null
                                : guardarSesion,

                        icon: guardando
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(
                                Icons
                                    .save_outlined,
                              ),

                        label: Text(
                          guardando
                              ? 'Guardando...'
                              : 'Guardar sesión',
                        ),

                        style:
                            ElevatedButton
                                .styleFrom(
                          padding:
                              const EdgeInsets
                                  .all(
                            17,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultCard
    extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _ResultCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding:
          const EdgeInsets.all(18),

      decoration:
          BoxDecoration(
        color:
            const Color(0xFFF4F8FC),
        borderRadius:
            BorderRadius.circular(16),
      ),

      child: Column(
        children: [

          Icon(
            icon,
            color:
                const Color(0xFF2D7FF9),
          ),

          const SizedBox(height: 8),

          Text(
            value,
            style:
                const TextStyle(
              fontSize: 20,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            title,
            textAlign:
                TextAlign.center,
            style:
                const TextStyle(
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}