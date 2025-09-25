import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:myfirstflutterapp/services/rental_service.dart';

enum HandoverAction { start, complete }

class RentalHandoverPage extends StatefulWidget {
  final int bookingId;
  final HandoverAction action;

  const RentalHandoverPage({
    super.key,
    required this.bookingId,
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
      ? 'Please enter the 6-digit Start Code provided by the owner to begin your rental.'
      : 'Please enter the 6-digit Return Code provided by the renter to complete the rental.';
  String get _buttonText =>
      widget.action == HandoverAction.start ? 'Start Rental' : 'Confirm Return';

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _submitCode() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      if (widget.action == HandoverAction.start) {
        await _rentalService.startRental(widget.bookingId, _codeController.text);
      } else {
        await _rentalService.completeRental(widget.bookingId, _codeController.text);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Success! The rental has been ${_pageTitle.toLowerCase()}.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true); // Return true to signal a refresh
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().replaceAll("Exception: ", "")}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Platform.isIOS
        ? CupertinoPageScaffold(
            navigationBar: CupertinoNavigationBar(middle: Text(_pageTitle)),
            child: _buildBody(),
          )
        : Scaffold(
            appBar: AppBar(title: Text(_pageTitle)),
            body: _buildBody(),
          );
  }

  Widget _buildBody() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          Icon(
            widget.action == HandoverAction.start
                ? Icons.qr_code_scanner
                : Icons.key,
            size: 80,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(height: 24),
          Text(
            _promptText,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 32),
          TextFormField(
            controller: _codeController,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 8),
            keyboardType: TextInputType.number,
            maxLength: 6,
            decoration: const InputDecoration(
              counterText: "", // Hide the character counter
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
          const SizedBox(height: 32),
          if (_isSubmitting)
            const Center(child: CircularProgressIndicator.adaptive())
          else
            ElevatedButton(
              onPressed: _submitCode,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(_buttonText),
            ),
        ],
      ),
    );
  }
}
