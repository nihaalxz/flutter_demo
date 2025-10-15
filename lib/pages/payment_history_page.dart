import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/payment_history_DTO.dart';
import '../../services/payment_services/payment_service.dart';
import 'payment_detail_page.dart';
import '../../theme/theme.dart'; // Import the theme file

class PaymentHistoryPage extends StatefulWidget {
  const PaymentHistoryPage({super.key});

  @override
  State<PaymentHistoryPage> createState() => _PaymentHistoryPageState();
}

class _PaymentHistoryPageState extends State<PaymentHistoryPage> {
  final PaymentService _paymentService = PaymentService();
  late Future<List<PaymentHistoryDto>> _historyFuture;
  
  List<PaymentHistoryDto> _allHistory = [];
  List<PaymentHistoryDto> _filteredHistory = [];
  
  String _selectedStatus = 'All';
  DateTimeRange? _selectedDateRange;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  void _loadHistory() {
    setState(() {
      _historyFuture = _paymentService.getPaymentHistory();
    });
    
    _historyFuture.then((history) {
      setState(() {
        _allHistory = history;
        _applyFilters();
      });
    });
  }

  void _applyFilters() {
    setState(() {
      _filteredHistory = _allHistory.where((transaction) {
        // Status filter
        bool statusMatch = _selectedStatus == 'All' ||
            transaction.status.toLowerCase() == _selectedStatus.toLowerCase();

        // Date filter
        bool dateMatch = _selectedDateRange == null ||
            (transaction.createdAt.isAfter(_selectedDateRange!.start) &&
                transaction.createdAt.isBefore(_selectedDateRange!.end.add(const Duration(days: 1))));

        return statusMatch && dateMatch;
      }).toList();
    });
  }

  void _showFilterBottomSheet() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Filter Transactions',
                    style: TextStyle(
                      fontSize: 20, 
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setModalState(() {
                        _selectedStatus = 'All';
                        _selectedDateRange = null;
                      });
                      setState(() {
                        _selectedStatus = 'All';
                        _selectedDateRange = null;
                      });
                      _applyFilters();
                      Navigator.pop(context);
                    },
                    child: Text(
                      'Reset',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'Status', 
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ['All', 'Success', 'Paid', 'Failed', 'Pending'].map((status) {
                  return ChoiceChip(
                    label: Text(status),
                    selected: _selectedStatus == status,
                    selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                    labelStyle: TextStyle(
                      color: _selectedStatus == status 
                          ? Theme.of(context).colorScheme.primary 
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                    onSelected: (selected) {
                      setModalState(() => _selectedStatus = status);
                      setState(() => _selectedStatus = status);
                      _applyFilters();
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              Text(
                'Date Range', 
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.onSurface,
                  side: BorderSide(color: Theme.of(context).colorScheme.outline),
                ),
                onPressed: () async {
                  final picked = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                    initialDateRange: _selectedDateRange,
                  );
                  if (picked != null) {
                    setModalState(() => _selectedDateRange = picked);
                    setState(() => _selectedDateRange = picked);
                    _applyFilters();
                  }
                },
                icon: Icon(
                  Icons.calendar_today,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                label: Text(
                  _selectedDateRange == null
                      ? 'Select Date Range'
                      : '${DateFormat('MMM d').format(_selectedDateRange!.start)} - ${DateFormat('MMM d, yyyy').format(_selectedDateRange!.end)}',
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Apply Filters'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color scaffoldBgColor = Theme.of(context).scaffoldBackgroundColor;
    final Color cardColor = Theme.of(context).cardColor;
    final Color textColor = Theme.of(context).colorScheme.onSurface;
    final Color secondaryTextColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment History'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        elevation: Theme.of(context).appBarTheme.elevation,
        actions: [
          IconButton(
            icon: Icon(
              Icons.filter_list,
              color: Theme.of(context).appBarTheme.foregroundColor,
            ),
            onPressed: _showFilterBottomSheet,
          ),
        ],
      ),
      backgroundColor: scaffoldBgColor,
      body: SafeArea(
        child: FutureBuilder<List<PaymentHistoryDto>>(
          future: _historyFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(
                  color: Theme.of(context).colorScheme.primary,
                ),
              );
            }

            if (snapshot.hasError) {
              return _buildErrorState(snapshot.error.toString());
            }

            if (_filteredHistory.isEmpty) {
              return _buildEmptyState();
            }

            return RefreshIndicator(
              onRefresh: () async => _loadHistory(),
              child: Column(
                children: [
                  if (_selectedStatus != 'All' || _selectedDateRange != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      color: isDark 
                          ? Colors.blue.shade900.withOpacity(0.3)
                          : Colors.blue.shade50,
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline, 
                            size: 16, 
                            color: isDark ? Colors.blue.shade300 : Colors.blue.shade700,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Showing ${_filteredHistory.length} of ${_allHistory.length} transactions',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.blue.shade300 : Colors.blue.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      itemCount: _filteredHistory.length,
                      itemBuilder: (context, index) {
                        return _buildHistoryCard(_filteredHistory[index]);
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHistoryCard(PaymentHistoryDto item) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isSuccess =
        item.status.toLowerCase() == 'paid' ||
        item.status.toLowerCase() == 'success';
    final DateFormat dateFormat = DateFormat('MMM d, yyyy');
    final DateFormat timeFormat = DateFormat('h:mm a');
    final NumberFormat currencyFormat = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );

    // Theme-aware colors
    final Color cardBackground = Theme.of(context).cardColor;
    final Color textColor = Theme.of(context).colorScheme.onSurface;
    final Color secondaryTextColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    final Color successColor = isDark ? Colors.green.shade400 : Colors.green.shade700;
    final Color errorColor = isDark ? Colors.red.shade400 : Colors.red.shade700;
    final Color successBgColor = isDark 
        ? Colors.green.shade900.withOpacity(0.2)
        : Colors.green.shade50;
    final Color errorBgColor = isDark 
        ? Colors.red.shade900.withOpacity(0.2)
        : Colors.red.shade50;
    final Color successBorderColor = isDark 
        ? Colors.green.shade800.withOpacity(0.5)
        : Colors.green.shade100.withOpacity(0.5);
    final Color errorBorderColor = isDark 
        ? Colors.red.shade800.withOpacity(0.5)
        : Colors.red.shade100.withOpacity(0.5);
    final Color successStatusBg = isDark 
        ? Colors.green.shade800 
        : Colors.green.shade100;
    final Color errorStatusBg = isDark 
        ? Colors.red.shade800 
        : Colors.red.shade100;
    final Color shadowColor = isDark 
        ? Colors.black.withOpacity(0.3)
        : Colors.black.withOpacity(0.05);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: isSuccess ? successBgColor : errorBgColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isSuccess ? successBorderColor : errorBorderColor,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PaymentDetailPage(payment: item),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Status Icon with solid background
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: isSuccess
                        ? (isDark ? Colors.green.shade600 : Colors.green.shade500)
                        : (isDark ? Colors.red.shade600 : Colors.red.shade500),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: (isSuccess ? successColor : errorColor).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    isSuccess ? Icons.check_circle : Icons.cancel,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                // Transaction Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.itemName,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: textColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isSuccess ? successStatusBg : errorStatusBg,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              item.status.toUpperCase(),
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: isSuccess ? successColor : errorColor,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Owner: ${item.ownerName}',
                        style: TextStyle(
                          fontSize: 13,
                          color: secondaryTextColor,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 12, 
                            color: secondaryTextColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            dateFormat.format(item.createdAt),
                            style: TextStyle(
                              fontSize: 12,
                              color: secondaryTextColor,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.access_time,
                            size: 12, 
                            color: secondaryTextColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            timeFormat.format(item.createdAt),
                            style: TextStyle(
                              fontSize: 12,
                              color: secondaryTextColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Amount and Arrow
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      currencyFormat.format(item.amount),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: isSuccess ? successColor : errorColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        Icons.arrow_forward_ios,
                        size: 12,
                        color: secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = Theme.of(context).colorScheme.onSurface;
    final Color secondaryTextColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    return RefreshIndicator(
      onRefresh: () async => _loadHistory(),
      child: ListView(
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.25),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.receipt_long, 
                  size: 64, 
                  color: secondaryTextColor,
                ),
                const SizedBox(height: 16),
                Text(
                  'No Transactions Found',
                  style: TextStyle(
                    fontSize: 18, 
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _selectedStatus != 'All' || _selectedDateRange != null
                      ? 'Try adjusting your filters'
                      : 'Your payment history will appear here',
                  style: TextStyle(color: secondaryTextColor),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = Theme.of(context).colorScheme.onSurface;
    final Color secondaryTextColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off_rounded, 
              size: 60, 
              color: secondaryTextColor,
            ),
            const SizedBox(height: 16),
            Text(
              "Something Went Wrong",
              style: TextStyle(
                fontSize: 18, 
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: TextStyle(color: secondaryTextColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadHistory,
              child: const Text("Retry"),
            ),
          ],
        ),
      ),
    );
  }
}