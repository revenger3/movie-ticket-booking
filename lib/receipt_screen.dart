import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReceiptScreen extends StatefulWidget {
  final String userId;
  final String movieId;
  final String theaterId;
  final String showtimeId;
  final List<String> selectedSeats;
  final double totalAmount;

  ReceiptScreen({
    required this.userId,
    required this.movieId,
    required this.theaterId,
    required this.showtimeId,
    required this.selectedSeats,
    required this.totalAmount,
  });

  @override
  _ReceiptScreenState createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends State<ReceiptScreen> {
  bool isReceiptSaved = false;

  @override
  void initState() {
    super.initState();
    _saveReceiptToFirestore();
  }

  Future<void> _saveReceiptToFirestore() async {
    if (isReceiptSaved) return;

    final receiptRef = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('receipts');

    await receiptRef.add({
      'movieId': widget.movieId,
      'theaterId': widget.theaterId,
      'showtimeId': widget.showtimeId,
      'selectedSeats': widget.selectedSeats,
      'totalAmount': widget.totalAmount,
      'timestamp': FieldValue.serverTimestamp(),
    });

    setState(() {
      isReceiptSaved = true;
    });
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('🎟️ Booking Receipt'),
        backgroundColor: Colors.redAccent,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 80),
                  SizedBox(height: 10),
                  Text(
                    'Booking Confirmed!',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                ],
              ),
            ),
            SizedBox(height: 30),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white54,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black,
                    blurRadius: 5,
                    spreadRadius: 2,
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow('🎬 Movie ID:', widget.movieId),
                  _buildInfoRow('🏛 Theater ID:', widget.theaterId),
                  _buildInfoRow('⏰ Showtime ID:', widget.showtimeId),
                  SizedBox(height: 10),
                  Text('🪑 Selected Seats:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Wrap(
                    children: widget.selectedSeats.map((seat) => Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Chip(
                        label: Text(seat, style: TextStyle(color: Colors.brown,fontSize: 16)),
                        backgroundColor: Colors.blueGrey,
                      ),
                    )).toList(),
                  ),
                  SizedBox(height: 10),
                  Divider(),
                  _buildInfoRow(
                    '💰 Total Amount:',
                    '\$${widget.totalAmount.toStringAsFixed(2)}',
                    isBold: true,
                    textColor: Colors.redAccent,
                  ),
                ],
              ),
            ),
            Spacer(),
            Center(
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                  backgroundColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 5,
                ),
                child: Text('Done', style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isBold = false, Color textColor = Colors.black}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          Text(
            value,
            style: TextStyle(fontSize: 16, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: textColor),
          ),
        ],
      ),
    );
  }
}
