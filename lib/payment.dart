import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;

class PaymentScreen extends StatefulWidget {
  final double amount;
  final String userId;
  final String movieId;
  final String theaterId;
  final String showtimeId;
  final List<String> selectedSeats;

  const PaymentScreen({
    super.key,
    required this.amount,
    required this.userId,
    required this.movieId,
    required this.theaterId,
    required this.showtimeId,
    required this.selectedSeats,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool isProcessing = false;
  Map<String, dynamic>? paymentIntent;

  @override
  void initState() {
    super.initState();
    makePayment(); // auto-start
  }

  Future<void> makePayment() async {
    setState(() => isProcessing = true);

    try {
      // Use your Node.js backend URL here
      const backendUrl = "http://10.0.2.2:3000/create-payment-intent";

      // 1️⃣ Create PaymentIntent via backend
      final response = await http.post(
        Uri.parse(backendUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "amount": (widget.amount * 100).toInt(), // smallest currency unit
          "currency": "usd",
          "userId": widget.userId,
          "movieId": widget.movieId,
          "theaterId": widget.theaterId,
          "showtimeId": widget.showtimeId,
          "selectedSeats": widget.selectedSeats,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception(
            "Failed to create PaymentIntent: ${response.body}");
      }

      // 2️⃣ Decode clientSecret from backend response
      paymentIntent = jsonDecode(response.body);
      final clientSecret = paymentIntent!['clientSecret'];

      // 3️⃣ Initialize Payment Sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'Movie App 🎬',
          customFlow: true,
          googlePay: const PaymentSheetGooglePay(
            merchantCountryCode: 'US', // change if needed
            currencyCode: 'USD',
            testEnv: true,
          ),
        ),
      );

      // 4️⃣ Display Payment Sheet
      await Stripe.instance.presentPaymentSheet();

      if (mounted) {
        Navigator.pop(context, true); // ✅ payment success
      }
    } catch (e) {
      debugPrint("❌ Payment failed: $e");
      if (mounted) {
        Navigator.pop(context, false); // ❌ payment failed
      }
    } finally {
      if (mounted) setState(() => isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Processing Payment")),
      body: Center(
        child: isProcessing
            ? const CircularProgressIndicator()
            : const Text("Finalizing payment..."),
      ),
    );
  }
}
