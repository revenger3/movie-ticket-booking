import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:movie_app_flutter/TV.dart';
import 'package:movie_app_flutter/profile_screen.dart';
import 'package:movie_app_flutter/topRatedMovies.dart';
import 'package:movie_app_flutter/firebase_options.dart';
import 'package:movie_app_flutter/search_screen.dart';
import 'package:movie_app_flutter/trending.dart';
import 'package:movie_app_flutter/login_page.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'my_bookings.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully');
  } catch (e) {
    print('Firebase initialization failed: $e');
    // Continue without Firebase for now
  }

  Stripe.publishableKey = 'pk_test_51QpHeaK9TNgWmqYBWEwqYcX6h1SgcZsg2cklvNuIBI7LWGxTQ5EZIduxGrK4uYR09cBS5dwzpejaeX48OlmeN1Ws001mk04jDh';

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.teal,
        scaffoldBackgroundColor: Colors.black,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => LoginScreen(),
        '/signup': (context) => SignupScreen(),
      },
    );
  }
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  List<Map<String, dynamic>> userReceipts = [];
  final String apikey = '2d24410';
  var nameSearch = TextEditingController();
  List trendingmovies = [];
  List topratedmovies = [];
  List tv = [];

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser; // Assign user before fetching
    loadMovies();
    fetchUserReceipts();
  }


  Future<void> fetchUserReceipts() async {
    if (user == null) {
      print("User is null, skipping receipt fetch.");
      return;
    }

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('receipts')
        .orderBy('timestamp', descending: true)
        .get();

    setState(() {
      userReceipts = snapshot.docs.map((doc) => doc.data()).toList();
    });

    print("Fetched receipts: $userReceipts"); // Debug log
  }


  void _showReceiptDialog(Map<String, dynamic> receipt) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: Text("Booking Details", style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("🎬 Movie: ${receipt['movieId']}",
                  style: TextStyle(color: Colors.white70)),
              Text("🏛 Theater: ${receipt['theaterId']}",
                  style: TextStyle(color: Colors.white70)),
              Text("⏰ Showtime: ${receipt['showtimeId']}",
                  style: TextStyle(color: Colors.white70)),
              Text("🪑 Seats: ${receipt['selectedSeats'].join(', ')}",
                  style: TextStyle(color: Colors.white70)),
              Text("💰 Amount: \$${receipt['totalAmount']}", style: TextStyle(
                  color: Colors.redAccent, fontWeight: FontWeight.bold)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Close", style: TextStyle(color: Colors.tealAccent)),
            )
          ],
        );
      },
    );
  }

  Future<void> loadMovies() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    try {
      var trendingResult = await fetchMovies('star');
      var topRatedResult = await fetchMovies('batman');
      var tvResult = await fetchMovies('marvel');

      setState(() {
        trendingmovies = trendingResult;
        topratedmovies = topRatedResult;
        tv = tvResult;
      });

      await prefs.setString('trendingMovies', json.encode(trendingResult));
      await prefs.setString('topRatedMovies', json.encode(topRatedResult));
      await prefs.setString('tvShows', json.encode(tvResult));
    } catch (e) {
      String? cachedTrending = prefs.getString('trendingMovies');
      String? cachedTopRated = prefs.getString('topRatedMovies');
      String? cachedTV = prefs.getString('tvShows');

      if (cachedTrending != null && cachedTopRated != null &&
          cachedTV != null) {
        setState(() {
          trendingmovies =
          List<Map<String, dynamic>>.from(json.decode(cachedTrending));
          topratedmovies =
          List<Map<String, dynamic>>.from(json.decode(cachedTopRated));
          tv = List<Map<String, dynamic>>.from(json.decode(cachedTV));
        });
      }
    }
  }

  Future<List<Map<String, dynamic>>> fetchMovies(String query) async {
    final url = Uri.parse('https://www.omdbapi.com/?s=$query&apikey=$apikey');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      var data = json.decode(response.body);
      if (data['Response'] == 'True' && data['Search'] != null) {
        return List<Map<String, dynamic>>.from(data['Search']);
      }
    }
    return [];
  }

  var user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('filmFest 🎬', style: TextStyle(fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.tealAccent)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      drawer: _buildDrawer(context, FirebaseAuth.instance.currentUser),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildCarouselSlider(),
            TV(tv: tv),
            TrendingMovies(trending: trendingmovies),
            TopRatedMovies(toprated: topratedmovies),
          ],
        ),
      ),
    );
  }

  Widget _buildCarouselSlider() {
    return CarouselSlider(
      options: CarouselOptions(
          height: 200, autoPlay: true, enlargeCenterPage: true),
      items: trendingmovies.take(5).map((movie) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.network(movie['Poster'] ?? '', fit: BoxFit.cover),
        );
      }).toList(),
    );
  }

  Widget _buildDrawer(BuildContext context, User? user) {
    return Drawer(
      child: Container(
        color: Colors.grey[900],
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(user?.displayName ?? 'Guest User'),
              accountEmail: Text(user?.email ?? 'No Email'),
              currentAccountPicture: CircleAvatar(
                child: Text(user?.displayName?.substring(0, 1) ?? 'U',
                    style: TextStyle(fontSize: 24)),
              ),
            ),
            ListTile(
              leading: Icon(Icons.home),
              title: Text('Home'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: Icon(Icons.person),
              title: Text('Profile'),
              onTap: (){
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ProfileScreen(),
                  ),
                );
              },
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.receipt),
              title: Text('My Bookings'),
              onTap: () {
                if (user != null) {
                  Navigator.pop(context); // Close drawer
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MyBookingsScreen(userId: user.uid),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Please log in to view bookings")),
                  );
                }
              },
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('Logout'),
              onTap: ()async{
                await FirebaseAuth.instance.signOut();

                // 2️⃣ Navigate to login screen and remove all previous screens
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                      (route) => false, // removes all previous routes
                );
              }
            ),
          ],
        ),
      ),
    );
  }
}

