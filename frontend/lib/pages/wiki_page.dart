import 'package:flutter/material.dart';

class WikiPage extends StatelessWidget {
  const WikiPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Fertilis Wiki")),
      body: const Center(
        child: Text("Wiki infos will be added to this page"),
      ),
    );
  }
}
