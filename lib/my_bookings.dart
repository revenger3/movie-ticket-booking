import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MyBookingsScreen extends StatelessWidget {
  final String userId;

  MyBookingsScreen({required this.userId}) {
    print("Opening MyBookingsScreen for userId: $userId"); // Debugging
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('🎟 My Bookings'),
        backgroundColor: Colors.redAccent,
        centerTitle: true,
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('receipts')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No bookings found.'));
          }

          return ListView(
            padding: EdgeInsets.all(10),
            children: snapshot.data!.docs.map((doc) {
              var data = doc.data() as Map<String, dynamic>;
              return Card(
                elevation: 3,
                margin: EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  leading: Icon(Icons.movie, color: Colors.blueGrey),
                  title: Text('Movie ID: ${data['movieId']}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Theater: ${data['theaterId']}'),
                      Text('Showtime: ${data['showtimeId']}'),
                      Text('Seats: ${data['selectedSeats'].join(", ")}'),
                      Text('Total: \$${data['totalAmount'].toStringAsFixed(2)}'),
                    ],
                  ),
                  trailing: Icon(Icons.arrow_forward_ios, size: 16),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
