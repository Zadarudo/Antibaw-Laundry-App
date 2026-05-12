# AntiBaw App - Implementation Guide

## Overview

This is a complete full-stack Flutter dashboard application designed for business owners and merchants to manage their operations. The app includes service management, transaction tracking, notifications, and account management.

## Architecture Overview

### Project Structure
```
lib/
├── main.dart                    # App entry point
├── constants/
│   └── app_theme.dart          # Theme, colors, and constants
├── models/
│   ├── service.dart            # Service model
│   ├── transaction.dart        # Transaction model
│   └── user.dart               # User model
├── screens/
│   ├── home_screen.dart        # Main dashboard
│   ├── service_detail_screen.dart
│   ├── report_detail_screen.dart
│   ├── notification_screen.dart
│   └── account_screen.dart
├── services/
│   └── api_service.dart        # API service (placeholder)
└── widgets/
    ├── service_card.dart       # Reusable service card
    └── report_card.dart        # Reusable report card
```

## Setup Instructions

### 1. Clone and Install
```bash
cd antibaw_app
flutter pub get
```

### 2. Run the App
```bash
flutter run
```

### 3. Build for Production
- **Android**: `flutter build apk`
- **iOS**: `flutter build ios`
- **Web**: `flutter build web`

## Features Breakdown

### Home Screen (Dashboard)
- **Header**: Personalized greeting with user and business name
- **Services Section**: 7 interactive service cards for different operations
- **Reports Section**: 4 cards for various reports
- **Navigation**: Bottom navigation bar for main sections

### Service Detail Screen
- Add new service entries
- Display list of services
- Delete functionality
- Date tracking

### Report Detail Screen
- Date range filtering
- Transaction display with amounts
- Total calculation
- Formatted currency display

### Notification Screen
- List of notifications
- Mark as read functionality
- Delete notifications
- Different notification types (promotions, updates, alerts)

### Account Screen
- User profile editing
- Business information management
- Settings (notifications toggle)
- About and Privacy Policy links
- Logout functionality

## Backend Integration

### Current State
The app is currently a frontend-only application with mock data. The `ApiService` class contains placeholder methods for backend integration.

### To Add Backend:

1. **Add HTTP Package**
```bash
flutter pub add http
# or
flutter pub add dio
```

2. **Implement API Calls**
Replace TODO methods in `lib/services/api_service.dart`:

```dart
import 'package:http/http.dart' as http;

Future<List<Transaction>> getTransactions() async {
  final response = await http.get(
    Uri.parse('$baseUrl/api/transactions'),
    headers: {'Authorization': 'Bearer $token'},
  );
  
  if (response.statusCode == 200) {
    final List<dynamic> data = json.decode(response.body);
    return data.map((json) => Transaction.fromMap(json)).toList();
  } else {
    throw Exception('Failed to load transactions');
  }
}
```

3. **State Management (Optional)**
Consider adding state management for better data handling:
- **Provider**: `flutter pub add provider`
- **Riverpod**: `flutter pub add riverpod flutter_riverpod`
- **GetX**: `flutter pub add get`

Example with Provider:
```dart
class TransactionProvider extends ChangeNotifier {
  List<Transaction> _transactions = [];
  
  Future<void> loadTransactions() async {
    _transactions = await ApiService().getTransactions();
    notifyListeners();
  }
}
```

## Customization Guide

### Changing Colors
Edit `lib/constants/app_theme.dart`:
```dart
static const Color primaryColor = Color(0xFF8B2E6E); // Change here
```

### Adding New Services
1. Update `home_screen.dart` GridView
2. Add new icon and color
3. Create corresponding detail screen

### Modifying Layouts
All screens use standard Flutter widgets:
- `Scaffold`: Basic structure
- `Column/Row`: Layout positioning
- `ListView/GridView`: List displays
- `Card`: Content containers

## Common Tasks

### Add a New Page
```dart
class NewPage extends StatefulWidget {
  const NewPage({super.key});

  @override
  State<NewPage> createState() => _NewPageState();
}

class _NewPageState extends State<NewPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Page')),
      body: Center(child: Container()),
    );
  }
}
```

### Add Navigation
```dart
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => const NewPage()),
);
```

### Format Currency
```dart
String formatCurrency(int amount) {
  return 'Rp ${amount.toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (m) => '${m[1]}.'
  )}';
}
```

## Testing

### Run Tests
```bash
flutter test
```

### Widget Testing Example
```dart
void main() {
  testWidgets('Home screen displays correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const MainApp());
    expect(find.text('Hi namakeren'), findsOneWidget);
  });
}
```

## Performance Optimization

1. **Image Caching**: Use `Image.network()` with caching
2. **List Performance**: Use `ListView.builder()` for large lists
3. **Lazy Loading**: Load data as user scrolls
4. **Code Splitting**: Separate concerns into different files

## Known Limitations

1. **No Authentication**: Currently no login/logout persistence
2. **No Real Data**: All data is mock/hardcoded
3. **No Database**: No local persistence
4. **No Offline Support**: Requires internet connection for future API calls

## Future Enhancements

### Phase 1: Core Backend
- Authentication system (Firebase or custom)
- Real database integration
- API endpoint implementation

### Phase 2: Advanced Features
- Real-time notifications (Firebase Cloud Messaging)
- Data visualization with charts (FL Chart)
- Export reports (PDF generation)
- Multi-language support

### Phase 3: Enterprise Features
- Role-based access control
- Advanced analytics
- Team collaboration
- Audit logs

## Troubleshooting

### Build Errors
```bash
flutter clean
flutter pub get
flutter run
```

### Widget Not Showing
- Check `SafeArea` wrapper
- Verify `Scaffold` is used
- Check `shrinkWrap: true` for nested scrollables

### Performance Issues
- Use `.builder()` for lists with many items
- Avoid rebuilding entire widget tree
- Use `const` constructors where possible

## Resources

- [Flutter Documentation](https://flutter.dev/docs)
- [Dart Language Guide](https://dart.dev/guides)
- [Material Design](https://material.io/design)
- [Firebase Integration](https://firebase.flutter.dev/)

## Support

For issues or feature requests, please document them with:
- What you were trying to do
- What happened
- What you expected
- Screenshots/logs
