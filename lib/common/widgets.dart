import 'package:flutter/material.dart';

class AppTitle extends StatelessWidget {
  const AppTitle({super.key});

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        text: 'LocalSend',
        children: [
          TextSpan(
            text: '_RS',
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
