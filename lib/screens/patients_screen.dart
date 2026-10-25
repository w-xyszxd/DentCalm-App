import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'new_patient_screen.dart';
import 'patient_detail_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PatientsScreen extends StatefulWidget {
  const PatientsScreen({super.key});

  @override
  State<PatientsScreen> createState() => _PatientsScreenState();
}

class _PatientsScreenState extends State<PatientsScreen> {
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Pacientes',
          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF12355B)),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 15),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NewPatientScreen()),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Nuevo paciente'),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // BARRA DE BÚSQUEDA
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  searchQuery = value.toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: 'Buscar por nombre o código...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFFF4F8FC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // LISTA DE PACIENTES
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('pacientes')
                  .where('dentistId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                  .orderBy('createdAt', descending: true) // Ordenar por los más recientes
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error al cargar pacientes:\n${snapshot.error}', textAlign: TextAlign.center));
                }

                final pacientes = snapshot.data?.docs ?? [];

                // FILTRAR PACIENTES SEGÚN LA BÚSQUEDA
                final pacientesFiltrados = pacientes.where((paciente) {
                  final datos = paciente.data() as Map<String, dynamic>;
                  final nombre = (datos['nombre'] ?? '').toString().toLowerCase();
                  final codigo = (datos['codigo'] ?? '').toString().toLowerCase();
                  return nombre.contains(searchQuery) || codigo.contains(searchQuery);
                }).toList();

                if (pacientesFiltrados.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.search_off, size: 60, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          searchQuery.isEmpty ? 'No hay pacientes registrados.' : 'No se encontraron resultados.',
                          style: const TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: pacientesFiltrados.length,
                  itemBuilder: (context, index) {
                    final paciente = pacientesFiltrados[index];
                    final datos = paciente.data() as Map<String, dynamic>;
                    final nombre = datos['nombre'] ?? 'Sin nombre';
                    final edad = datos['edad'] ?? '-';
                    final sexo = datos['sexo'] ?? '-';
                    final codigo = datos['codigo'] ?? paciente.id;

                    return InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => PatientDetailScreen(patient: paciente)),
                        );
                      },
                      borderRadius: BorderRadius.circular(18),
                      child: Card(
                        elevation: 0,
                        margin: const EdgeInsets.only(bottom: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              Container(
                                width: 55,
                                height: 55,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE7F0FF),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(Icons.person, color: Color(0xFF2D7FF9), size: 30),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      nombre.toString(),
                                      style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 5),
                                    Text('$edad años  •  Sexo: $sexo', style: const TextStyle(color: Colors.grey)),
                                    const SizedBox(height: 4),
                                    Text('Código: $codigo', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right, color: Colors.grey),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}