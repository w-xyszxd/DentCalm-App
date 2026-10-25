import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class NewPatientScreen extends StatefulWidget {
  const NewPatientScreen({super.key});

  @override
  State<NewPatientScreen> createState() => _NewPatientScreenState();
}

class _NewPatientScreenState extends State<NewPatientScreen> {
  final nombreController = TextEditingController();
  final codigoController = TextEditingController();
  final edadController = TextEditingController();
  final notasController = TextEditingController();

  String? sexo;
  DateTime? fechaNacimiento;

  bool guardando = false;

  Future<void> seleccionarFecha() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (fecha != null) {
      setState(() {
        fechaNacimiento = fecha;
      });
    }
  }

  Future<void> guardarPaciente() async {
    if (nombreController.text.trim().isEmpty ||
        edadController.text.trim().isEmpty ||
        sexo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Completa nombre, edad y sexo.',
          ),
        ),
      );
      return;
    }

    final edad = int.tryParse(
      edadController.text.trim(),
    );

    if (edad == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'La edad debe ser un número entero.',
          ),
        ),
      );
      return;
    }

    setState(() {
      guardando = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;

      await FirebaseFirestore.instance
          .collection('pacientes')
          .add({
        'nombre': nombreController.text.trim(),
        'codigo': codigoController.text.trim(),
        'edad': edad,
        'sexo': sexo,
        'fechaNacimiento': fechaNacimiento != null
            ? Timestamp.fromDate(fechaNacimiento!)
            : null,
        'notas': notasController.text.trim(),
        'dentistId': user?.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Paciente registrado correctamente.',
            ),
          ),
        );

        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error al guardar: $e',
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
    nombreController.dispose();
    codigoController.dispose();
    edadController.dispose();
    notasController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FC),

      appBar: AppBar(
        title: const Text(
          'Nuevo paciente',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF12355B),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),

      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30),

          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 650,
            ),

            child: Card(
              elevation: 0,

              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),

              child: Padding(
                padding: const EdgeInsets.all(30),

                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [

                    const Text(
                      'Datos del paciente',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF12355B),
                      ),
                    ),

                    const SizedBox(height: 25),

                    TextField(
                      controller: nombreController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre completo',
                        prefixIcon:
                            Icon(Icons.person_outline),
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 18),

                    TextField(
                      controller: codigoController,
                      decoration: const InputDecoration(
                        labelText: 'Código del paciente',
                        hintText: 'Ej. PAC-001',
                        prefixIcon:
                            Icon(Icons.badge_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 18),

                    TextField(
                      controller: edadController,
                      keyboardType:
                          TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Edad',
                        suffixText: 'años',
                        prefixIcon:
                            Icon(Icons.cake_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 18),

                    DropdownButtonFormField<String>(
                      value: sexo,
                      decoration: const InputDecoration(
                        labelText: 'Sexo',
                        prefixIcon:
                            Icon(Icons.wc_outlined),
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'F',
                          child: Text('Femenino'),
                        ),
                        DropdownMenuItem(
                          value: 'M',
                          child: Text('Masculino'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          sexo = value;
                        });
                      },
                    ),

                    const SizedBox(height: 18),

                    InkWell(
                      onTap: seleccionarFecha,

                      child: InputDecorator(
                        decoration:
                            const InputDecoration(
                          labelText:
                              'Fecha de nacimiento',
                          prefixIcon: Icon(
                            Icons.calendar_today_outlined,
                          ),
                          border: OutlineInputBorder(),
                        ),

                        child: Text(
                          fechaNacimiento == null
                              ? 'Seleccionar fecha'
                              : '${fechaNacimiento!.day.toString().padLeft(2, '0')}/'
                                '${fechaNacimiento!.month.toString().padLeft(2, '0')}/'
                                '${fechaNacimiento!.year}',
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    TextField(
                      controller: notasController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Notas',
                        alignLabelWithHint: true,
                        prefixIcon:
                            Icon(Icons.notes_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 30),

                    SizedBox(
                      width: double.infinity,

                      child: ElevatedButton.icon(
                        onPressed:
                            guardando
                                ? null
                                : guardarPaciente,

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
                                Icons.save_outlined,
                              ),

                        label: Text(
                          guardando
                              ? 'Guardando...'
                              : 'Guardar paciente',
                        ),

                        style:
                            ElevatedButton.styleFrom(
                          padding:
                              const EdgeInsets.all(18),
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