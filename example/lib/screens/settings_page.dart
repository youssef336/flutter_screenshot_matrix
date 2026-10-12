import 'package:flutter/material.dart';

import '../strings.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final Strings s = Strings.of(context);
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(s.get('settings'))),
      body: ListView(
        children: <Widget>[
          ListTile(
            leading: const CircleAvatar(
              backgroundImage: AssetImage('assets/images/cover.png'),
            ),
            title: Text(s.get('name')),
            subtitle: Text(s.get('account')),
            trailing: const Icon(Icons.chevron_right),
          ),
          const Divider(),
          SwitchListTile(
            value: true,
            onChanged: (_) {},
            secondary: const Icon(Icons.notifications_outlined),
            title: Text(s.get('notifications')),
          ),
          SwitchListTile(
            value: Theme.of(context).brightness == Brightness.dark,
            onChanged: (_) {},
            secondary: const Icon(Icons.dark_mode_outlined),
            title: Text(s.get('darkMode')),
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(s.get('language')),
            trailing: Text(s.get('languageValue')),
          ),
          ListTile(
            leading: const Icon(Icons.shield_outlined),
            title: Text(s.get('privacy')),
            trailing: const Icon(Icons.chevron_right),
          ),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: Text(s.get('help')),
            trailing: const Icon(Icons.chevron_right),
          ),
          const Divider(),
          ListTile(
            leading: Icon(Icons.logout, color: colors.error),
            title: Text(s.get('logout'), style: TextStyle(color: colors.error)),
          ),
        ],
      ),
    );
  }
}
