# O.B AWTO BEZEGleri - Flutter + Supabase

This project now connects to the Supabase project configured in `lib/main.dart` using the public publishable client key. The publishable key is intended for client apps; never add a Supabase secret/service-role key to this project.

## Included in this build
- Supabase initialization
- Live product listing from `public.products`
- Admin sign-in using the Supabase Auth email/password account
- Admin role check against `public.profiles.role`
- Basic admin product creation and active/inactive toggle
- Email/password customer registration with phone metadata
- Existing splash screen and supplied O.B logos
- Android launcher icon generated from `assets/logo_dark.png`
- GitHub Actions workflow to build a release APK

## Supabase setup
The project URL and publishable key are configured in `lib/main.dart`. If you rotate the publishable key, replace it there or pass `--dart-define=SUPABASE_PUBLISHABLE_KEY=...` during build.

Run the SQL in `supabase/migrations/20261102_profile_phone_trigger.sql` in Supabase SQL Editor to ensure new signup phone metadata is copied into `profiles.phone`. The base tables and RLS policies were created separately in the Supabase project.

## Build
```bash
flutter pub get
flutter create --platforms=android --project-name ob_awto_bezegleri .
dart run flutter_launcher_icons
flutter build apk --release
```

Or push the project to a GitHub repository and run the `Build OB Android APK` workflow.

## Important limitations
This is an integration milestone, not a finished production store. Admin product creation and activation are connected. Product image upload, editing/deleting products, member approval UI, verified phone OTP, secure server-side order pricing, checkout, courier workflow, persistent comments, and complete translations still need implementation and testing. Do not collect real customer data until the remaining authentication, privacy, and order flows have been reviewed and tested.
