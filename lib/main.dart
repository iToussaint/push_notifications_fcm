import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:rxdart/rxdart.dart';


final _messageStreamController = BehaviorSubject<RemoteMessage>();


final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();


Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  if (kDebugMode) {
    print("Handling a background message: ${message.messageId}");
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final messaging = FirebaseMessaging.instance;


  final settings = await messaging.requestPermission();

  if (kDebugMode) {
    print('Permission granted: ${settings.authorizationStatus}');
  }

  try {
    String? token = await messaging.getToken();
    if (kDebugMode) {
      print('Registration Token=$token');
    }
  } catch (e) {
    print("Token error: $e");
  }

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    _messageStreamController.sink.add(message);

    if (navigatorKey.currentContext != null) {
      showDialog(
        context: navigatorKey.currentContext!,
        builder: (context) => AlertDialog(
          title: Text(message.notification?.title ?? "Notification"),
          content: Text(message.notification?.body ?? "No content"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        ),
      );
    }
  });

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    _messageStreamController.sink.add(message);
  });

  RemoteMessage? initialMessage =
  await FirebaseMessaging.instance.getInitialMessage();

  if (initialMessage != null) {
    _messageStreamController.sink.add(initialMessage);
  }

  FirebaseMessaging.onBackgroundMessage(
      _firebaseMessagingBackgroundHandler);

  // 📡 Topic subscription
  await messaging.subscribeToTopic('app_promotion');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'FCM Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Push Notifications'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _lastMessage = "No messages received yet";

  @override
  void initState() {
    super.initState();

    _messageStreamController.listen((message) {
      setState(() {
        _lastMessage = """
New Notification

Title: ${message.notification?.title ?? "No title"}
Body: ${message.notification?.body ?? "No body"}

Data: ${message.data}
""";
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 20),

            const Icon(
              Icons.notifications_active,
              size: 80,
              color: Colors.deepPurple,
            ),

            const SizedBox(height: 20),

            Text(
              "Live Notifications",
              style: Theme.of(context).textTheme.headlineSmall,
            ),

            const SizedBox(height: 30),

            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.deepPurple),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _lastMessage,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}