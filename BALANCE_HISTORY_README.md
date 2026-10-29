# Balance History Page

This document explains the Balance History page implementation that follows the same design pattern as the Notifications page, providing a comprehensive transaction history view with filtering and statistics.

## Overview

The Balance History page provides:
- **Transaction History**: Complete list of all financial transactions
- **Statistics Cards**: Monthly and overall financial summaries
- **Filtering**: Filter by transaction type (All, Income, Expenses)
- **Pagination**: Load more transactions as needed
- **Pull-to-Refresh**: Refresh data by pulling down
- **Empty State**: Helpful message when no transactions exist

## Design Pattern

The Balance History page follows the same design pattern as the Notifications page:

### Similarities with Notifications Page:
- ✅ **Same Layout Structure**: AppBar + Body with ListView
- ✅ **Card-based Items**: Each transaction is displayed in a card
- ✅ **Loading States**: CircularProgressIndicator during loading
- ✅ **Empty States**: Centered message when no data
- ✅ **Pull-to-Refresh**: RefreshIndicator for data refresh
- ✅ **Consistent Styling**: Same colors, spacing, and typography

### Enhancements over Notifications Page:
- 📊 **Statistics Cards**: Monthly and overall financial summaries
- 🔍 **Filtering System**: Filter by transaction type
- 📱 **Pagination**: Load more functionality
- 💰 **Financial Data**: Transaction amounts, types, and status
- 📅 **Date Formatting**: Proper date display
- 🎨 **Color Coding**: Different colors for different transaction types

## Features

### 1. Statistics Cards
- **Current Month Statistics**: Shows income and expenses for the current month
- **Overall Statistics**: Shows total income and expenses
- **Visual Indicators**: Icons and colors for different metrics

### 2. Transaction Filtering
- **All Transactions**: Shows all transactions
- **Income Only**: Shows only credit/payment transactions
- **Expenses Only**: Shows only debit/withdrawal transactions

### 3. Transaction Items
Each transaction shows:
- **Transaction Icon**: Visual indicator of transaction type
- **Description**: Transaction description
- **Method**: Payment method (Cash, Bank, Card, etc.)
- **Date**: Formatted date
- **Amount**: Formatted amount with +/- indicator
- **Status**: Transaction status (Completed, Pending, Failed)

### 4. Pagination
- **Load More**: Button to load additional transactions
- **Loading State**: Shows loading indicator while fetching
- **End Detection**: Automatically detects when no more data

## Implementation Details

### Models

#### BalanceTransaction
```dart
class BalanceTransaction {
  final int id;
  final String type; // 'credit', 'debit', 'withdrawal', 'payment'
  final String amount;
  final String description;
  final String method; // 'cash', 'bank', 'card', etc.
  final String status; // 'completed', 'pending', 'failed'
  final String createdAt;
  final String? referenceId;
  final String? notes;
}
```

#### BalanceHistoryResponse
```dart
class BalanceHistoryResponse {
  final String status;
  final String message;
  final List<BalanceTransaction> transactions;
  final int totalCount;
}
```

### Provider

#### BalanceHistoryProvider
- **State Management**: Manages transaction data and UI state
- **API Integration**: Handles API calls for balance history
- **Filtering**: Provides filtering functionality
- **Pagination**: Manages pagination logic
- **Statistics**: Calculates financial statistics

### Key Methods:
```dart
// Fetch balance history
Future<void> fetchBalanceHistory({bool refresh = false})

// Load more transactions
Future<void> loadMoreTransactions()

// Filter transactions
void setFilter(String filter)

// Get statistics
Map<String, double> getTransactionStats()
```

## UI Components

### 1. Statistics Cards
```dart
Widget _buildStatisticsCards(BalanceHistoryProvider provider)
```
- Shows current month and overall statistics
- Uses color-coded indicators
- Displays income vs expenses

### 2. Filter Section
```dart
Widget _buildFilterSection(BalanceHistoryProvider provider)
```
- Filter chips for All, Income, Expenses
- Active state styling
- Smooth transitions

### 3. Transaction Item
```dart
Widget _buildTransactionItem(BuildContext context, BalanceTransaction transaction)
```
- Card-based layout
- Color-coded transaction types
- Status indicators
- Formatted amounts

### 4. Empty State
```dart
Widget _buildEmptyState()
```
- Centered layout
- Helpful message
- Refresh button

## Usage Examples

### Navigation
```dart
// Navigate to Balance History page
Nav.to(const BalanceHistoryPage());

// Or use the helper class
BalanceHistoryNavigationExample.navigateToBalanceHistory();
```

### Integration with Wallet
```dart
// Add to wallet page
ElevatedButton(
  onPressed: () => Nav.to(const BalanceHistoryPage()),
  child: const Text('View Transaction History'),
)
```

### Custom Filtering
```dart
// Filter by specific type
provider.setFilter('credit'); // Show only income
provider.setFilter('debit');  // Show only expenses
provider.setFilter('all');    // Show all transactions
```

## API Integration

### Required API Endpoint
```php
// api_balance_history.php
POST /services/api_balance_history.php
Headers: X-API-KEY, Content-Type
Body: {
  clientId: string,
  page: number,
  limit: number,
  filter: string,
  status: string
}
```

### Expected Response
```json
{
  "status": "success",
  "message": "Balance history retrieved successfully",
  "total_count": 25,
  "transactions": [
    {
      "id": 1,
      "type": "credit",
      "amount": "100.00",
      "description": "Payment received",
      "method": "bank",
      "status": "completed",
      "created_at": "2024-01-15T10:30:00Z",
      "reference_id": "REF123",
      "notes": "Monthly payment"
    }
  ]
}
```

## Styling

### Colors
- **Primary**: AppColors.primary for main elements
- **Green**: For income/credit transactions
- **Red**: For expenses/debit transactions
- **Orange**: For pending transactions
- **Grey**: For neutral elements

### Typography
- **Title**: 16px, FontWeight.w600
- **Description**: 14px, FontWeight.bold
- **Details**: 12px, normal weight
- **Date**: 10px, grey color

### Spacing
- **Card Padding**: 12px
- **Item Spacing**: 16px
- **Section Margins**: 16px
- **Icon Sizes**: 40px containers, 20px icons

## Error Handling

### Network Errors
- Shows error dialog using AppUtils
- Provides retry functionality
- Graceful fallback to empty state

### Data Validation
- Handles null/empty responses
- Validates date formats
- Safely parses amounts

### Loading States
- Shows loading indicator during API calls
- Prevents multiple simultaneous requests
- Provides user feedback

## Performance Considerations

### Pagination
- Loads 10 items per page
- Prevents memory issues with large datasets
- Smooth scrolling experience

### Debouncing
- Prevents excessive API calls
- Optimizes network usage
- Improves user experience

### Caching
- Stores loaded transactions
- Reduces API calls
- Faster subsequent loads

## Testing

### Manual Testing
1. Navigate to Balance History page
2. Verify statistics cards display correctly
3. Test filtering functionality
4. Check pagination works
5. Test pull-to-refresh
6. Verify empty state

### Test Cases
- ✅ Load with data
- ✅ Load with no data
- ✅ Filter by type
- ✅ Load more transactions
- ✅ Refresh data
- ✅ Network error handling
- ✅ Date formatting
- ✅ Amount formatting

## Future Enhancements

### Planned Features
1. **Date Range Filtering**: Filter by specific date ranges
2. **Export Functionality**: Export transactions to PDF/CSV
3. **Search**: Search within transactions
4. **Charts**: Visual charts for spending patterns
5. **Categories**: Transaction categorization
6. **Notifications**: Real-time transaction notifications

### Technical Improvements
1. **Offline Support**: Cache transactions for offline viewing
2. **Real-time Updates**: WebSocket integration
3. **Advanced Filtering**: Multiple filter combinations
4. **Sorting**: Sort by date, amount, type
5. **Bulk Actions**: Select multiple transactions

## Integration Guide

### 1. Add Provider
```dart
// In main.dart
ChangeNotifierProvider(create: (_) => BalanceHistoryProvider()),
```

### 2. Add Navigation
```dart
// In any page
Nav.to(const BalanceHistoryPage());
```

### 3. Add API Endpoint
```php
// Create api_balance_history.php on server
```

### 4. Test Integration
```dart
// Test the complete flow
await provider.fetchBalanceHistory();
```

## Troubleshooting

### Common Issues

1. **No Data Loading**
   - Check API endpoint URL
   - Verify authentication headers
   - Check network connectivity

2. **Filtering Not Working**
   - Verify filter values match API
   - Check provider state management
   - Test with different filter types

3. **Statistics Not Calculating**
   - Verify transaction data structure
   - Check amount parsing
   - Test with sample data

### Debug Steps

1. Check console for error messages
2. Verify API response format
3. Test with mock data
4. Check provider state
5. Verify UI updates

## Conclusion

The Balance History page successfully implements the same design pattern as the Notifications page while adding financial-specific features. It provides a comprehensive view of transaction history with excellent user experience and robust error handling. 