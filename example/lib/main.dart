import 'package:flutter/material.dart';
import 'vault.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: FutureBuilder<int>(
            // .use() is now async to support non-blocking decryption
            future: Vault.apiKey.use((v) => v.length),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              }
              if (snapshot.hasError) {
                return Text('Decryption Error: \${snapshot.error}');
              }
              return Text('envault example app. Key length: \${snapshot.data}');
            },
          ),
        ),
      ),
    );
  }
}
