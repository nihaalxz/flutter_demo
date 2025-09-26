import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:myfirstflutterapp/models/BookingResponseDTO.dart';
import 'package:myfirstflutterapp/services/rental_service.dart';
import 'package:myfirstflutterapp/services/MapLauncherService.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:myfirstflutterapp/environment/env.dart';

enum HandoverAction { start, complete }

class RentalHandoverPage extends StatefulWidget {
  final BookingResponseDTO booking;
  final HandoverAction action;

  const RentalHandoverPage({
    super.key,
    required this.booking,
    required this.action,
  });

  @override
  State<RentalHandoverPage> createState() => _RentalHandoverPageState();
}

class _RentalHandoverPageState extends State<RentalHandoverPage> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _rentalService = RentalService();
  bool _isSubmitting = false;

  String get _pageTitle =>
      widget.action == HandoverAction.start ? 'Start Rental' : 'Complete Rental';
  String get _promptText => widget.action == HandoverAction.start
      ? 'Enter the 6-digit Start Code from the owner to begin your rental.'
      : 'Enter the 6-digit Return Code from the renter to complete the rental.';
  String get _buttonText =>
      widget.action == HandoverAction.start ? 'Start Rental' : 'Confirm Return';

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  /// Handles the submission of the handover code.
  Future<void> _submitCode() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    try {
      if (widget.action == HandoverAction.start) {
        await _rentalService.startRental(widget.booking.id, _codeController.text);
      } else {
        await _rentalService.completeRental(widget.booking.id, _codeController.text);
      }

      if (mounted) {
        // ✅ Use adaptive feedback and navigate on success
        _showAdaptiveFeedback(
          isError: false,
          title: 'Success!',
          content: 'The rental has been ${_pageTitle.toLowerCase()}.',
          // On success, pop the page when the user dismisses the dialog.
          onDismiss: () => Navigator.of(context).pop(true), 
        );
      }
    } catch (e) {
      if (mounted) {
        // On failure, show a clear, adaptive dialog with the specific error.
         _showAdaptiveFeedback(
          isError: true,
          title: 'Error',
          content: e.toString().replaceAll("Exception: ", ""),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  /// ✅ NEW: Shows a platform-native dialog for all feedback.
  void _showAdaptiveFeedback({
    required bool isError,
    required String title,
    required String content,
    VoidCallback? onDismiss,
  }) {
    showAdaptiveDialog(
      context: context,
      builder: (context) => AlertDialog.adaptive(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            child: const Text('OK'),
            onPressed: () {
              Navigator.of(context).pop(); // Close the dialog
              onDismiss?.call(); // Then trigger the navigation
            },
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Platform.isIOS
        ? _buildCupertinoPage()
        : _buildMaterialPage();
  }

  Widget _buildMaterialPage() {
    return Scaffold(
      appBar: AppBar(title: Text(_pageTitle)),
      body: _buildBody(),
    );
  }

  Widget _buildCupertinoPage() {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(middle: Text(_pageTitle)),
      child: SafeArea(
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildItemHeader(),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 24),
          
          Text(
            _promptText,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 24),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: TextFormField(
              controller: _codeController,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 8),
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(
                counterText: "",
                labelText: '6-Digit Code',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.length != 6) {
                  return 'Please enter a valid 6-digit code.';
                }
                return null;
              },
            ),
          ),
          const SizedBox(height: 32),

          if (_isSubmitting)
            const Center(child: CircularProgressIndicator.adaptive())
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Platform.isIOS
                ? CupertinoButton.filled(
                    onPressed: _submitCode,
                    child: Text(_buttonText),
                  )
                : ElevatedButton(
                    onPressed: _submitCode,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(_buttonText),
                  ),
            ),
        ],
      ),
    );
  }

  Widget _buildItemHeader() {
    final isIOS = Platform.isIOS;
    return Container(
      decoration: BoxDecoration(
        color: isIOS 
          ? CupertinoColors.secondarySystemGroupedBackground
          : Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: CachedNetworkImage(
                    imageUrl: "${AppConfig.imageBaseUrl}${widget.booking.itemImage}",
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.booking.itemName, style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text("Booking ID: #${widget.booking.id}", style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Icon(isIOS ? CupertinoIcons.location_solid : Icons.location_on, color: Colors.grey.shade600, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(widget.booking.locationName, style: TextStyle(color: Colors.grey.shade800))),
                TextButton(
                  onPressed: () {
                    MapLauncherService.openMap(widget.booking.latitude, widget.booking.longitude);
                  },
                  child: const Text("View on Map"),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

