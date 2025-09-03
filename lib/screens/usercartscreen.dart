import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:localbazzar/screens/bookingscreen.dart';

class CartScreen extends StatefulWidget {
  final List<String> cartItems;
  final Function(String) removeFromCart;

  const CartScreen({
    super.key,
    required this.cartItems,
    required this.removeFromCart,
  });

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  List<Map<String, dynamic>> _cartProducts = [];

  @override
  void initState() {
    super.initState();

    _fetchCartProducts();
  }

  Future<void> _fetchCartProducts() async {
    List<Map<String, dynamic>> fetchedProducts = [];

    List<Future<void>> fetchTasks = [];

    for (String productId in widget.cartItems) {
      fetchTasks.add(_fetchProductById(productId, fetchedProducts));
    }

    await Future.wait(fetchTasks);

    setState(() {
      _cartProducts = fetchedProducts;
    });
  }

  Future<void> _fetchProductById(
    String productId,
    List<Map<String, dynamic>> fetchedProducts,
  ) async {
    for (String category in [
      'Mens',
      'Womens',
      'Kitchen',
      'Footwear',
      'Electronics',
      'Kids',
    ]) {
      try {
        DocumentSnapshot doc =
            await FirebaseFirestore.instance
                .collection(category)
                .doc(productId)
                .get();

        if (doc.exists) {
          Map<String, dynamic> product = doc.data() as Map<String, dynamic>;
          product['productId'] = productId;
          product['quantity'] = 1;
          fetchedProducts.add(product);
          break; // Stop checking other categories
        }
      } catch (e) {
        print("Error fetching product in $category: $e");
      }
    }
  }

  void _increaseQuantity(int index) {
    setState(() {
      _cartProducts[index]['quantity'] += 1;
    });
  }

  void _decreaseQuantity(int index) {
    setState(() {
      if (_cartProducts[index]['quantity'] > 1) {
        _cartProducts[index]['quantity'] -= 1;
      } else {
        // Remove item if quantity is 1 and minus clicked
        widget.removeFromCart(_cartProducts[index]['productId']);
        _cartProducts.removeAt(index);
      }
    });
  }

  double getTotalPrice() {
    double total = 0.0;
    for (var product in _cartProducts) {
      total += (product['price'] ?? 0) * (product['quantity'] ?? 1);
    }
    return total;
  }

  void _buyNow() async {
    final bookingData =
        _cartProducts
            .map(
              (product) => {
                'name': product['name'],
                'price': product['price'],
                'imageBase64': product['imageBase64'],
                'quantity': product['quantity'],
                'timestamp': DateTime.now(),
              },
            )
            .toList();

    DocumentReference bookingRef = await FirebaseFirestore.instance
        .collection('Bookings')
        .add({
          'items': bookingData,
          'status': 'pending',
          'userId': FirebaseAuth.instance.currentUser?.uid ?? 'anonymous',
          'totalAmount': getTotalPrice(),
          'timestamp': DateTime.now(),
        });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => BookingScreen(
              bookingId: bookingRef.id,
              amount: getTotalPrice(),
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Cart')),
      body:
          _cartProducts.isEmpty
              ? const Center(child: Text('Your cart is empty'))
              : Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: _cartProducts.length,
                      itemBuilder: (context, index) {
                        final product = _cartProducts[index];
                        return ListTile(
                          leading:
                              product['imageBase64'] != null
                                  ? Image.memory(
                                    base64Decode(product['imageBase64']),
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                  )
                                  : const Icon(Icons.image_not_supported),
                          title: Text(product['name'] ?? 'No name'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '₹${product['price']?.toStringAsFixed(2) ?? '0.00'}',
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove),
                                    onPressed: () => _decreaseQuantity(index),
                                  ),
                                  Text(product['quantity'].toString()),
                                  IconButton(
                                    icon: const Icon(Icons.add),
                                    onPressed: () => _increaseQuantity(index),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () {
                              widget.removeFromCart(product['productId']);
                              setState(() {
                                _cartProducts.removeAt(index);
                              });
                            },
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      children: [
                        Text(
                          'Total: ₹${getTotalPrice().toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton.icon(
                          onPressed: _buyNow,
                          icon: const Icon(Icons.shopping_cart_checkout),
                          label: const Text('Buy Now'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50),
                            backgroundColor: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
    );
  }
}
