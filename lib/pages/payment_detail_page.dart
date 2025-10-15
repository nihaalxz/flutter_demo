import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/payment_history_DTO.dart';

class PaymentDetailPage extends StatefulWidget {
  final PaymentHistoryDto payment;

  const PaymentDetailPage({super.key, required this.payment});

  @override
  State<PaymentDetailPage> createState() => _PaymentDetailPageState();
}

class _PaymentDetailPageState extends State<PaymentDetailPage> {
  final GlobalKey _screenshotKey = GlobalKey();
  bool _isSharing = false;

  Future<void> _shareReceipt() async {
    setState(() => _isSharing = true);

    try {
      RenderRepaintBoundary boundary = _screenshotKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/payment_receipt.png');
      await file.writeAsBytes(pngBytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Payment Receipt - ${widget.payment.itemName}',
      );
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isSuccess =
        widget.payment.status.toLowerCase() == 'paid' ||
        widget.payment.status.toLowerCase() == 'success';
    
    final DateFormat dateFormat = DateFormat('MMM d, yyyy');
    final DateFormat timeFormat = DateFormat('h:mm a');
    final NumberFormat currencyFormat = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
    );

    // Theme-aware colors
    final successColor = isSuccess
        ? (isDark ? const Color(0xFF10B981) : Colors.green.shade700)
        : (isDark ? const Color(0xFFEF4444) : Colors.red.shade700);
    
    final bgColor = isSuccess
        ? (isDark ? const Color(0xFF10B981).withOpacity(0.1) : Colors.green.shade50)
        : (isDark ? const Color(0xFFEF4444).withOpacity(0.1) : Colors.red.shade50);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction Details'),
        actions: [
          IconButton(
            icon: _isSharing
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: isDark ? Colors.white : Theme.of(context).primaryColor,
                    ),
                  )
                : const Icon(Icons.share),
            onPressed: _isSharing ? null : _shareReceipt,
          ),
        ],
      ),
      body: RepaintBoundary(
        key: _screenshotKey,
        child: Container(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Status Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32.0),
                  decoration: BoxDecoration(
                    color: bgColor,
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: isSuccess
                                ? [
                                    isDark ? const Color(0xFF10B981) : Colors.green.shade400,
                                    isDark ? const Color(0xFF059669) : Colors.green.shade600,
                                  ]
                                : [
                                    isDark ? const Color(0xFFEF4444) : Colors.red.shade400,
                                    isDark ? const Color(0xFFDC2626) : Colors.red.shade600,
                                  ],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: successColor.withOpacity(0.3),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Icon(
                          isSuccess ? Icons.check_circle : Icons.cancel,
                          size: 34,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        isSuccess ? 'Payment Successful' : 'Payment Failed',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : successColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        currencyFormat.format(widget.payment.amount),
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: successColor,
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
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 6),
                      _buildDetailCard([
                        _buildDetailRow('Item Name', widget.payment.itemName, isDark),
                        _buildDetailRow('Owner', widget.payment.ownerName, isDark),
                        _buildDetailRow('Status', widget.payment.status.toUpperCase(), isDark),
                        _buildDetailRow('Payment Method', widget.payment.paymentMethod, isDark),
                        _buildDetailRow(
                          'Date',
                          dateFormat.format(widget.payment.createdAt),
                          isDark,
                        ),
                        _buildDetailRow(
                          'Time',
                          timeFormat.format(widget.payment.createdAt),
                          isDark,
                        ),
                        _buildDetailRow(
                          'Amount',
                          currencyFormat.format(widget.payment.amount),
                          isDark,
                          isHighlight: true,
                        ),
                      ], isDark),

                      const SizedBox(height: 6),
                      Text(
                        'Payment Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildDetailCard([
                        _buildDetailRow('Order ID', widget.payment.orderId, isDark),
                        _buildDetailRow('Booking ID', '#${widget.payment.bookingId}', isDark),
                        _buildDetailRow('Currency', widget.payment.currency.toUpperCase(), isDark),
                      ], isDark),

                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark 
                              ? const Color(0xFF374151).withOpacity(0.5)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: isDark
                              ? Border.all(color: const Color(0xFF4B5563), width: 1)
                              : null,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: isDark ? const Color(0xFF9CA3AF) : Colors.grey[700],
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'For any queries, please contact support with your transaction ID.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? const Color(0xFF9CA3AF) : Colors.grey[700],
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
        ),
      ),
    );
  }

  Widget _buildDetailCard(List<Widget> children, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2E37) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isDark
            ? Border.all(color: const Color(0xFF374151), width: 1)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: children,
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, bool isDark, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? const Color(0xFF9CA3AF) : Colors.grey[700],
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
                color: isHighlight
                    ? (isDark ? const Color(0xFF10B981) : Colors.green.shade700)
                    : (isDark ? Colors.white : Colors.black87),
              ),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }
}