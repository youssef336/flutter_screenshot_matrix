import 'package:flutter/material.dart';

import '../strings.dart';

/// A profile screen with two deliberate layout bugs, so the gallery has
/// something to flag:
///
/// * the action buttons sit in a plain `Row` (no `Expanded`/`Wrap`), so the
///   longer Arabic labels overflow on small phones and at large text sizes;
/// * the bio is limited to two lines and gets ellipsized.
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final Strings s = Strings.of(context);
    final TextTheme text = Theme.of(context).textTheme;
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(s.get('profile')),
        actions: <Widget>[
          IconButton(onPressed: () {}, icon: const Icon(Icons.share_outlined)),
          IconButton(onPressed: () {}, icon: const Icon(Icons.more_vert)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: <Widget>[
          Row(
            children: <Widget>[
              const CircleAvatar(
                radius: 40,
                backgroundImage: AssetImage('assets/images/cover.png'),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(s.get('name'), style: text.titleLarge),
                    const SizedBox(height: 4),
                    Row(
                      children: <Widget>[
                        Icon(Icons.verified, size: 18, color: colors.primary),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            s.get('verified'),
                            style: text.labelLarge,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            s.get('bio'),
            style: text.bodyLarge,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              _Stat(value: '1.2K', label: s.get('followers')),
              _Stat(value: '348', label: s.get('following')),
              _Stat(value: '87', label: s.get('posts')),
            ],
          ),
          const SizedBox(height: 20),
          // Deliberate bug: no Expanded, so long labels overflow.
          Row(
            children: <Widget>[
              FilledButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.person_add_alt_1),
                label: Text(s.get('follow')),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.chat_bubble_outline),
                label: Text(s.get('message')),
              ),
            ],
          ),
          const SizedBox(height: 20),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
            children: <Widget>[
              for (int i = 0; i < 6; i++)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    'assets/images/cover.png',
                    fit: BoxFit.cover,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Column(
      children: <Widget>[
        Text(value, style: text.titleLarge),
        Text(label, style: text.bodyMedium),
      ],
    );
  }
}
