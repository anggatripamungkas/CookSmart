import 'package:flutter/material.dart';

class FavoriteItem extends StatelessWidget {
  final String title;
  final String imageUrl;

  FavoriteItem({required this.title, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Image.network(imageUrl),
      title: Text(title),
    );
  }
}
