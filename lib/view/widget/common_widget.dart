import 'package:flutter/material.dart';

import '../../common/spacing.dart';
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
      padding: const EdgeInsets.only(right: AppSpacing.x8),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.x8,
          vertical: AppSpacing.x4,
        ),
        decoration: BoxDecoration(
          // M3 chip corner: small (8dp).
          borderRadius: BorderRadius.circular(AppSpacing.x8),
          color: Theme.of(context).colorScheme.primaryContainer,
        ),
        child: Text(
          title,
          // Tonal pairing: on-primary-container on primary-container.
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
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
