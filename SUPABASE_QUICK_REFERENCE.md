# Supabase Integration - Quick Reference Card

## 3-Minute Quick Start

### 1. Create Supabase Project (2 minutes)
```
supabase.com → Create Project → Get URL and Key
```

### 2. Update Code (30 seconds)
Edit `lib/main.dart` line 11-14:
```dart
await Supabase.initialize(
  url: 'YOUR_URL',
  anonKey: 'YOUR_KEY',
);
```

### 3. Create Database Tables (30 seconds)
Go to **Supabase SQL Editor**, run the SQL:
```bash
# Copy all SQL from SUPABASE_SETUP.md → "Create Database Tables"
# Run in SQL Editor
```

### 4. Test (30 seconds)
```bash
flutter run
# → Click "Daftar"
# → Enter email, password, business name
# → Click "Masuk"
```

---

## Essential Commands

```bash
# Install dependencies
flutter pub get

# Run app
flutter run

# Check for errors
flutter analyze

# Build
flutter build apk --release
```

---

## Key Files

| File | Purpose | Status |
|------|---------|--------|
| `lib/main.dart` | App initialization | 🟡 UPDATE CREDENTIALS |
| `lib/screens/login_screen.dart` | Login | ✅ READY |
| `lib/screens/signup_screen.dart` | Sign up | ✅ READY |
| `lib/screens/home_screen.dart` | Dashboard | ✅ READY |
| `lib/screens/account_screen.dart` | Account | ✅ READY |
| `lib/services/supabase_service.dart` | Database methods | ✅ READY |

---

## Needed Credentials

Get from Supabase Settings → API:

```
URL: https://[PROJECT-ID].supabase.co
KEY: [ANON-PUBLIC-KEY]
```

---

## SQL to Run

**Paste into Supabase SQL Editor:**

```sql
-- Users
CREATE TABLE users (
  id UUID PRIMARY KEY REFERENCES auth.users,
  email TEXT NOT NULL,
  business_name TEXT NOT NULL,
  name TEXT,
  phone TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Transactions
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

-- Services
CREATE TABLE services (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Notifications
CREATE TABLE notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  is_read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT NOW()
);
```

---

## Enable RLS for Each Table

```sql
-- For users table
CREATE POLICY "Users can access own data"
ON users FOR ALL USING (auth.uid() = id);

-- For transactions, services, notifications
CREATE POLICY "Users can access own data"
ON [TABLE_NAME] FOR ALL USING (auth.uid() = user_id);
```

---

## Test Sign Up Flow

```
1. Click "Daftar"
2. Enter:
   - Nama Bisnis: Test123
   - Email: test@example.com
   - Password: password123 (min 6 chars)
3. Click "Daftar"
✅ Should see: "Pendaftaran berhasil!"
```

---

## Test Login Flow

```
1. Click "Masuk"
2. Enter:
   - Email: test@example.com
   - Password: password123
3. Click "Masuk"
✅ Should see: Dashboard with "Test123"
```

---

## Common Code Examples

### Get Current User
```dart
final user = SupabaseService().getCurrentUser();
```

### Load User Profile
```dart
final profile = await SupabaseService()
  .getUserProfile(user.id);
```

### Add Transaction
```dart
await SupabaseService().addTransaction(
  userId: user.id,
  description: 'Sales',
  amount: 500000,
  type: 'income',
);
```

### Get Transactions
```dart
final transactions = await SupabaseService()
  .getTransactions(user.id);
```

### Logout
```dart
await SupabaseService().signOut();
```

---

## API Methods

```
SupabaseService().signUp()
SupabaseService().signIn()
SupabaseService().signOut()
SupabaseService().getCurrentUser()

SupabaseService().getUserProfile()
SupabaseService().updateUserProfile()

SupabaseService().addTransaction()
SupabaseService().getTransactions()
SupabaseService().deleteTransaction()

SupabaseService().addService()
SupabaseService().getServices()
SupabaseService().deleteService()

SupabaseService().getNotifications()
SupabaseService().markNotificationAsRead()
SupabaseService().deleteNotification()

SupabaseService().getReports()
SupabaseService().getReportSummary()
```

---

## Error Handling

```dart
try {
  await SupabaseService().signIn(...);
} on AuthException catch (e) {
  print('Error: ${e.message}');
} catch (e) {
  print('Error: $e');
}
```

---

## Troubleshooting

| Error | Solution |
|-------|----------|
| "Project URL not set" | Update main.dart with URL |
| "Invalid API key" | Use anon public key, not service key |
| "Permission denied" | Enable RLS and add policies |
| "Table not found" | Run SQL queries in editor |
| "User not found" | Signup first, then login |

---

## Documentation Files

- **SUPABASE_SETUP.md** - Complete setup guide
- **SUPABASE_CHECKLIST.md** - Step-by-step checklist
- **SUPABASE_INTEGRATION_SUMMARY.md** - Full summary
- **SUPABASE_QUICK_REFERENCE.md** - This file

---

## Quick Checklist

- [ ] Create Supabase project
- [ ] Get URL and Key
- [ ] Update main.dart
- [ ] Run SQL in editor
- [ ] Enable RLS on tables
- [ ] flutter pub get
- [ ] flutter run
- [ ] Test signup
- [ ] Test login
- [ ] View dashboard

---

## Support Links

- Supabase: https://supabase.com
- Docs: https://supabase.com/docs
- Flutter Docs: https://supabase.com/docs/reference/flutter
- Discord: https://discord.supabase.com

---

**Status: Production Ready** ✅

Your app is ready for Supabase! Follow the steps above and you'll be up and running in 10 minutes.
