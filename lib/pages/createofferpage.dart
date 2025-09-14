import 'package:flutter/material.dart';
import '../models/Offer_DTO/OfferResponse_DTO.dart';
import '../services/offers_service.dart';

class CreateOfferPage extends StatefulWidget {
  final String productName;
  final double originalPrice;
  final int productId;

  const CreateOfferPage({
    super.key,
    required this.productName,
    required this.originalPrice,
    required this.productId,
  });

  @override
  State<CreateOfferPage> createState() => _CreateOfferPageState();
}

class _CreateOfferPageState extends State<CreateOfferPage> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  final OfferService _offerService = OfferService();

  bool _isLoading = false;
  bool _offerSubmitted = false; // 🚀 disables input after offer is made

  @override
  void initState() {
    super.initState();
    _loadExistingOffer();
  }

  Future<void> _loadExistingOffer() async {
    setState(() => _isLoading = true);

    try {
      // 👇 fetch any existing offer for this product
      OfferResponseDTO? existing =
          await _offerService.getOfferByProduct(widget.productId);

      _messages.add({
        "isUser": false,
        "text": "Seller’s Price: ₹${widget.originalPrice}",
      });

      if (existing != null) {
        _messages.add({
          "isUser": true,
          "text": "You offered ₹${existing.offeredPrice}",
        });
        _messages.add({
          "isUser": false,
          "text": "Status: ${existing.status}", // e.g., Pending / Accepted / Rejected
        });

        // If still pending, block user from sending another
        if (existing.status.toLowerCase() == "pending") {
          _offerSubmitted = true;
        }
      }
    } catch (e) {
      _messages.add({
        "isUser": false,
        "text": "⚠️ Could not load offer history: $e",
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendOffer() async {
    if (_controller.text.trim().isEmpty) return;

    final offerValue = double.tryParse(_controller.text.trim());
    if (offerValue == null) return;

    setState(() {
      _messages.add({
        "isUser": true,
        "text": "You offered ₹$offerValue",
      });
      _isLoading = true;
      _offerSubmitted = true; // 🚀 disable further input
    });

    try {
      OfferResponseDTO response =
          await _offerService.createOffer(widget.productId, offerValue);

      setState(() {
        _messages.add({
          "isUser": false,
          "text": "Offer submitted ✅ (Status: ${response.status})",
        });
      });
    } catch (e) {
      setState(() {
        _messages.add({
          "isUser": false,
          "text": "❌ Failed to submit offer: $e",
        });
        _offerSubmitted = false; // allow retry if API failed
      });
    } finally {
      setState(() => _isLoading = false);
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Offer for ${widget.productName}"),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg["isUser"] as bool;

                return Align(
                  alignment:
                      isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUser
                          ? Colors.blueAccent.withOpacity(0.8)
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      msg["text"],
                      style: TextStyle(
                        color: isUser ? Colors.white : Colors.black87,
                        fontSize: 16,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isLoading) const LinearProgressIndicator(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    enabled: !_offerSubmitted, // 🚀 disabled if offer already sent
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: _offerSubmitted
                          ? "Wait for seller’s response..."
                          : "Enter your offer price...",
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _offerSubmitted || _isLoading ? null : _sendOffer,
                  icon: const Icon(Icons.send, color: Colors.blueAccent),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
