import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';

class UserSetupScreen extends StatefulWidget {
  const UserSetupScreen({super.key});

  @override
  State<UserSetupScreen> createState() => _UserSetupScreenState();
}

class _UserSetupScreenState extends State<UserSetupScreen> {
  final _ctrl = TextEditingController();
  final _form = GlobalKey<FormState>();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(title: const Text('Crear usuario')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tu ID: ${app.userId ?? "..."}',
                  style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: 16),
              TextFormField(
                controller: _ctrl,
                decoration: const InputDecoration(
                  labelText: 'Nombre visible',
                  hintText: 'Ej: Ramon',
                ),
                validator: (v) {
                  final t = (v ?? '').trim();
                  if (t.isEmpty) return 'Elegí un nombre';
                  if (t.length > 24) return 'Máx 24 caracteres';
                  return null;
                },
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    if (!_form.currentState!.validate()) return;
                    await context.read<AppState>().setUserName(_ctrl.text);
                    if (context.mounted) {
                      Navigator.of(context).pushReplacementNamed('/home');
                    }
                  },
                  child: const Text('Guardar y continuar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
