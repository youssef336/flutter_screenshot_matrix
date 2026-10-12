import 'package:flutter/material.dart';

import '../strings.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final Strings s = Strings.of(context);
    final TextTheme text = Theme.of(context).textTheme;
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  'assets/images/cover.png',
                  height: 140,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 28),
              Text(s.get('welcome'), style: text.headlineMedium),
              const SizedBox(height: 6),
              Text(
                s.get('subtitle'),
                style: text.bodyLarge?.copyWith(color: colors.onSurfaceVariant),
              ),
              const SizedBox(height: 28),
              TextField(
                decoration: InputDecoration(
                  labelText: s.get('email'),
                  prefixIcon: const Icon(Icons.alternate_email),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                obscureText: true,
                decoration: InputDecoration(
                  labelText: s.get('password'),
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: const Icon(Icons.visibility_off_outlined),
                  border: const OutlineInputBorder(),
                ),
              ),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton(
                  onPressed: () {},
                  child: Text(s.get('forgot')),
                ),
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.login),
                label: Text(s.get('signIn')),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () {},
                  child: Text(s.get('noAccount')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
