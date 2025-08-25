import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:movie_app_flutter/payment.dart';
import 'package:movie_app_flutter/receipt_screen.dart';
import 'package:animate_do/animate_do.dart';

class SeatSelectionScreen extends StatefulWidget {
  final String movieId;
  final String theaterId;
  final String screenId;
  final String showtimeId;
  final String userId;

  const SeatSelectionScreen({
    Key? key,
    required this.movieId,
    required this.theaterId,
    required this.screenId,
    required this.showtimeId,
    required this.userId,
  }) : super(key: key);

  @override
  _SeatSelectionScreenState createState() => _SeatSelectionScreenState();
}

class _SeatSelectionScreenState extends State<SeatSelectionScreen> {
  List<String> selectedSeats = [];
  List<String> bookedSeats = [];
  final double seatPrice = 10.0;
  bool isProcessing = false;

  @override
  void initState() {
    super.initState();
    _fetchBookedSeats();
  }

  Future<void> _fetchBookedSeats() async {
    try {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('theaters')
          .doc(widget.theaterId)
          .collection('screens')
          .doc(widget.screenId)
          .collection('showtimes')
          .doc(widget.showtimeId)
          .get();

      if (snapshot.exists) {
        Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
        setState(() {
          bookedSeats = List<String>.from(data['selectedSeats'] ?? []);
        });
      }
    } catch (e) {
      print("⚠️ Error fetching booked seats: $e");
    }
  }

  Future<bool> _bookSeats(double totalAmount) async {
    DocumentReference bookingRef = FirebaseFirestore.instance
        .collection('theaters')
        .doc(widget.theaterId)
        .collection('screens')
        .doc(widget.screenId)
        .collection('showtimes')
        .doc(widget.showtimeId);

    return FirebaseFirestore.instance.runTransaction((transaction) async {
      DocumentSnapshot snapshot = await transaction.get(bookingRef);

      List<String> alreadyBooked = [];
      if (snapshot.exists && snapshot.data() != null) {
        var data = snapshot.data() as Map<String, dynamic>;
        alreadyBooked = List<String>.from(data['selectedSeats'] ?? []);
      }

      bool isSeatAvailable = selectedSeats.every((seat) => !alreadyBooked.contains(seat));
      if (!isSeatAvailable) {
        throw Exception("Some selected seats are already booked. Try again.");
      }

      transaction.set(
        bookingRef,
        {
          'selectedSeats': FieldValue.arrayUnion(selectedSeats),
          'totalAmount': totalAmount,
          'userId': widget.userId,
          'movieId': widget.movieId,
          'timestamp': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }).then((_) => true).catchError((error) {
      print("⚠️ Booking Error: $error");
      return false;
    });
  }

  @override
  Widget build(BuildContext context) {
    double totalAmount = selectedSeats.length * seatPrice;

    return Scaffold(
      appBar: AppBar(title: const Text('Select Your Seats 🎟️')),
      body: Column(
        children: [
          const SizedBox(height: 10),
          FadeInDown(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildSeatLegend(Colors.green, "Selected"),
                const SizedBox(width: 10),
                _buildSeatLegend(Colors.red, "Booked"),
                const SizedBox(width: 10),
                _buildSeatLegend(Colors.grey, "Available"),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 12.0,
                  mainAxisSpacing: 12.0,
                ),
                itemCount: 20,
                itemBuilder: (context, index) {
                  String seatNumber = 'S${index + 1}';
                  bool isBooked = bookedSeats.contains(seatNumber);
                  bool isSelected = selectedSeats.contains(seatNumber);

                  return GestureDetector(
                    onTap: isBooked
                        ? null
                        : () {
                      setState(() {
                        isSelected
                            ? selectedSeats.remove(seatNumber)
                            : selectedSeats.add(seatNumber);
                      });
                    },
                    child: FadeInUp(
                      child: Container(
                        decoration: BoxDecoration(
                          color: isBooked
                              ? Colors.red
                              : isSelected
                              ? Colors.green
                              : Colors.grey[300],
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Center(
                          child: Text(
                            seatNumber,
                            style: TextStyle(
                              color: isBooked ? Colors.white : Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: (selectedSeats.isNotEmpty && !isProcessing)
                  ? () async {
                setState(() {
                  isProcessing = true;
                });

                bool? paymentSuccess = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PaymentScreen(
                      amount: totalAmount,
                      userId: widget.userId,
                      movieId: widget.movieId,
                      theaterId: widget.theaterId,
                      showtimeId: widget.showtimeId,
                      selectedSeats: List.from(selectedSeats),
                    ),
                  ),
                );

                if (paymentSuccess == true) {
                  bool bookingSuccess = await _bookSeats(totalAmount);
                  if (bookingSuccess) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ReceiptScreen(
                          userId: widget.userId,
                          movieId: widget.movieId,
                          theaterId: widget.theaterId,
                          showtimeId: widget.showtimeId,
                          selectedSeats: List.from(selectedSeats),
                          totalAmount: totalAmount,
                        ),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text("⚠️ Booking failed. Try again.")),
                    );
                  }
                }

                setState(() {
                  isProcessing = false;
                });
              }
                  : null,
              child: isProcessing
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text('Confirm Selection (\$${totalAmount.toStringAsFixed(2)})'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeatLegend(Color color, String label) {
    return Row(
      children: [
        Container(width: 15, height: 15, color: color),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontSize: 14)),
      ],
    );
  }
}
