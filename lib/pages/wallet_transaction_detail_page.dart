import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:myfirstflutterapp/models/wallet_DTO/wallet_transaction.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/wallet_DTO/wallet_view.dart';
import '../../theme/theme.dart'; // Import the theme file

class WalletTransactionDetailPage extends StatefulWidget {
  final WalletTransaction transaction;

  const WalletTransactionDetailPage({super.key, required this.transaction});

  @override
  State<WalletTransactionDetailPage> createState() =>
      _WalletTransactionDetailPageState();
}

class _WalletTransactionDetailPageState
    extends State<WalletTransactionDetailPage> {
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _isSharing = false;

  Future<void> _shareReceipt() async {
    setState(() => _isSharing = true);

    try {
      // Capture only the widget inside Screenshot (excludes AppBar)
      final Uint8List? imageBytes = await _screenshotController.capture(
        delay: const Duration(milliseconds: 200),
        pixelRatio: 3.0, // high-quality image
      );

      if (imageBytes != null) {
        final directory = await getTemporaryDirectory();
        final file = File('${directory.path}/wallet_transaction.png');
        await file.writeAsBytes(imageBytes);

        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'Wallet Transaction - ${widget.transaction.description}',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to share: $e')),
        );
      }
    } finally {
      setState(() => _isSharing = false);
    }
  }

  Widget _buildReceiptContent(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isCredit = widget.transaction.type.toLowerCase() == 'credit' ||
        widget.transaction.type.toLowerCase() == 'refund';

    final DateFormat dateFormat = DateFormat('MMM d, yyyy');
    final DateFormat timeFormat = DateFormat('h:mm a');
    final NumberFormat currencyFormat = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
    );

    // Determine colors and icon based on type and theme
    Color primaryColor;
    Color bgColor;
    IconData icon;

    if (isCredit) {
      primaryColor = isDark ? Colors.green.shade400 : Colors.green.shade700;
      bgColor = isDark ? 
          Colors.green.shade900.withOpacity(0.3) : 
          Colors.green.shade50;
      icon = Icons.arrow_downward;
    } else {
      primaryColor = isDark ? Colors.orange.shade400 : Colors.orange.shade700;
      bgColor = isDark ? 
          Colors.orange.shade900.withOpacity(0.3) : 
          Colors.orange.shade50;
      icon = Icons.arrow_upward;
    }

    final Color scaffoldBgColor = Theme.of(context).scaffoldBackgroundColor;
    final Color textColor = Theme.of(context).colorScheme.onSurface;
    final Color secondaryTextColor = isDark ? 
        Colors.grey.shade400 : 
        Colors.grey.shade700;
    final Color infoBoxColor = isDark ? 
        Colors.blueGrey.shade800 : 
        Colors.grey.shade100;

    return Container(
      color: scaffoldBgColor,
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Transaction Type Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32.0),
              decoration: BoxDecoration(color: bgColor),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(isDark ? 0.3 : 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 34, color: primaryColor),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.transaction.type.toUpperCase(),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${isCredit ? '+' : '-'} ${currencyFormat.format(widget.transaction.amount)}',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                ],
              ),
            ),

            // Transaction Details
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Transaction Details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _buildDetailCard(context, [
                    _buildDetailRow(
                      context,
                      'Transaction Type',
                      widget.transaction.type.toUpperCase(),
                    ),
                    _buildDetailRow(
                      context,
                      'Date',
                      dateFormat.format(widget.transaction.timestamp),
                    ),
                    _buildDetailRow(
                      context,
                      'Time',
                      timeFormat.format(widget.transaction.timestamp),
                    ),
                    _buildDetailRow(
                      context,
                      'Amount',
                      currencyFormat.format(widget.transaction.amount),
                      isHighlight: true,
                      highlightColor: primaryColor,
                    ),
                  ]),

                  if (widget.transaction.description != null && 
                      widget.transaction.description!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    _buildDetailCard(context, [
                      _buildDetailRow(
                        context,
                        'Description',
                        widget.transaction.description!,
                      ),
                    ]),
                  ],

                  if (widget.transaction.relatedBookingId != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Related Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _buildDetailCard(context, [
                      _buildDetailRow(
                        context,
                        'Booking ID',
                        '#${widget.transaction.relatedBookingId}',
                      ),
                    ]),
                  ],

                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: infoBoxColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline, 
                          color: isDark ? 
                              Colors.blue.shade300 : 
                              Colors.grey.shade700,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'For any queries regarding this transaction, please contact support.',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? 
                                  Colors.grey.shade300 : 
                                  Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ],
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction Details'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        elevation: Theme.of(context).appBarTheme.elevation,
        actions: [
          IconButton(
            icon: _isSharing
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Theme.of(context).appBarTheme.foregroundColor ?? 
                            (Theme.of(context).brightness == Brightness.dark ? 
                             Colors.white : Colors.black),
                    ),
                  )
                : Icon(
                    Icons.share,
                    color: Theme.of(context).appBarTheme.foregroundColor,
                  ),
            onPressed: _isSharing ? null : _shareReceipt,
          ),
        ],
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Screenshot(
        controller: _screenshotController,
        child: _buildReceiptContent(context),
      ),
    );
  }

  Widget _buildDetailCard(BuildContext context, List<Widget> children) {
    return Card(
      elevation: 2,
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: children,
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value, {
    bool isHighlight = false,
    Color? highlightColor,
  }) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color defaultTextColor = Theme.of(context).colorScheme.onSurface;
    final Color secondaryTextColor = isDark ? 
        Colors.grey.shade400 : 
        Colors.grey.shade700;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: secondaryTextColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
                color: isHighlight 
                    ? (highlightColor ?? Theme.of(context).colorScheme.primary)
                    : defaultTextColor,
              ),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              maxLines: 3,
            ),
          ),
        ],
      ),
    );
  }
}