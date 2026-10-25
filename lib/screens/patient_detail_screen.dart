import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'monitoring_screen.dart';

class PatientDetailScreen extends StatelessWidget {
  final DocumentSnapshot patient;

  const PatientDetailScreen({
    super.key,
    required this.patient,
  });

  @override
  Widget build(BuildContext context) {
    final datos =
        patient.data() as Map<String, dynamic>;

    final nombre =
        datos['nombre'] ?? 'Sin nombre';

    final edad =
        datos['edad'] ?? '-';

    final sexo =
        datos['sexo'] ?? '-';

    final codigo =
        datos['codigo'] ?? patient.id;

    final notas =
        datos['notas'] ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FC),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Color(0xFF12355B),
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),

        title: const Text(
          'Paciente',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF12355B),
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(30),

        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 900,
            ),

            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [

                // =====================================================
                // DATOS PRINCIPALES DEL PACIENTE
                // =====================================================

                Card(
                  elevation: 0,
                  color: Colors.white,

                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(22),
                  ),

                  child: Padding(
                    padding: const EdgeInsets.all(30),

                    child: Row(
                      children: [

                        Container(
                          width: 85,
                          height: 85,

                          decoration: BoxDecoration(
                            color:
                                const Color(0xFFE7F0FF),
                            borderRadius:
                                BorderRadius.circular(22),
                          ),

                          child: const Icon(
                            Icons.person,
                            size: 45,
                            color:
                                Color(0xFF2D7FF9),
                          ),
                        ),

                        const SizedBox(width: 25),

                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,

                            children: [

                              Text(
                                nombre.toString(),
                                style: const TextStyle(
                                  fontSize: 30,
                                  fontWeight:
                                      FontWeight.bold,
                                  color:
                                      Color(0xFF12355B),
                                ),
                              ),

                              const SizedBox(height: 8),

                              Text(
                                '$edad años  •  Sexo: $sexo',
                                style:
                                    const TextStyle(
                                  fontSize: 17,
                                  color: Colors.grey,
                                ),
                              ),

                              const SizedBox(height: 5),

                              Text(
                                'Código: $codigo',
                                style:
                                    const TextStyle(
                                  color: Colors.grey,
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

                // =====================================================
                // INFORMACIÓN DEL PACIENTE
                // =====================================================

                Card(
                  elevation: 0,
                  color: Colors.white,

                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(22),
                  ),

                  child: Padding(
                    padding: const EdgeInsets.all(30),

                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,

                      children: [

                        const Text(
                          'Información del paciente',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight:
                                FontWeight.bold,
                            color:
                                Color(0xFF12355B),
                          ),
                        ),

                        const SizedBox(height: 20),

                        _InfoRow(
                          icon: Icons.cake_outlined,
                          title: 'Edad',
                          value: '$edad años',
                        ),

                        _InfoRow(
                          icon: Icons.wc_outlined,
                          title: 'Sexo',
                          value: sexo.toString(),
                        ),

                        _InfoRow(
                          icon:
                              Icons.badge_outlined,
                          title: 'Código',
                          value: codigo.toString(),
                        ),

                        if (notas
                            .toString()
                            .isNotEmpty)
                          _InfoRow(
                            icon:
                                Icons.notes_outlined,
                            title: 'Notas',
                            value:
                                notas.toString(),
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                // =====================================================
                // NUEVA SESIÓN
                // =====================================================

                Card(
                  elevation: 0,
                  color:
                      const Color(0xFFEAF7F1),

                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(22),
                  ),

                  child: Padding(
                    padding: const EdgeInsets.all(30),

                    child: Row(
                      children: [

                        Container(
                          width: 65,
                          height: 65,

                          decoration:
                              BoxDecoration(
                            color:
                                Colors.white,
                            borderRadius:
                                BorderRadius.circular(
                              18,
                            ),
                          ),

                          child: const Icon(
                            Icons
                                .monitor_heart_outlined,
                            size: 35,
                            color:
                                Color(0xFF20A86B),
                          ),
                        ),

                        const SizedBox(width: 20),

                        const Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,

                            children: [

                              Text(
                                'Nueva sesión',
                                style: TextStyle(
                                  fontSize: 21,
                                  fontWeight:
                                      FontWeight.bold,
                                  color:
                                      Color(0xFF145A3A),
                                ),
                              ),

                              SizedBox(height: 5),

                              Text(
                                'Iniciar monitorización respiratoria',
                                style: TextStyle(
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),

                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    MonitoringScreen(
                                  patient: patient,
                                ),
                              ),
                            );
                          },

                          icon: const Icon(
                            Icons.play_arrow,
                          ),

                          label: const Text(
                            'Iniciar',
                          ),

                          style:
                              ElevatedButton
                                  .styleFrom(
                            backgroundColor:
                                const Color(
                              0xFF20A86B,
                            ),
                            foregroundColor:
                                Colors.white,
                            padding:
                                const EdgeInsets
                                    .symmetric(
                              horizontal: 20,
                              vertical: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // =====================================================
                // HISTORIAL DE SESIONES
                // =====================================================

                const Text(
                  'Historial de sesiones',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF12355B),
                  ),
                ),

                const SizedBox(height: 15),

                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('sesiones')
                      .where(
                        'patientId',
                        isEqualTo: patient.id,
                      )
                      .snapshots(),

                  builder: (context, snapshot) {

                    // -------------------------------------------------
                    // CARGANDO
                    // -------------------------------------------------

                    if (snapshot.connectionState ==
                        ConnectionState.waiting) {
                      return Card(
                        elevation: 0,
                        color: Colors.white,

                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(
                            18,
                          ),
                        ),

                        child: const Padding(
                          padding:
                              EdgeInsets.all(30),

                          child: Center(
                            child:
                                CircularProgressIndicator(),
                          ),
                        ),
                      );
                    }

                    // -------------------------------------------------
                    // ERROR
                    // -------------------------------------------------

                    if (snapshot.hasError) {
                      return Card(
                        elevation: 0,
                        color: Colors.white,

                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(
                            18,
                          ),
                        ),

                        child: Padding(
                          padding:
                              const EdgeInsets.all(
                            25,
                          ),

                          child: Text(
                            'Error al cargar las sesiones:\n'
                            '${snapshot.error}',
                            textAlign:
                                TextAlign.center,
                          ),
                        ),
                      );
                    }

                    // -------------------------------------------------
                    // OBTENER SESIONES
                    // -------------------------------------------------

                    final sesiones =
                        snapshot.data?.docs ?? [];

                    // -------------------------------------------------
                    // SIN SESIONES
                    // -------------------------------------------------

                    if (sesiones.isEmpty) {
                      return Card(
                        elevation: 0,
                        color: Colors.white,

                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(
                            18,
                          ),
                        ),

                        child: const Padding(
                          padding:
                              EdgeInsets.all(25),

                          child: Center(
                            child: Column(
                              children: [

                                Icon(
                                  Icons.history,
                                  size: 45,
                                  color: Colors.grey,
                                ),

                                SizedBox(height: 12),

                                Text(
                                  'Este paciente todavía no tiene sesiones.',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }

                    // -------------------------------------------------
                    // MOSTRAR SESIONES
                    // -------------------------------------------------

                    return Column(
                      children: sesiones.map(
                        (sesion) {

                          final datos =
                              sesion.data()
                                  as Map<String, dynamic>;

                          final frPromedio =
                              datos['frPromedio'] ?? '-';

                          final frMinima =
                              datos['frMinima'] ?? '-';

                          final frMaxima =
                              datos['frMaxima'] ?? '-';

                          final duracion =
                              (datos[
                                      'duracionSegundos']
                                  as num?)
                              ?.toInt() ??
                              0;

                          final ansiedad =
                              datos['nivelAnsiedad'] ??
                                  '-';

                          final feedback =
                              datos['feedback'] ??
                                  '';

                          final fecha =
                              datos['fecha']
                                  is Timestamp
                                  ? datos['fecha']
                                      as Timestamp
                                  : null;

                          String fechaTexto =
                              'Fecha no disponible';

                          if (fecha != null) {
                            final date =
                                fecha.toDate();

                            fechaTexto =
                                '${date.day.toString().padLeft(2, '0')}/'
                                '${date.month.toString().padLeft(2, '0')}/'
                                '${date.year} '
                                '${date.hour.toString().padLeft(2, '0')}:'
                                '${date.minute.toString().padLeft(2, '0')}';
                          }

                          final minutos =
                              duracion ~/ 60;

                          final segundos =
                              duracion % 60;

                          return Card(
                            elevation: 0,
                            color: Colors.white,

                            margin:
                                const EdgeInsets.only(
                              bottom: 15,
                            ),

                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(
                                18,
                              ),
                            ),

                            child: Padding(
                              padding:
                                  const EdgeInsets.all(
                                22,
                              ),

                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment
                                        .start,

                                children: [

                                  // ENCABEZADO
                                  Row(
                                    children: [

                                      Container(
                                        width: 50,
                                        height: 50,

                                        decoration:
                                            BoxDecoration(
                                          color:
                                              const Color(
                                            0xFFE7F0FF,
                                          ),
                                          borderRadius:
                                              BorderRadius
                                                  .circular(
                                            15,
                                          ),
                                        ),

                                        child:
                                            const Icon(
                                          Icons
                                              .monitor_heart_outlined,
                                          color:
                                              Color(
                                            0xFF2D7FF9,
                                          ),
                                        ),
                                      ),

                                      const SizedBox(
                                          width: 15),

                                      const Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment
                                                  .start,

                                          children: [

                                            Text(
                                              'Sesión de monitorización',
                                              style:
                                                  TextStyle(
                                                fontSize:
                                                    18,
                                                fontWeight:
                                                    FontWeight
                                                        .bold,
                                                color:
                                                    Color(
                                                  0xFF12355B,
                                                ),
                                              ),
                                            ),

                                            SizedBox(
                                                height: 4),

                                            Text(
                                              'Registro guardado',
                                              style:
                                                  TextStyle(
                                                color:
                                                    Colors
                                                        .grey,
                                                fontSize:
                                                    13,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(
                                      height: 20),

                                  // FECHA
                                  Text(
                                    fechaTexto,
                                    style:
                                        const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 13,
                                    ),
                                  ),

                                  const SizedBox(
                                      height: 18),

                                  // DATOS DE FR
                                  Row(
                                    children: [

                                      Expanded(
                                        child:
                                            _SessionData(
                                          title:
                                              'FR promedio',
                                          value:
                                              '$frPromedio rpm',
                                        ),
                                      ),

                                      Expanded(
                                        child:
                                            _SessionData(
                                          title:
                                              'FR mínima',
                                          value:
                                              '$frMinima rpm',
                                        ),
                                      ),

                                      Expanded(
                                        child:
                                            _SessionData(
                                          title:
                                              'FR máxima',
                                          value:
                                              '$frMaxima rpm',
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(
                                      height: 18),

                                  // DURACIÓN
                                  _SessionInfoRow(
                                    icon:
                                        Icons
                                            .timer_outlined,
                                    title:
                                        'Duración',
                                    value:
                                        '${minutos.toString().padLeft(2, '0')}:'
                                        '${segundos.toString().padLeft(2, '0')}',
                                  ),

                                  // ANSIEDAD
                                  _SessionInfoRow(
                                    icon: Icons
                                        .sentiment_satisfied_alt_outlined,
                                    title:
                                        'Ansiedad',
                                    value:
                                        ansiedad.toString(),
                                  ),

                                  // FEEDBACK
                                  if (feedback
                                      .toString()
                                      .isNotEmpty)
                                    _SessionInfoRow(
                                      icon: Icons
                                          .notes_outlined,
                                      title:
                                          'Feedback',
                                      value:
                                          feedback
                                              .toString(),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ).toList(),
                    );
                  },
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
// FILA DE INFORMACIÓN DEL PACIENTE
// =====================================================

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.only(bottom: 18),

      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [

          Icon(
            icon,
            color: const Color(0xFF2D7FF9),
          ),

          const SizedBox(width: 15),

          SizedBox(
            width: 120,

            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


// =====================================================
// DATO DE SESIÓN
// =====================================================

class _SessionData extends StatelessWidget {
  final String title;
  final String value;

  const _SessionData({
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: [

        Text(
          value,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: Color(0xFF12355B),
          ),
        ),

        const SizedBox(height: 3),

        Text(
          title,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}


// =====================================================
// FILA DE INFORMACIÓN DE SESIÓN
// =====================================================

class _SessionInfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _SessionInfoRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.only(bottom: 10),

      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [

          Icon(
            icon,
            size: 20,
            color: const Color(0xFF2D7FF9),
          ),

          const SizedBox(width: 10),

          SizedBox(
            width: 90,

            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }
}