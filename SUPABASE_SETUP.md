# Supabase Integration Guide

## Setup Instructions

### 1. Create Supabase Project

1. Go to [supabase.com](https://supabase.com)
2. Click "Start your project"
3. Create a new account or login
4. Click "New Project"
5. Fill in project details:
   - **Name**: antibaw_app (or your preference)
   - **Database Password**: Create a strong password
   - **Region**: Choose closest to your location
6. Click "Create new project" and wait for setup

### 2. Get Your Credentials

Once your project is ready:

1. Go to **Settings** → **API**
2. Copy:
   - **Project URL** (SUPABASE_URL)
   - **anon public** key (SUPABASE_ANON_KEY)
3. Save these values securely

### 3. Configure Your App

1. **Update main.dart** with your credentials:

```dart
await Supabase.initialize(
  url: 'YOUR_SUPABASE_URL',
  anonKey: 'YOUR_ANON_KEY',
);
```

2. **Create .env file** (copy from .env.example):

```bash
cp .env.example .env
```

3. **Edit .env** with your credentials:

```
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here
```

### 4. Create Database Tables

In Supabase Dashboard, go to **SQL Editor** and run these queries:

#### Users Table
```sql
CREATE TABLE users (
  id UUID PRIMARY KEY REFERENCES auth.users,
  email TEXT NOT NULL,
  business_name TEXT NOT NULL,
  name TEXT,
  phone TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);
```

#### Transactions Table
```sql
CREATE TABLE transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  description TEXT NOT NULL,
  amount INTEGER NOT NULL,
  type TEXT NOT NULL, -- 'income' or 'expense'
  date TIMESTAMP DEFAULT NOW(),
  status TEXT DEFAULT 'completed',
  created_at TIMESTAMP DEFAULT NOW()
);
```

#### Services Table
```sql
CREATE TABLE services (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);
```

#### Notifications Table
```sql
CREATE TABLE notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  is_read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT NOW()
);
```

### 5. Enable Authentication

1. Go to **Authentication** → **Providers**
2. Enable **Email** (should be enabled by default)
3. Configure email settings as needed

### 6. Set Row-Level Security (RLS)

For each table, enable RLS:

1. Go to **Database** → **Tables**
2. Select a table
3. Click **Authentication** → **Enable RLS**
4. Add policy:

```sql
CREATE POLICY "Users can only access their own data"
ON users
FOR ALL
USING (
  auth.uid() = id
);
```

Repeat for transactions, services, and notifications tables.

## Install Dependencies

```bash
flutter pub get
```

This installs:
- `supabase_flutter: ^2.0.0` - Supabase client
- `dotenv: ^4.1.0` - Environment variables

## Usage Examples

### Authentication

#### Sign Up
```dart
await SupabaseService().signUp(
  email: 'user@example.com',
  password: 'password123',
  businessName: 'My Business',
);yes

```

#### Sign In
```dart
await SupabaseService().signIn(
  email: 'user@example.com',
  password: 'password123',
);
```

#### Sign Out
```dart
await SupabaseService().signOut();
```

### Transactions

#### Add Transaction
```dart
await SupabaseService().addTransaction(
  userId: 'user-id',
  description: 'Product Sales',
  amount: 500000,
  type: 'income',
);
```

#### Get Transactions
```dart
final transactions = await SupabaseService().getTransactions('user-id');
```

#### Delete Transaction
```dart
await SupabaseService().deleteTransaction('transaction-id');
```

### Services

#### Add Service
```dart
await SupabaseService().addService(
  userId: 'user-id',
  name: 'Service Name',
  description: 'Service description',
);
```

#### Get Services
```dart
final services = await SupabaseService().getServices('user-id');
```

### Notifications

#### Get Notifications
```dart
final notifications = await SupabaseService().getNotifications('user-id');
```

#### Mark as Read
```dart
await SupabaseService().markNotificationAsRead('notification-id');
```

## Real-time Updates (Optional)

To enable real-time updates, modify SupabaseService:

```dart
// Listen to transactions in real-time
Supabase.instance.client
  .from('transactions')
  .on(RealtimeListenTypes.allEvents, (payload) {
    print('Transaction changed: ${payload.newRecord}');
  })
  .subscribe();
```

## Error Handling

All methods throw exceptions. Wrap calls in try-catch:

```dart
try {
  await SupabaseService().signIn(
    email: email,
    password: password,
  );
} on AuthException catch (e) {
  print('Auth error: ${e.message}');
} catch (e) {
  print('Error: $e');
}
```

## Advanced Configuration

### Custom Postgres Functions

Create functions for complex operations:

```sql
CREATE OR REPLACE FUNCTION get_monthly_report(user_id UUID)
RETURNS TABLE (month TEXT, income BIGINT, expense BIGINT) as $$
BEGIN
  RETURN QUERY
  SELECT
    TO_CHAR(date, 'YYYY-MM') as month,
    COALESCE(SUM(CASE WHEN type = 'income' THEN amount ELSE 0 END), 0) as income,
    COALESCE(SUM(CASE WHEN type = 'expense' THEN amount ELSE 0 END), 0) as expense
  FROM transactions
  WHERE transactions.user_id = get_monthly_report.user_id
  GROUP BY TO_CHAR(date, 'YYYY-MM')
  ORDER BY month DESC;
END;
$$ language plpgsql;
```

### Database Triggers

Auto-create notification on transaction:

```sql
CREATE TRIGGER notify_transaction
AFTER INSERT ON transactions
FOR EACH ROW
EXECUTE FUNCTION notify_on_transaction();
```

## Deployment

### Android
```bash
flutter build apk --release
```

### iOS
```bash
flutter build ios --release
```

### Web
```bash
flutter build web --release
```

## Troubleshooting

### Connection Error
- Check SUPABASE_URL and SUPABASE_ANON_KEY
- Verify URL format: `https://your-project-id.supabase.co`
- Check internet connection

### Authentication Error
- Verify email is correct
- Password must be at least 6 characters
- Check if user exists in Supabase

### Row-Level Security Error
- Enable RLS on tables
- Create proper policies
- Verify user has correct permissions

### Real-time Not Working
- Enable real-time for the table
- Check Supabase project plan (real-time requires paid plan features)

## Best Practices

1. **Secure Credentials**: Use environment variables, never commit .env file
2. **Validate Input**: Always validate user input before database operations
3. **Error Handling**: Implement proper error handling and user feedback
4. **RLS Policies**: Always use Row-Level Security for data protection
5. **Backup**: Enable automated backups in Supabase settings
6. **Monitor Usage**: Check "Usage" dashboard to avoid quota limits

## Security Tips

1. Enable JWT expiration
2. Use email verification
3. Set up password reset
4. Implement 2FA (Two-Factor Authentication)
5. Regular security audits
6. Monitor suspicious activities

## Next Steps

1. [x] Install Supabase packages
2. [x] Create authentication screens
3. [x] Set up Supabase service
4. [ ] Create database tables (run SQL queries)
5. [ ] Update screens to use real data
6. [ ] Implement real-time updates
7. [ ] Add error handling UI
8. [ ] Deploy to production

## Resources

- [Supabase Documentation](https://supabase.com/docs)
- [Supabase Flutter Docs](https://supabase.com/docs/reference/flutter)
- [PostgreSQL Documentation](https://www.postgresql.org/docs)
- [Supabase Community](https://github.com/supabase/supabase)

## Support

For issues:
1. Check Supabase status page
2. Review logs in Supabase dashboard
3. Check Flutter console for errors
4. Search Supabase community forum
