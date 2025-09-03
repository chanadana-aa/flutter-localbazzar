import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BookingScreen extends StatefulWidget {
  final String bookingId;
  final double amount;

  const BookingScreen({
    super.key,
    required this.bookingId,
    required this.amount,
  });

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  late Razorpay _razorpay;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _startPayment();
  }

  void _startPayment() {
    var options = {
      'key': 'rzp_test_htvtVhYjG0q003', // Replace with your Razorpay key
      'amount': (widget.amount * 100).toInt(), // in paise
      'name': 'Local bazaar',
      'description': 'Booking Payment',
      'prefill': {'contact': '', 'email': ''},
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint('Razorpay error: $e');
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    FirebaseFirestore.instance
        .collection('Bookings')
        .doc(widget.bookingId)
        .update({'status': 'confirmed', 'paymentId': response.paymentId});
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Payment successful!')));
    Navigator.pop(context);
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    FirebaseFirestore.instance
        .collection('Bookings')
        .doc(widget.bookingId)
        .update({'status': 'failed', 'error': response.message});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Payment failed: ${response.message}')),
    );
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Processing Payment')),
      body: const Center(child: CircularProgressIndicator()),
    );
  }
}
