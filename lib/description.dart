import 'package:flutter/material.dart';
import 'package:movie_app_flutter/select_theatre.dart';
import 'package:movie_app_flutter/text.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class Description extends StatefulWidget {
  final String imdbID;

  const Description({Key? key, required this.imdbID}) : super(key: key);

  @override
  _DescriptionState createState() => _DescriptionState();
}

class _DescriptionState extends State<Description> {
  String name = 'Not Loaded',
      description = 'No description available',
      bannerurl = '',
      posterurl = '',
      vote = 'N/A',
      launch_on = 'Not Available';

  final String apikey = '2d24410';

  @override
  void initState() {
    super.initState();
    fetchMovieDetails();
  }

  Future<void> fetchMovieDetails() async {
    final url =
    Uri.parse('https://www.omdbapi.com/?i=${widget.imdbID}&apikey=$apikey');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      var data = json.decode(response.body);

      setState(() {
        name = data['Title'] ?? 'Not Loaded';
        description = data['Plot'] ?? 'No description available';
        bannerurl = data['Poster'] != 'N/A' ? data['Poster'] : '';
        posterurl = data['Poster'] != 'N/A' ? data['Poster'] : '';
        vote = data['imdbRating'] ?? 'N/A';
        launch_on = data['Released'] ?? 'Not Available';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ✅ Background Banner Image
          Positioned.fill(
            child: bannerurl.isNotEmpty
                ? Image.network(bannerurl, fit: BoxFit.cover)
                : Container(color: Colors.black),
          ),

          // ✅ Dark Gradient Overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.8),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // ✅ Back Button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  color: Colors.black.withOpacity(0.4),
                  child: IconButton(
                    icon: Icon(Icons.arrow_back_ios_new, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
            ),
          ),

          // ✅ Movie Details
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 420, // Increased height to fit IMDb ID
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.6),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // ✅ Movie Title
                  modified_text(text: name, size: 26, color: Colors.white),

                  SizedBox(height: 5),

                  // ✅ 🎬 Show IMDb ID
                  Text(
                    "Movie ID: ${widget.imdbID}",
                    style: TextStyle(fontSize: 16, color: Colors.grey[400]),
                  ),

                  SizedBox(height: 8),

                  // ✅ IMDb Rating & Release Date
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.star, color: Colors.yellow, size: 20),
                      SizedBox(width: 5),
                      modified_text(
                        text: 'IMDb $vote',
                        size: 16,
                        color: Colors.grey[300]!,
                      ),
                      SizedBox(width: 15),
                      Icon(Icons.calendar_today, color: Colors.white, size: 16),
                      SizedBox(width: 5),
                      modified_text(
                        text: launch_on,
                        size: 16,
                        color: Colors.grey[300]!,
                      ),
                    ],
                  ),

                  SizedBox(height: 20),

                  // ✅ Movie Description Box
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 15),
                    child: Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: modified_text(
                          text: description,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 30),

                  // ✅ Book Now Button
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                TheaterListScreen(movieId: widget.imdbID),
                          ),
                        );
                      },
                      child: Container(
                        width: 200,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.redAccent, Colors.orangeAccent],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.4),
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: modified_text(
                            text: '🎟️ Book Now',
                            size: 18,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
