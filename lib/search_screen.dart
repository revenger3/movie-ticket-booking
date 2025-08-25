import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'description.dart';

class SearchScreen extends StatefulWidget {
  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final String apikey = '2d24410'; // Replace with your OMDb API Key
  TextEditingController searchController = TextEditingController();
  Future<List<Movie>>? futureMovies;

  // Fetch movies based on search query
  Future<List<Movie>> fetchMovies(String query) async {
    if (query.isEmpty) return [];

    final url = Uri.parse('https://www.omdbapi.com/?s=$query&apikey=$apikey');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      if (data['Response'] == 'True' && data['Search'] != null) {
        return (data['Search'] as List)
            .map((movie) => Movie.fromJson(movie))
            .toList();
      }
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Search Movies')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                labelText: 'Search for movies...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15.0)),
              ),
              onSubmitted: (query) {
                setState(() {
                  futureMovies = fetchMovies(query);
                });
              },
            ),
          ),
          Expanded(
            child: futureMovies == null
                ? Center(child: Text('Search for movies to see results'))
                : FutureBuilder<List<Movie>>(
              future: futureMovies,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('No movies found'));
                }

                return ListView.builder(
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    final movie = snapshot.data![index];

                    return ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: movie.poster != 'N/A'
                            ? Image.network(movie.poster, width: 80, height: 100, fit: BoxFit.cover)
                            : Image.asset('assets/images/placeholder.jpg', width: 80, height: 100),
                      ),
                      title: Text(movie.title),
                      subtitle: Text('Year: ${movie.year}'),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => Description(imdbID: movie.imdbID),
                          ),
                        );
                      },
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

// 🔹 Movie Model
class Movie {
  final String imdbID;
  final String title;
  final String year;
  final String poster;

  Movie({required this.imdbID, required this.title, required this.year, required this.poster});

  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
      imdbID: json['imdbID'],
      title: json['Title'],
      year: json['Year'],
      poster: json['Poster'],
    );
  }
}
