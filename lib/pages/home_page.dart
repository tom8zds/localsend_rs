import 'package:flutter/material.dart';
import 'package:localsend_rs/i18n/strings.g.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.t.home.title),
      ),
    );
  }
}
