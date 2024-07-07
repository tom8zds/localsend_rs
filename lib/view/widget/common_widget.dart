import 'package:flutter/material.dart';

import '../../i18n/strings.g.dart';

class AppTitle extends StatelessWidget {
  const AppTitle({super.key});

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        text: t.appTitle.parta,
        children: [
          TextSpan(
            text: t.appTitle.partb,
            style: Theme.of(context).textTheme.displaySmall!.copyWith(
                  color: const Color(0xfff74c00),
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
      style: Theme.of(context).textTheme.displaySmall,
    );
  }
}

class Tag extends StatelessWidget {
  final String title;

  const Tag({super.key, required this.title});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          color: Theme.of(context).colorScheme.primaryContainer,
        ),
        child: Text(
          title,
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }
}

class StaticAppbar extends StatelessWidget {
  final String title;

  const StaticAppbar({super.key, required this.title});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: kToolbarHeight,
      child: Center(
        child: Text(
          title,
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
    );
  }
}
