import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:localbazzar/screens/ordertrackingscreen.dart';
import 'package:localbazzar/screens/usercartscreen.dart';
import 'package:localbazzar/screens/userprofile.dart';

class UserApp extends StatelessWidget {
  const UserApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Local bazaar',
      theme: ThemeData(
        primaryColor: Colors.teal,
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.teal,
          accentColor: Colors.amber,
        ).copyWith(secondary: Colors.amber),
        scaffoldBackgroundColor: Colors.grey[50],
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
          elevation: 4,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        textTheme: TextTheme(
          headlineSmall: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          bodyMedium: TextStyle(fontSize: 14, color: Colors.grey[700]),
        ),
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final List<String> _cartItems = [];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _addToCart(String productId) {
    if (!_cartItems.contains(productId)) {
      setState(() {
        _cartItems.add(productId);
      });
    }
  }

  void _removeFromCart(String productId) {
    if (_cartItems.contains(productId)) {
      setState(() {
        _cartItems.remove(productId);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          HomeScreen(
            selectedCategory: 'Mens',
            cartItems: _cartItems,
            addToCart: _addToCart,
            removeFromCart: _removeFromCart,
          ),
          CartScreen(
            key: ValueKey(_cartItems.length),
            cartItems: _cartItems,
            removeFromCart: _removeFromCart,
          ),

          OrderTrackingScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Cart',
          ),

          BottomNavigationBarItem(icon: Icon(Icons.receipt), label: 'Myorders'),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ), // <-- New item
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.teal,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        elevation: 8,
        onTap: _onItemTapped,
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final String selectedCategory;
  final List<String> cartItems;
  final Function(String) addToCart;
  final Function(String) removeFromCart;

  const HomeScreen({
    super.key,
    required this.selectedCategory,
    required this.cartItems,
    required this.addToCart,
    required this.removeFromCart,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late String _selectedCategory;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.selectedCategory;
  }

  void _selectCategory(String category) {
    setState(() {
      _selectedCategory = category;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> _categories = [
      {'name': 'Mens', 'icon': Icons.man},
      {'name': 'Womens', 'icon': Icons.woman},
      {'name': 'Kitchen', 'icon': Icons.kitchen},
      {'name': 'Footwear', 'icon': Icons.sports},
      {'name': 'Electronics', 'icon': Icons.devices},
      {'name': 'Kids', 'icon': Icons.child_care},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Local Bazar'),
        actions: [],
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.teal, Colors.tealAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children:
                    _categories
                        .map(
                          (category) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: ChoiceChip(
                              label: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(category['icon'], size: 16),
                                  const SizedBox(width: 4),
                                  Text(category['name']),
                                ],
                              ),
                              selected:
                                  _selectedCategory ==
                                  category['name'].toLowerCase(),
                              selectedColor: Colors.teal,
                              backgroundColor: Colors.grey[200],
                              labelStyle: TextStyle(
                                color:
                                    _selectedCategory ==
                                            category['name'].toLowerCase()
                                        ? Colors.white
                                        : Colors.teal,
                              ),
                              onSelected:
                                  (_) => _selectCategory(category['name']),
                            ),
                          ),
                        )
                        .toList(),
              ),
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection(_selectedCategory)
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No products found'));
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 200,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final product =
                        snapshot.data!.docs[index].data()
                            as Map<String, dynamic>;
                    return ProductCard(
                      product: product,
                      onBuyNow: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => ProductDetailsScreen(
                                  productId: product['productId'],
                                  category: _selectedCategory,
                                  cartItems: widget.cartItems,
                                  addToCart: widget.addToCart,
                                  removeFromCart: widget.removeFromCart,
                                ),
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

class ProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final VoidCallback onBuyNow;

  const ProductCard({super.key, required this.product, required this.onBuyNow});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onBuyNow,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image with animation
            Expanded(
              child: Hero(
                tag: 'product_${product['productId']}',
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    child:
                        product['imageBase64'] != null
                            ? Image.memory(
                              base64Decode(product['imageBase64']),
                              fit: BoxFit.cover,
                              width: double.infinity,
                              errorBuilder:
                                  (context, error, stackTrace) => Container(
                                    color: Colors.grey[200],
                                    child: const Icon(
                                      Icons.image_not_supported,
                                      size: 50,
                                      color: Colors.grey,
                                    ),
                                  ),
                            )
                            : Container(
                              color: Colors.grey[200],
                              child: const Icon(
                                Icons.image_not_supported,
                                size: 50,
                                color: Colors.grey,
                              ),
                            ),
                  ),
                ),
              ),
            ),
            // Product details
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['name'] ?? 'No Name',
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${product['price']?.toStringAsFixed(2) ?? '0.00'}',
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.amber,
                    ),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onBuyNow,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        textStyle: const TextStyle(fontSize: 12),
                      ),
                      child: const Text('Buy Now'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProductDetailsScreen extends StatefulWidget {
  final String productId;
  final String category;
  final List<String> cartItems;
  final Function(String) addToCart;
  final Function(String) removeFromCart;

  const ProductDetailsScreen({
    super.key,
    required this.productId,
    required this.category,
    required this.cartItems,
    required this.addToCart,
    required this.removeFromCart,
  });

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  bool _isInCart = false;

  @override
  void initState() {
    super.initState();
    _checkCartStatus();
  }

  void _checkCartStatus() {
    setState(() {
      _isInCart = widget.cartItems.contains(widget.productId);
    });
  }

  void _addToCart() {
    if (!_isInCart) {
      widget.addToCart(widget.productId);
      setState(() {
        _isInCart = true;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Added to cart!')));
    }
  }

  void _removeFromCart() {
    if (_isInCart) {
      widget.removeFromCart(widget.productId);
      setState(() {
        _isInCart = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Removed from cart!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Details'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.teal, Colors.tealAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection(widget.category)
                .doc(widget.productId)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError ||
              !snapshot.hasData ||
              !snapshot.data!.exists) {
            return const Center(child: Text('Product not found'));
          }

          final product = snapshot.data!.data() as Map<String, dynamic>;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product image
                Hero(
                  tag: 'product_${product['productId']}',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child:
                        product['imageBase64'] != null
                            ? Image.memory(
                              base64Decode(product['imageBase64']),
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: 300,
                              errorBuilder:
                                  (context, error, stackTrace) => Container(
                                    color: Colors.grey[200],
                                    height: 300,
                                    child: const Icon(
                                      Icons.image_not_supported,
                                      size: 50,
                                      color: Colors.grey,
                                    ),
                                  ),
                            )
                            : Container(
                              color: Colors.grey[200],
                              height: 300,
                              child: const Icon(
                                Icons.image_not_supported,
                                size: 50,
                                color: Colors.grey,
                              ),
                            ),
                  ),
                ),
                const SizedBox(height: 16),
                // Product name
                Text(
                  product['name'] ?? 'No Name',
                  style: Theme.of(
                    context,
                  ).textTheme.headlineSmall!.copyWith(color: Colors.teal),
                ),
                const SizedBox(height: 8),
                // Product price
                Text(
                  '₹${product['price']?.toStringAsFixed(2) ?? '0.00'}',
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.amber,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 24),
                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          // Placeholder for buy now action
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Buy Now clicked!')),
                          );
                        },
                        child: const Text('Buy Now'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isInCart ? _removeFromCart : _addToCart,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.teal),
                          foregroundColor: Colors.teal,
                        ),
                        child: Text(
                          _isInCart ? 'Remove from Cart' : 'Add to Cart',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
