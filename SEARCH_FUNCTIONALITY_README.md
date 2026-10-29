# Search Functionality for Shipments

This document explains the new search functionality that allows users to search shipments by Order ID, recipient name, phone number, and other fields.

## Overview

The search functionality has been implemented with the following features:

- **Real-time Search**: Search as you type with debouncing
- **Multiple Search Fields**: Search by Order ID, recipient name, phone, shipment ID, and barcode
- **Visual Feedback**: Clear indication of search status and results
- **Easy Clear**: One-click to clear search and return to all shipments
- **Responsive UI**: Search results indicator and no-results message

## Search Fields

The search functionality searches across the following fields:

1. **Order ID (Policy Number)**: Primary search field
2. **Recipient Name**: Customer's name
3. **Recipient Phone**: Customer's phone number
4. **Shipment ID**: Internal shipment identifier
5. **Barcode**: Shipment barcode (if available)

## How to Use

### 1. Access Search Bar
The search bar appears in the header when `showSearchFiled` is set to `true`:

```dart
HomeHeader(
  showSearchFiled: true,
  // ... other parameters
)
```

### 2. Search by Order ID
- Type the Order ID (policy number) in the search bar
- Results will show immediately as you type
- Example: `ORD-2024-001`

### 3. Search by Other Fields
- Type recipient name: `John Doe`
- Type phone number: `0779735666`
- Type shipment ID: `12345`
- Type barcode: `BAR123456`

### 4. Clear Search
- Click the clear button (X) in the search bar
- Or click "Clear" in the search results indicator

## Implementation Details

### ShipmentProvider Changes

```dart
class ShipmentProvider with ChangeNotifier {
  // Search state
  String _searchQuery = '';
  List<Shipment> _filteredShipments = [];
  bool _isSearching = false;

  // Search method
  void searchShipments(String query) {
    _searchQuery = query.trim();
    _isSearching = query.isNotEmpty;
    
    if (_isSearching && shipmentsResponse != null) {
      _filteredShipments = shipmentsResponse!.shipments.where((shipment) {
        // Search by multiple fields
        return shipment.policyNum.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               shipment.recipientName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               shipment.recipientPhone.contains(_searchQuery) ||
               shipment.id.toString().contains(_searchQuery) ||
               (shipment.barcode != null && 
                shipment.barcode!.toLowerCase().contains(_searchQuery.toLowerCase()));
      }).toList();
    }
    
    currentPage = 1; // Reset to first page
    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';
    _isSearching = false;
    _filteredShipments = [];
    currentPage = 1;
    notifyListeners();
  }
}
```

### Header Component Changes

```dart
class _HomeHeaderState extends State<HomeHeader> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  Timer? _debounceTimer;

  void _onSearchChanged() {
    // Debounce search to avoid too many calls
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      final shipmentProvider = Provider.of<ShipmentProvider>(context, listen: false);
      shipmentProvider.searchShipments(_searchController.text);
    });
  }

  void _clearSearch() {
    _searchController.clear();
    final shipmentProvider = Provider.of<ShipmentProvider>(context, listen: false);
    shipmentProvider.clearSearch();
  }
}
```

## UI Features

### 1. Search Bar
- **Hint Text**: "Search by Order ID, Name, Phone..."
- **Clear Button**: Appears when text is entered
- **Focus Border**: Primary color when focused
- **Debounced Input**: 500ms delay to avoid excessive searches

### 2. Search Results Indicator
- Shows when search is active
- Displays search query and result count
- Clear button to reset search
- Styled with primary color theme

### 3. No Results Message
- Appears when search returns no results
- Shows search query
- Clear search button
- Search icon for visual clarity

### 4. Loading State
- Shows loading indicator during API calls
- Prevents interaction during loading

## Search Examples

### Search by Order ID
```
Input: "ORD-2024"
Result: All shipments with Order ID containing "ORD-2024"
```

### Search by Recipient Name
```
Input: "John"
Result: All shipments for recipients named "John"
```

### Search by Phone Number
```
Input: "077973"
Result: All shipments with phone numbers containing "077973"
```

### Search by Shipment ID
```
Input: "123"
Result: All shipments with ID containing "123"
```

## Performance Considerations

1. **Debouncing**: 500ms delay prevents excessive API calls
2. **Client-side Filtering**: Search is performed on loaded data
3. **Pagination**: Search results respect pagination settings
4. **Memory Efficient**: Only stores filtered results when needed

## Error Handling

- **Empty Search**: Returns all shipments
- **No Results**: Shows appropriate message
- **API Errors**: Handled gracefully with error dialogs
- **Network Issues**: Fallback to cached data if available

## Future Enhancements

1. **Server-side Search**: Implement API endpoint for large datasets
2. **Advanced Filters**: Date range, status, cost range
3. **Search History**: Remember recent searches
4. **Voice Search**: Speech-to-text for hands-free searching
5. **Barcode Scanner**: Direct barcode scanning integration

## Testing

### Test Cases

1. **Empty Search**: Should show all shipments
2. **Partial Match**: Should find partial matches
3. **Case Insensitive**: Should work regardless of case
4. **Special Characters**: Should handle special characters
5. **Clear Function**: Should reset to all shipments
6. **Pagination**: Should work with search results
7. **Performance**: Should not lag with large datasets

### Manual Testing

1. Open the home page with search enabled
2. Type "ORD" in the search bar
3. Verify results show Order IDs containing "ORD"
4. Clear the search
5. Verify all shipments are shown again
6. Test with different search terms
7. Verify pagination works with search results

## Troubleshooting

### Common Issues

1. **Search not working**: Check if ShipmentProvider is properly initialized
2. **No results showing**: Verify data is loaded and search query is correct
3. **Performance issues**: Check if debouncing is working properly
4. **UI not updating**: Ensure notifyListeners() is called

### Debug Steps

1. Check console for error messages
2. Verify search query is being passed correctly
3. Confirm filtered results are being generated
4. Test with simple search terms first
5. Verify provider state management

## Integration with Existing Code

The search functionality integrates seamlessly with existing code:

- **No Breaking Changes**: Existing functionality remains unchanged
- **Backward Compatible**: Works with existing shipment data
- **Provider Pattern**: Uses existing Provider architecture
- **UI Consistency**: Matches existing design patterns 