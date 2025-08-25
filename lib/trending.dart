import 'package:flutter/material.dart';
import 'description.dart';
import 'text.dart';

class TrendingMovies extends StatefulWidget {
  final List trending;

  const TrendingMovies({Key? key, required this.trending}) : super(key: key);

  @override
  _TrendingMoviesState createState() => _TrendingMoviesState();
}

class _TrendingMoviesState extends State<TrendingMovies> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          modified_text(
            text: '🔥 Trending Movies',
            size: 26,
            color: Colors.white,
          ),
          SizedBox(height: 10),

          // ✅ ListView for horizontal scrolling
          SizedBox(
            height: 220,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: widget.trending.length,
              itemBuilder: (context, index) {
                var movie = widget.trending[index];

                String imageUrl = movie['Poster'] != null && movie['Poster'] != 'N/A'
                    ? movie['Poster']
                    : 'https://via.placeholder.com/150'; // Placeholder if image is null

                String title = movie['Title'] ?? 'Loading'; // Default title fallback

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Description(imdbID: movie['imdbID'] ?? ''),
                      ),
                    );
                  },
                  child: Container(
                    margin: EdgeInsets.only(right: 12),
                    width: 140,
                    child: Column(
                      children: [
                        // ✅ Movie Poster
                        Container(
                          height: 200,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.5),
                                blurRadius: 8,
                                spreadRadius: 2,
                                offset: Offset(2, 4),
                              ),
                            ],
                            image: DecorationImage(
                              image: NetworkImage(imageUrl),
                              fit: BoxFit.cover,
                            ),
                          ),
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              width: double.infinity,
                              padding: EdgeInsets.symmetric(vertical: 8, horizontal: 5),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    Colors.black.withOpacity(0.8),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                              child: modified_text(
                                size: 15,
                                text: title,
                                color: Colors.white,

                              ),
                            ),
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
