import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/db_service.dart';
import 'providers/task_provider.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DBService.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TaskProvider()),
      ],
      child: MaterialApp(
        title: 'Task Manager',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          scaffoldBackgroundColor: Colors.grey[100],
          cardTheme: CardThemeData(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          appBarTheme: const AppBarTheme(
            elevation: 0,
            centerTitle: true,
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
          colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.blue).copyWith(
            secondary: Colors.blueAccent,
          ),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
