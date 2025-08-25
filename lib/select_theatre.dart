import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shimmer/shimmer.dart';
import 'seat_selection.dart';

class Theater {
  final String id;
  final String name;
  final String location;
  final List<Showtime> showtimes;

  Theater({required this.id, required this.name, required this.location, required this.showtimes});
}

class Showtime {
  final String id;
  final String time;
  final String screenId;

  Showtime({required this.id, required this.time, required this.screenId});
}

Future<List<Theater>> fetchTheatersForMovie(String movieId) async {
  try {
    QuerySnapshot theaterSnapshot = await FirebaseFirestore.instance.collection('theaters').get();
    if (theaterSnapshot.docs.isEmpty) return [];

    List<Theater> theaters = [];

    for (var doc in theaterSnapshot.docs) {
      String theaterId = doc.id;
      String theaterName = doc['name'];
      String location = doc['location'];

      QuerySnapshot screenSnapshot = await doc.reference.collection('screens').get();
      List<Showtime> allShowtimes = [];

      for (var screenDoc in screenSnapshot.docs) {
        QuerySnapshot showtimeSnapshot = await screenDoc.reference
            .collection('showtimes')
            .where('startTime', isGreaterThan: Timestamp.now()) // 🔥 Only fetch upcoming showtimes
            .get();

        List<Showtime> showtimes = showtimeSnapshot.docs
            .where((showtimeDoc) => showtimeDoc['movieId'] == movieId)
            .map((showtimeDoc) => Showtime(
          id: showtimeDoc.id,
          time: showtimeDoc['time'],
          screenId: screenDoc.id,
        ))
            .toList();
        allShowtimes.addAll(showtimes);
      }

      if (allShowtimes.isNotEmpty) {
        theaters.add(Theater(id: theaterId, name: theaterName, location: location, showtimes: allShowtimes));
      }
    }
    return theaters;
  } catch (e) {
    print("Error fetching theaters: $e");
    return [];
  }
}


class TheaterListScreen extends StatefulWidget {
  final String movieId;
  const TheaterListScreen({Key? key, required this.movieId}) : super(key: key);

  @override
  _TheaterListScreenState createState() => _TheaterListScreenState();
}

class _TheaterListScreenState extends State<TheaterListScreen> {
  TextEditingController textController = TextEditingController();
  String searchLocation = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('🎭 Select a Theater')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: textController,
              decoration: InputDecoration(
                labelText: 'Search by Location',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onChanged: (value) {
                setState(() => searchLocation = value);
              },
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Theater>>(
              future: fetchTheatersForMovie(widget.movieId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return ListView.builder(
                    itemCount: 5,
                    itemBuilder: (context, index) => Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No theaters available for this movie.'));
                }

                List<Theater> filteredTheaters = snapshot.data!
                    .where((theater) => theater.location.toLowerCase().contains(searchLocation.toLowerCase()))
                    .toList();

                return ListView.builder(
                  itemCount: filteredTheaters.length,
                  itemBuilder: (context, index) {
                    final theater = filteredTheaters[index];
                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: InkWell(
                        onTap: () {
                          if (theater.showtimes.isNotEmpty) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SeatSelectionScreen(
                                  movieId: widget.movieId,
                                  theaterId: theater.id,
                                  screenId: theater.showtimes.first.screenId,
                                  showtimeId: theater.showtimes.first.id,
                                  userId: FirebaseAuth.instance.currentUser?.uid ?? 'guest',
                                ),
                              ),
                            );
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ListTile(
                                leading: const Icon(Icons.movie, color: Colors.blueAccent, size: 40),
                                title: Text(theater.name, style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
                                subtitle: Text(theater.location, style: TextStyle(fontSize: 20, color: Colors.grey[600])),
                              ),
                              Wrap(
                                spacing: 10.0,
                                children: theater.showtimes.map((showtime) {
                                  return ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue.shade50,
                                    ),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => SeatSelectionScreen(
                                            movieId: widget.movieId,
                                            theaterId: theater.id,
                                            screenId: showtime.screenId,
                                            showtimeId: showtime.id,
                                            userId: FirebaseAuth.instance.currentUser?.uid ?? 'guest',
                                          ),
                                        ),
                                      );
                                    },
                                    child: Text(showtime.time, style: TextStyle(color: Colors.deepPurpleAccent, fontWeight: FontWeight.bold)),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}