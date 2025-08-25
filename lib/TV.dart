import 'package:flutter/material.dart';
import 'package:movie_app_flutter/text.dart';
import 'package:movie_app_flutter/description.dart';

class TV extends StatelessWidget {
  final List tv;

  const TV({Key? key, required this.tv}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          modified_text(
            text: '🔥 New TV Releases',
            size: 28,
            color: Colors.white,
          ),
          SizedBox(height: 10),
          SizedBox(
            height: 270,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: tv.length,
              itemBuilder: (context, index) {
                var tvShow = tv[index];

                String imageUrl = tvShow['Poster'] != null && tvShow['Poster'] != 'N/A'
                    ? tvShow['Poster']
                    : 'https://via.placeholder.com/150'; // Placeholder image

                String title = tvShow['Title'] ?? 'Loading';
                String imdbID = tvShow['imdbID'] ?? '';
                String rating = (6 + (index % 4) * 0.8).toStringAsFixed(1); // Fake rating generator

                return GestureDetector(
                  onTap: () {
                    if (imdbID.isNotEmpty) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Description(imdbID: imdbID),
                        ),
                      );
                    }
                  },
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    margin: EdgeInsets.only(right: 12),
                    width: 160,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.6),
                          blurRadius: 8,
                          spreadRadius: 2,
                          offset: Offset(3, 5),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        // Poster Image
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            imageUrl,
                            height: 230,
                            width: 160,
                            fit: BoxFit.cover,
                          ),
                        ),
                        // Glassmorphism Overlay
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
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
                        // IMDb Rating Badge
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade600,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.5),
                                  blurRadius: 4,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.star, color: Colors.white, size: 16),
                                SizedBox(width: 4),
                                Text(
                                  rating,
                                  style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Title at Bottom
                        Positioned(
                          bottom: 12,
                          left: 12,
                          right: 12,
                          child: modified_text(
                            size: 16,
                            text: title,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
