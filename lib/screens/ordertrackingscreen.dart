import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class RealTimeOrderStatusScreen extends StatelessWidget {
  final String bookingId;

  RealTimeOrderStatusScreen({super.key, required this.bookingId});

  final List<String> statusSteps = [
    'pending',
    'confirmed',
    'shipped',
    'delivered',
  ];

  int getStatusIndex(String status) {
    return statusSteps.contains(status) ? statusSteps.indexOf(status) : 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Order Status")),
      body: StreamBuilder<DocumentSnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('Bookings')
                .doc(bookingId)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Order not found"));
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final status = data['status'] ?? 'pending';
          final amount = data['totalAmount'] ?? 0;
          final lastUpdated =
              (data['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now();

          final now = DateTime.now();
          final diffHours = now.difference(lastUpdated).inHours;
          int currentStep = getStatusIndex(status);

          if (diffHours >= 12 && currentStep < statusSteps.length - 1) {
            currentStep += 1;
          }

          final List<dynamic> rawItems = data['items'] ?? [];
          final List<Map<String, dynamic>> items =
              rawItems.map((item) => Map<String, dynamic>.from(item)).toList();

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              Text(
                "Booking ID: $bookingId",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text("Status: ${statusSteps[currentStep].toUpperCase()}"),
              Text("Amount: ₹$amount"),
              const SizedBox(height: 20),
              const Text(
                "Order Progress",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Stepper(
                physics: const NeverScrollableScrollPhysics(),
                currentStep: currentStep,
                controlsBuilder: (context, _) => const SizedBox(),
                steps:
                    statusSteps.map((step) {
                      final stepIndex = statusSteps.indexOf(step);
                      return Step(
                        title: Text(step.toUpperCase()),
                        content: const SizedBox(),
                        isActive: stepIndex <= currentStep,
                        state:
                            stepIndex < currentStep
                                ? StepState.complete
                                : StepState.indexed,
                      );
                    }).toList(),
              ),
              const Divider(),
              const Text(
                "Items",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              if (items.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text("No items found"),
                )
              else
                ...items.map(
                  (item) => ListTile(
                    title: Text(item['name'] ?? 'No name'),
                    subtitle: Text("Qty: ${item['quantity']}"),
                    trailing: Text("₹${item['price']}"),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class OrderTrackingScreen extends StatefulWidget {
  const OrderTrackingScreen({super.key});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _setupFirebaseMessaging();
  }

  void _setupFirebaseMessaging() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    final token = await messaging.getToken();
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid != null && token != null) {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'fcmToken': token,
      });
    }

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification != null) {
        _showNotification(notification.title ?? '', notification.body ?? '');
      }
    });
  }

  void _showNotification(String title, String body) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'order_channel',
          'Order Updates',
          importance: Importance.high,
          priority: Priority.high,
        );
    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );
    await flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      notificationDetails,
    );
  }

  @override
  Widget build(BuildContext context) {
    final String userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text("My Orders")),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('Bookings')
                .where('userId', isEqualTo: userId)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No bookings found"));
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final bookings = snapshot.data!.docs;

          return ListView.builder(
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final doc = bookings[index];
              final data = doc.data() as Map<String, dynamic>;
              final bookingId = doc.id;
              final status = data['status'] ?? 'pending';
              final amount = data['totalAmount'] ?? 0;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text("Booking ID: $bookingId"),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Status: ${status.toUpperCase()}"),
                      Text("Amount: ₹$amount"),
                    ],
                  ),
                  trailing: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => RealTimeOrderStatusScreen(
                                bookingId: bookingId,
                              ),
                        ),
                      );
                    },
                    child: const Text("Track Order"),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
