import 'package:flutter/material.dart';
import 'package:myfirstflutterapp/pages/search_screen.dart';

class HomeSearchBar extends StatelessWidget {
  // ✅ FIX: Removed the unnecessary 'context' parameter from the constructor.
  const HomeSearchBar({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    // The 'context' is automatically available inside the build method.
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            blurRadius: 15,
            color: Theme.of(context).shadowColor.withOpacity(0.05),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SearchPage()),
          );
        },
        child: IgnorePointer( // Prevents the keyboard from opening on the HomePage
          child: TextField(
            enabled: false, // Disables typing but keeps the UI look
            decoration: InputDecoration(
              filled: true,
              fillColor: Theme.of(context).cardColor,
              hintText: 'Search Products...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
              prefixIcon: const Icon(Icons.search),
            ),
          ),
        ),
      ),
    );
  }
}
