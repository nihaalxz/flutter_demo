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
  bool _offerSubmitted = false; // Disables input after offer is made
  String? _errorMessage; // For input validation errors

  @override
  void initState() {
    super.initState();
    _loadExistingOffer();
  }

  Future<void> _loadExistingOffer() async {
    setState(() => _isLoading = true);

    try {
      OfferResponseDTO? existing =
          await _offerService.getOfferByProduct(widget.productId);

      _messages.add({
        "isUser": false,
        "text": "Seller’s Price: ₹${widget.originalPrice.toStringAsFixed(2)}",
        "icon": Icons.store,
      });

      if (existing != null) {
        _messages.add({
          "isUser": true,
          "text": "You offered ₹${existing.offeredPrice.toStringAsFixed(2)}",
          "icon": Icons.thumb_up_alt_outlined,
        });
        _messages.add({
          "isUser": false,
          "text": "Status: ${existing.status}",
          "icon": _getStatusIcon(existing.status),
        });

        if (existing.status.toLowerCase() == "pending") {
          _offerSubmitted = true;
        }
      } else {
        _messages.add({
          "isUser": false,
          "text": "No previous offers. Make your best offer!",
          "icon": Icons.info_outline,
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("⚠️ Could not load offer history: $e")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return Icons.check_circle_outline;
      case 'rejected':
        return Icons.cancel_outlined;
      case 'pending':
        return Icons.hourglass_bottom_outlined;
      default:
        return Icons.help_outline;
    }
  }

  Future<void> _sendOffer() async {
    final inputText = _controller.text.trim();
    if (inputText.isEmpty) {
      setState(() => _errorMessage = "Please enter an offer price.");
      return;
    }

    final offerValue = double.tryParse(inputText);
    if (offerValue == null || offerValue <= 0) {
      setState(() => _errorMessage = "Please enter a valid positive number.");
      return;
    }

    if (offerValue >= widget.originalPrice) {
      setState(() => _errorMessage = "Offer should be less than the seller's price.");
      return;
    }

    setState(() {
      _errorMessage = null;
      _messages.add({
        "isUser": true,
        "text": "You offered ₹${offerValue.toStringAsFixed(2)}",
        "icon": Icons.thumb_up_alt_outlined,
      });
      _isLoading = true;
      _offerSubmitted = true;
    });

    try {
      OfferResponseDTO response =
          await _offerService.createOffer(widget.productId, offerValue);

      setState(() {
        _messages.add({
          "isUser": false,
          "text": "Offer submitted ✅ (Status: ${response.status})",
          "icon": Icons.check_circle_outline,
        });
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Offer submitted successfully!")),
      );
    } catch (e) {
      setState(() {
        _messages.add({
          "isUser": false,
          "text": "❌ Failed to submit offer: $e",
          "icon": Icons.error_outline,
        });
        _offerSubmitted = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to submit offer: $e")),
      );
    } finally {
      setState(() => _isLoading = false);
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Make an Offer for ${widget.productName}"),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
      ),
      body: SafeArea( // ✅ Added SafeArea
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.blueAccent.withOpacity(0.1),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Original Price: ₹${widget.originalPrice.toStringAsFixed(2)}",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Icon(Icons.local_offer, color: Colors.blueAccent, size: 28),
                ],
              ),
            ),
            Expanded(
              child: _isLoading && _messages.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final msg = _messages[index];
                        final isUser = msg["isUser"] as bool;
                        final icon = msg["icon"] as IconData?;

                        return Align(
                          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: isUser ? Colors.blueAccent : Colors.grey.shade200,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(isUser ? 20 : 0),
                                topRight: Radius.circular(isUser ? 0 : 20),
                                bottomLeft: const Radius.circular(20),
                                bottomRight: const Radius.circular(20),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (!isUser && icon != null)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: Icon(icon, color: Colors.blueAccent, size: 20),
                                  ),
                                Flexible(
                                  child: Text(
                                    msg["text"],
                                    style: TextStyle(
                                      color: isUser ? Colors.white : Colors.black87,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                if (isUser && icon != null)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 8),
                                    child: Icon(icon, color: Colors.white, size: 20),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            if (_isLoading) const LinearProgressIndicator(color: Colors.blueAccent),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 14),
                      ),
                    ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          enabled: !_offerSubmitted && !_isLoading,
                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            hintText: _offerSubmitted
                                ? "Waiting for seller’s response..."
                                : "Enter your offer price (e.g., 500.00)...",
                            prefixText: "₹ ",
                            prefixStyle: const TextStyle(color: Color.fromARGB(221, 255, 255, 255)),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: const Color.fromARGB(0, 245, 245, 245),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: _offerSubmitted || _isLoading ? null : _sendOffer,
                        icon: const Icon(Icons.send),
                        label: const Text("Send"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(255, 248, 248, 248),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ],
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
