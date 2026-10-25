import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_options.dart';
import 'screens/patients_screen.dart';
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const DentCalmApp());
}

class DentCalmApp extends StatelessWidget {
  const DentCalmApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'DentCalm',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2D7FF9),
        ),
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasData) {
          return const HomeScreen();
        }

        return const LoginScreen();
      },
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool loading = false;
  String? errorMessage;

  Future<void> login() async {
    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        errorMessage = _firebaseError(e.code);
      });
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  String _firebaseError(String code) {
    switch (code) {
      case 'invalid-credential':
        return 'Correo o contraseña incorrectos.';
      case 'invalid-email':
        return 'El correo electrónico no es válido.';
      case 'user-disabled':
        return 'Esta cuenta está deshabilitada.';
      default:
        return 'No se pudo iniciar sesión.';
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFF6FF),
      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 430,
            ),
            child: Card(
              margin: const EdgeInsets.all(24),
              elevation: 6,
              child: Padding(
                padding: const EdgeInsets.all(30),
                child: Column(
                  children: [
                    const Icon(
                      Icons.medical_services_outlined,
                      size: 70,
                      color: Color(0xFF2D7FF9),
                    ),

                    const SizedBox(height: 15),

                    const Text(
                      'DentCalm',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      'Monitorización respiratoria',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey,
                      ),
                    ),

                    const SizedBox(height: 30),

                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Correo electrónico',
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 16),

                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Contraseña',
                        prefixIcon: Icon(Icons.lock_outline),
                        border: OutlineInputBorder(),
                      ),
                    ),

                    if (errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        errorMessage!,
                        style: const TextStyle(
                          color: Colors.red,
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: loading ? null : login,
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: loading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(),
                                )
                              : const Text(
                                  'Iniciar sesión',
                                ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),

                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RegisterScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        '¿Primera vez? Crear cuenta',
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

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();

  bool loading = false;
  String? errorMessage;

  Future<void> register() async {
    if (passwordController.text != confirmController.text) {
      setState(() {
        errorMessage = 'Las contraseñas no coinciden.';
      });
      return;
    }

    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      final credential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      await credential.user?.updateDisplayName(
        nameController.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        errorMessage = _registerError(e.code);
      });
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  String _registerError(String code) {
    switch (code) {
      case 'weak-password':
        return 'La contraseña es demasiado débil.';
      case 'email-already-in-use':
        return 'Ya existe una cuenta con ese correo.';
      case 'invalid-email':
        return 'El correo electrónico no es válido.';
      default:
        return 'No se pudo crear la cuenta.';
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFF6FF),
      appBar: AppBar(
        title: const Text('Crear cuenta'),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 430,
            ),
            child: Card(
              margin: const EdgeInsets.all(24),
              child: Padding(
                padding: const EdgeInsets.all(30),
                child: Column(
                  children: [
                    const Text(
                      'Registro del odontólogo',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 25),

                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre completo',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 16),

                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Correo electrónico',
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 16),

                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Contraseña',
                        prefixIcon: Icon(Icons.lock_outline),
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 16),

                    TextField(
                      controller: confirmController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Confirmar contraseña',
                        prefixIcon: Icon(Icons.lock_outline),
                        border: OutlineInputBorder(),
                      ),
                    ),

                    if (errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        errorMessage!,
                        style: const TextStyle(
                          color: Colors.red,
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: loading ? null : register,
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: loading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(),
                                )
                              : const Text(
                                  'Crear cuenta',
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

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final nombre = user?.displayName?.isNotEmpty == true ? user!.displayName! : 'Odontólogo';
    final uid = user?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'DentCalm',
          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF12355B)),
        ),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
            icon: const Icon(Icons.logout),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bienvenido, $nombre',
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF12355B)),
            ),
            const SizedBox(height: 8),
            const Text(
              'Monitorización respiratoria para la atención odontológica',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 30),

            // BOTONES PRINCIPALES
            Row(
              children: [
                Expanded(
                  child: _DashboardCard(
                    icon: Icons.people_alt_outlined,
                    title: 'Pacientes',
                    subtitle: 'Registrar y consultar',
                    color: const Color(0xFF2D7FF9),
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const PatientsScreen()));
                    },
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: _DashboardCard(
                    icon: Icons.monitor_heart_outlined,
                    title: 'Nueva sesión',
                    subtitle: 'Iniciar monitoreo',
                    color: const Color(0xFF20A86B),
                    onTap: () {
                      // Redirige a pacientes con un aviso
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Selecciona un paciente para iniciar la sesión.')),
                      );
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const PatientsScreen()));
                    },
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: _DashboardCard(
                    icon: Icons.history,
                    title: 'Historial',
                    subtitle: 'Consultar sesiones',
                    color: const Color(0xFF8A5CF6),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Selecciona un paciente para ver su historial.')),
                      );
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const PatientsScreen()));
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            // ESTADO DEL SISTEMA
            Card(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(25),
                child: Row(
                  children: [
                    Container(
                      width: 65,
                      height: 65,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE7F0FF),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(Icons.air, size: 35, color: Color(0xFF2D7FF9)),
                    ),
                    const SizedBox(width: 20),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Estado del sistema', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          SizedBox(height: 6),
                          Text('Listo para iniciar una sesión de monitoreo.', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE6F7EF),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.circle, size: 10, color: Colors.green),
                          SizedBox(width: 8),
                          Text('Preparado', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),
            const Text(
              'Resumen',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF12355B)),
            ),
            const SizedBox(height: 15),

            // TARJETAS DE RESUMEN CONECTADAS A FIREBASE
            if (uid != null)
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('pacientes').where('dentistId', isEqualTo: uid).snapshots(),
                builder: (context, snapshotPacientes) {
                  final totalPacientes = snapshotPacientes.data?.docs.length ?? 0;

                  return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('sesiones').where('dentistId', isEqualTo: uid).snapshots(),
                    builder: (context, snapshotSesiones) {
                      final docsSesiones = snapshotSesiones.data?.docs ?? [];
                      final totalSesiones = docsSesiones.length;

                      // Calcular sesiones de hoy
                      final now = DateTime.now();
                      final startOfDay = DateTime(now.year, now.month, now.day);
                      int sesionesHoy = 0;

                      for (var doc in docsSesiones) {
                        final data = doc.data() as Map<String, dynamic>;
                        if (data['fecha'] != null && data['fecha'] is Timestamp) {
                          final fechaSesion = (data['fecha'] as Timestamp).toDate();
                          if (fechaSesion.isAfter(startOfDay) || fechaSesion.isAtSameMomentAs(startOfDay)) {
                            sesionesHoy++;
                          }
                        }
                      }

                      return Row(
                        children: [
                          Expanded(child: _SummaryCard(title: 'Pacientes', value: '$totalPacientes', icon: Icons.people_outline)),
                          const SizedBox(width: 20),
                          Expanded(child: _SummaryCard(title: 'Sesiones', value: '$totalSesiones', icon: Icons.assignment_outlined)),
                          const SizedBox(width: 20),
                          Expanded(child: _SummaryCard(title: 'Hoy', value: '$sesionesHoy', icon: Icons.today_outlined)),
                        ],
                      );
                    },
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}


// TARJETA PRINCIPAL
class _DashboardCard extends StatelessWidget {

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _DashboardCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),

      child: Card(
        elevation: 0,
        color: Colors.white,

        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),

        child: Padding(
          padding: const EdgeInsets.all(25),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [

              Container(
                width: 60,
                height: 60,

                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                ),

                child: Icon(
                  icon,
                  size: 32,
                  color: color,
                ),
              ),

              const SizedBox(height: 18),

              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                subtitle,
                style: const TextStyle(
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


// TARJETA DE RESUMEN
class _SummaryCard extends StatelessWidget {

  final String title;
  final String value;
  final IconData icon;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {

    return Card(
      elevation: 0,
      color: Colors.white,

      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),

      child: Padding(
        padding: const EdgeInsets.all(22),

        child: Row(
          children: [

            Icon(
              icon,
              size: 30,
              color: const Color(0xFF2D7FF9),
            ),

            const SizedBox(width: 15),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [

                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}