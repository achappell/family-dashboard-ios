# Family Hub - iOS App

A native iOS application designed to keep your family organized on the go. Built entirely with modern Swift and SwiftUI, it interfaces seamlessly with Supabase for real-time data sync and Google APIs for calendar management.

## Features

- **Google Sign-In:** Secure authentication using Supabase OAuth, automatically syncing your Google profile name.
- **Daily Calendar View:** A focused, day-by-day calendar view. Events that contain a family member's name are automatically highlighted in their assigned color.
- **Real-time Chore Dashboard:** 
  - View tasks assigned to you or your children.
  - Support for Due Dates and Overdue highlighting.
  - Support for Recurring tasks (Daily, Weekly on specific days, Monthly).
  - Checking off a recurring task completes it for the current day only.
  - UI updates instantly when a task is checked off on another device (like the Electron desktop app) via Supabase Realtime.
- **Family Management:** Add children, assign them theme colors, and manage your selected Google Calendars directly from the Settings tab.

## Architecture

- **UI Framework:** SwiftUI
- **Pattern:** MVVM (Model-View-ViewModel) using the `@Observable` macro.
- **Concurrency:** Modern Swift `async/await` and `@MainActor` for safe UI updates.
- **Networking:** `supabase-swift` for database/auth and `URLSession` for direct Google Calendar API calls.

## Setup & Configuration

1. **Requirements:**
   - Xcode 15 or later.
   - iOS 17.0+ deployment target.

2. **Dependencies:**
   - The project uses Swift Package Manager (SPM). The primary dependency is `supabase-swift` (`https://github.com/supabase-community/supabase-swift`). This should resolve automatically when opening the project in Xcode.

3. **Supabase Configuration:**
   - Ensure the `Secrets.plist` file is present in the `Family Hub` group directory.
   - It must contain your `SUPABASE_URL` and `SUPABASE_ANON_KEY`.
   - Ensure your Supabase project has Google Auth configured with the correct client IDs and that the URL scheme `io.supabase.familyhub://` is whitelisted as a redirect URI in your Supabase Auth settings.

4. **Running the App:**
   - Open `Family Hub.xcodeproj` in Xcode.
   - Select your target simulator or physical device.
   - Hit **Run** (Cmd+R).
