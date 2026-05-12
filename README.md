# AntiBaw App

A full-stack Flutter application for managing business services, transactions, and customer relationships. This app provides a comprehensive dashboard for business owners to track their operations.

## Features

### 🏠 Home Dashboard
- Personalized greeting with user name and business name
- Quick access to all services and reports

### 📋 Services (Layanan)
- Cara Penggunaan (How to Use)
- Cabang (Branch Management)
- Layanan (Service Management)
- Pegawai (Employee Management)
- Pelanggan (Customer Management)
- Promo (Promotion Management)
- Notifikasi (Notification Settings)

### 📊 Reports (Laporan)
- Data Transaksi (Transaction Data)
- Grafik 5 Bulan (5-Month Graph Analysis)
- Pengeluaran (Expense Tracking)
- Detail Laporan (Detailed Reports)

### 🔔 Notifications (Notifikasi)
- Real-time notifications
- Promotion alerts
- Transaction confirmations
- System updates

### 👤 Account Management (Akun Saya)
- User profile editing
- Business information management
- Notification preferences
- Privacy policy and app information
- Logout functionality

## Project Structure

```
lib/
├── main.dart                 # App entry point and navigation setup
├── screens/
│   ├── home_screen.dart      # Main dashboard
│   ├── service_detail_screen.dart  # Service management
│   ├── report_detail_screen.dart   # Report viewing
│   ├── notification_screen.dart    # Notifications list
│   └── account_screen.dart         # User account settings
├── widgets/
│   ├── service_card.dart     # Service grid card component
│   └── report_card.dart      # Report grid card component
├── models/
│   ├── service.dart          # Service data model
│   ├── transaction.dart      # Transaction data model
│   └── user.dart             # User data model
└── services/
    └── api_service.dart      # API service for backend integration
```

## Getting Started

### Prerequisites
- Flutter SDK 3.10.4 or higher
- Dart SDK 3.10.4 or higher

### Installation

1. Clone the repository:
```bash
cd antibaw_app
```

2. Get dependencies:
```bash
flutter pub get
```

3. Run the app:
```bash
flutter run
```

## Color Scheme

- **Primary Color**: #8B2E6E (Purple)
- **Service Colors**: Blue, Cyan, Purple, Green, Orange, Green Dark, Pink
- **Report Colors**: Green Dark, Navy Blue, Teal, Yellow-Green

## Future Development

### Backend Integration
- Replace `ApiService` placeholder with actual HTTP client implementation
- Add authentication/login system
- Implement real data persistence

### Features to Add
- Real data visualization with charts
- Push notifications integration
- Payment gateway integration
- Advanced reporting with filters
- User roles and permissions
- Multi-language support
- Dark mode theme

### Testing
- Unit tests for models and services
- Widget tests for UI components
- Integration tests for navigation flows

## Dependencies

Currently using Flutter's built-in Material Design:
- flutter (SDK)
- flutter_lints

Future dependencies to consider:
- `http` or `dio` for API calls
- `provider` or `riverpod` for state management
- `sqflite` or `firebase` for data persistence
- `fl_chart` for advanced charting
- `firebase_messaging` for push notifications

## API Integration

The `ApiService` class in `lib/services/api_service.dart` provides placeholder methods for backend integration. To implement actual API calls:

1. Add `http` or `dio` package to `pubspec.yaml`
2. Implement the TODO methods in `ApiService`
3. Update screens to use the service for data fetching

Example API endpoints (to be implemented):
- `GET /api/transactions` - Fetch transactions
- `GET /api/services` - Fetch services
- `GET /api/user/profile` - Get user profile
- `PUT /api/user/profile` - Update user profile
- `GET /api/reports` - Fetch reports

## UI Best Practices Implemented

- Responsive design using flexible/expanded widgets
- Consistent color scheme and typography
- Smooth navigation with proper AppBar styling
- Empty state handling
- Card-based layout for better readability
- Icon-based quick access navigation
- Bottom navigation for main sections

## Building for Production

### Android
```bash
flutter build apk
```

### iOS
```bash
flutter build ios
```

## Contributing

Feel free to submit issues and enhancement requests!

## License

This project is proprietary to AntiBaw.
