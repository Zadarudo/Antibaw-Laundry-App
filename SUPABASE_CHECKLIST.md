# Supabase Integration - Quick Start Checklist

## Current Implementation Status

✅ **Already Integrated:**
- [x] Supabase dependencies added to pubspec.yaml
- [x] SupabaseService class created with all database methods
- [x] LoginScreen created with email/password authentication
- [x] SignupScreen created with business registration
- [x] Authentication state management in main.dart
- [x] Automatic user profile creation on signup
- [x] Logout functionality integrated
- [x] HomeScreen updated to load user data from Supabase

## Next Steps

### Step 1: Set Up Supabase Project (Required)

1. Go to [supabase.com](https://supabase.com)
2. Create new project (follow SUPABASE_SETUP.md for detailed guide)
3. Get your **SUPABASE_URL** and **SUPABASE_ANON_KEY**
4. Update in `lib/main.dart` lines 12-13

### Step 2: Create Database Tables (Required)

Run these SQL queries in Supabase SQL Editor:

```sql
-- Users table
CREATE TABLE users (
  id UUID PRIMARY KEY REFERENCES auth.users,
  email TEXT NOT NULL,
  business_name TEXT NOT NULL,
  name TEXT,
  phone TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Transactions table
CREATE TABLE transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  description TEXT NOT NULL,
  amount INTEGER NOT NULL,
  type TEXT NOT NULL,
  date TIMESTAMP DEFAULT NOW(),
  status TEXT DEFAULT 'completed',
  created_at TIMESTAMP DEFAULT NOW()
);

-- Services table
CREATE TABLE services (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Notifications table
CREATE TABLE notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  is_read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT NOW()
);
```

### Step 3: Enable Row-Level Security (RLS)

For each table in Supabase:

1. Go to **Database** → Click table
2. Click **Authentication** → **Enable RLS**
3. Add policy for users table:

```sql
CREATE POLICY "Users can access own data"
ON users FOR ALL USING (auth.uid() = id);
```

4. Add policy for other tables:

```sql
CREATE POLICY "Users can access own transactions"
ON transactions FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can access own services"
ON services FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can access own notifications"
ON notifications FOR ALL USING (auth.uid() = user_id);
```

### Step 4: Update Credentials in Code

Edit `lib/main.dart` (lines 12-13):

```dart
await Supabase.initialize(
  url: 'YOUR_ACTUAL_SUPABASE_URL',
  anonKey: 'YOUR_ACTUAL_ANON_KEY',
);
```

### Step 5: Install Dependencies

```bash
flutter pub get
```

### Step 6: Test Authentication

```bash
flutter run
```

1. Click "Daftar" to create account
2. Enter email, password, business name
3. Should see "Pendaftaran berhasil!" message
4. Click "Masuk" to login
5. Should see home screen with your business name

## Feature Implementation Guide

### Real-time Data Loading

Update screens to load data from Supabase:

#### Service Detail Screen
```dart
class _ServiceDetailScreenState extends State<ServiceDetailScreen> {
  List<Map<String, dynamic>> _services = [];
  
  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  Future<void> _loadServices() async {
    final user = SupabaseService().getCurrentUser();
    if (user != null) {
      final services = await SupabaseService().getServices(user.id);
      setState(() => _services = services);
    }
  }

  Future<void> _addService(String name) async {
    final user = SupabaseService().getCurrentUser();
    if (user != null) {
      await SupabaseService().addService(
        userId: user.id,
        name: name,
        description: '',
      );
      _loadServices();
    }
  }
}
```

#### Transaction/Report Screen
```dart
Future<void> _loadTransactions() async {
  final user = SupabaseService().getCurrentUser();
  if (user != null) {
    final transactions = await SupabaseService()
      .getTransactions(user.id);
    setState(() => _transactionList = transactions);
  }
}
```

### Real-time Updates (Advanced)

For live data updates without refreshing:

```dart
void _listenToTransactions(String userId) {
  Supabase.instance.client
    .from('transactions')
    .on(RealtimeListenTypes.allEvents, 
      (payload) {
        if (payload['new_record']['user_id'] == userId) {
          _loadTransactions();
        }
      })
    .subscribe();
}
```

## Screens Ready for Integration

| Screen | Status | Implementation |
|--------|--------|-----------------|
| LoginScreen | ✅ Complete | Email/password auth |
| SignupScreen | ✅ Complete | New user registration |
| HomeScreen | 🟡 Partial | Loads user name/business |
| ServiceDetailScreen | ⏳ Ready | Ready for data loading |
| ReportDetailScreen | ⏳ Ready | Ready for data loading |
| NotificationScreen | ⏳ Ready | Ready for data loading |
| AccountScreen | ✅ Complete | Logout integrated |

## Available API Methods

### Authentication
- `signUp(email, password, businessName)` - Create new account
- `signIn(email, password)` - Login user
- `signOut()` - Logout user
- `getCurrentUser()` - Get current user
- `authStateChanges()` - Listen to auth changes

### User Profile
- `createUserProfile(userId, email, businessName)` - Create profile
- `getUserProfile(userId)` - Fetch user profile
- `updateUserProfile(userId, data)` - Update profile

### Transactions
- `getTransactions(userId)` - Fetch all transactions
- `addTransaction(userId, description, amount, type)` - Add transaction
- `deleteTransaction(transactionId)` - Delete transaction

### Services
- `getServices(userId)` - Fetch all services
- `addService(userId, name, description)` - Add service
- `deleteService(serviceId)` - Delete service

### Notifications
- `getNotifications(userId)` - Fetch notifications
- `markNotificationAsRead(notificationId)` - Mark as read
- `deleteNotification(notificationId)` - Delete notification

### Reports
- `getReports(userId, startDate, endDate)` - Get filtered transactions
- `getReportSummary(userId)` - Get income/expense totals

## Testing Checklist

- [ ] Signup works
- [ ] Login works with created account
- [ ] User data persists after logout/login
- [ ] Can add transactions
- [ ] Can view transactions
- [ ] Can add services
- [ ] Can delete services
- [ ] Can view notifications
- [ ] Can mark notifications as read
- [ ] Logout clears session
- [ ] New login works

## Common Issues & Solutions

### Issue: "No Session" Error
**Solution**: Make sure user is signed in before accessing data

### Issue: RLS Violation Error
**Solution**: Enable Row-Level Security policies on all tables

### Issue: 404 Not Found
**Solution**: Verify table names match exactly (lowercase, no spaces)

### Issue: Real-time Not Working
**Solution**: Enable real-time in table settings, may require paid plan

### Issue: User Data Not Loading
**Solution**: Check if user profile was created, verify user_id matches

## Next Development Tasks

1. **Implement real data loading** in all screens
2. **Add error handling** UI for network failures
3. **Implement real-time updates** for notifications
4. **Add data validation** before database insertion
5. **Create backup/export** functionality
6. **Add search functionality** for transactions
7. **Implement filters** for reports
8. **Add pagination** for large datasets
9. **Create admin dashboard** (optional)
10. **Set up push notifications** with FCM

## Security Reminders

⚠️ **DO NOT**:
- Commit .env file or credentials to git
- Use service role key in frontend (only anon key)
- Trust client-side validation (validate on backend too)
- Store sensitive data in Auth metadata

✅ **DO**:
- Use environment variables for credentials
- Enable RLS on all tables
- Validate input on both client and server
- Use HTTPS only
- Implement rate limiting
- Monitor suspicious activities
- Regular security audits

## Testing with Mock Data

Before real backend:

1. Add test data in Supabase dashboard
2. Test login with test data
3. Verify data loads correctly
4. Test CRUD operations
5. Check error handling

## Resources

- [Supabase Flutter Docs](https://supabase.com/docs/reference/flutter)
- [Supabase API Docs](https://supabase.com/docs/reference/api)
- [PostgreSQL Docs](https://www.postgresql.org/docs)
- [Row-Level Security Guide](https://supabase.com/docs/guides/auth/row-level-security)

## Support Contacts

- Supabase Docs: https://supabase.com/docs
- Supabase Discord: https://discord.supabase.com
- GitHub Issues: https://github.com/supabase/supabase/issues
