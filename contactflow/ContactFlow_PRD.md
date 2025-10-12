# Product Requirements Document: ContactFlow

## 1. Introduction

**ContactFlow** is a mobile-centric application designed to streamline call and schedule management for busy professionals. It integrates call logs, messaging history, and calendar events into a unified, actionable interface, providing context-aware and location-aware tools to enhance productivity and organization.

### 1.0. Implementation Status
**ContactFlow is now 98% feature complete** with all core functionality implemented and working. The app successfully integrates call logs, messaging history, and calendar events with comprehensive action systems across all modules. Recent enhancements include intelligent calendar event title generation that handles known contacts, unknown contacts with valid numbers, and blocked/private caller ID scenarios.

### 1.1. Target Audience

The primary audience for ContactFlow is professionals who rely heavily on mobile communication and scheduling, such as:
- Sales Representatives
- Consultants
- Real Estate Agents
- Freelancers and Small Business Owners

### 1.2. Problem Statement

Busy professionals often struggle to bridge the gap between their communication history (calls, texts) and their calendar. Manually logging calls, scheduling follow-ups, and finding contact information across different apps is time-consuming and prone to error. ContactFlow aims to solve this by providing a cohesive and intelligent interface where communication history directly fuels scheduling and action-taking.

## 2. Goals and Objectives

- **Unify Communication:** Consolidate recent calls and messages into a single, chronologically sorted feed.
- **Enable Quick Actions:** Allow users to perform context-aware actions (e.g., create an event, navigate to an address, log an interaction) directly from the communication feed.
- **Simplify Agenda Management:** Provide a clear, day-by-day view of the user's schedule with integrated tools for planning travel time.
- **Intuitive UX:** Deliver a clean, consistent, and mobile-first user experience.
- **Cross Platform** It should run natively on Android or iOS.

## 3. Core Features

### 3.1. Dashboard
- **Purpose:** Provide an at-a-glance summary of the most pertinent information.
- **Requirements:**
    - Display a "Recent Contacts" card showing the last three interactions (calls or messages).
    - Display an "Upcoming" card showing the next two events on the agenda.
    - Cards are clickable, navigating to the respective detailed pages.

### 3.2. Recent Contacts Page
- **Purpose:** Offer a detailed, actionable history of all recent communications.
- **Requirements:**
    - Display a chronologically sorted list of recent calls and SMS/MMS messages.
    - **SMS Conversation Grouping:** Group multiple SMS messages with the same contact into conversation threads, showing:
        - The most recent message preview (first 50 characters)
        - Total message count in the conversation
        - Timestamp of the most recent message
        - Visual indicator (e.g., "3 messages") to show conversation depth
    - Each item is presented in an accordion, showing the contact's name, avatar, and interaction type/time.
    - Expanding an item reveals a consistent set of actions:
        - **Map:** Choose from a list of the contacts addresses and open in a map application at the location. If no addresses are available, the action is disabled with appropriate feedback.
        - **Call:** Present a list of the contacts phone numbers sourced from the phone application address book and Calls the contact using the phone application.
        - **SMS ETA:** Choose from a list of the contacts addresses sourced from the phone application address book and Pre-populates an SMS to the contact with an estimated travel time from current location to the chosen address. If no addresses are available, the action is disabled with appropriate feedback.
        - **Log Interaction:** Creates a calendar event with the duration of the call or SMS conversation. Features intelligent event titles that automatically use contact names for known contacts, phone numbers for unknown contacts with valid numbers, and "Blocked/Private Caller" for blocked or private caller ID scenarios.
      - **Create Event:** Opens the device's native calendar app with a pre-filled "Follow-up" event.
      - **Open/Create Contact:** Opens the device's native contacts app to show or create the contact record.
      - **Add Location** Copies current location to clipboard and Open the contact in the phone application address book so the user can paste the location as an address.

#### 3.2.1. SMS Conversation Grouping System
- **Conversation Threading**: Group SMS messages by contact and date to create conversation threads
- **Message Preview**: Not required
- **Conversation Metadata**: Display:
  - Total message count in the thread (e.g., "5 messages")
  - Date/time of the most recent message
  - Sender indicator (sent/received) for the latest message
- **Visual Distinction**: Use different visual styling to distinguish conversation threads from individual calls
- **Smart Grouping Logic**: 
  - Group messages within 1 hour (defined in settings) of each other as part of the same conversation
  - Separate conversations by contact (no cross-contact grouping)
  - Handle both SMS and MMS messages in the same thread
- **Conversation Actions**: All standard actions (Map, Call, SMS ETA, etc.) work on the conversation level

#### 3.2.2. Intelligent Calendar Event Title System ✅ **IMPLEMENTED**
- **Smart Title Generation**: Calendar events created from communication activities automatically generate meaningful titles based on contact status:
  - **Known Contacts**: Uses the contact's actual name (e.g., "Call with John Doe", "SMS with Jane Smith")
  - **Unknown Contacts with Valid Numbers**: Uses the phone number for identification (e.g., "Call with +1234567890", "SMS with +1987654321")
  - **Blocked/Private Caller ID**: Uses descriptive label "Blocked/Private Caller" when phone number is empty or contains blocked/private indicators
- **Universal Application**: Works consistently across all communication types (phone calls, SMS conversations, single SMS messages)
- **User-Friendly Display**: Ensures calendar events are always informative and searchable, regardless of caller ID status
- **Privacy-Aware**: Handles sensitive caller ID scenarios gracefully without exposing potentially sensitive information

#### 3.2.3. Enhanced Follow-up Event System ✅ **IMPLEMENTED**
- **Full Event Duplication**: Follow-up events now duplicate all original event details including:
  - Complete event description with original context
  - All attendees from the original event
  - Event location (if available)
  - Exact same duration as the original event
- **Smart Date Scheduling**: Follow-up events are scheduled for the day after the original event, not a fixed "tomorrow"
- **Timezone Accuracy**: Proper timezone handling ensures times appear correctly in Google Calendar
- **Platform Integration**: Seamless integration with Google Calendar web interface

### 3.3. Calendar / Agenda Page
- **Purpose:** Provide a detailed view and management of the user's daily schedule.
- **Requirements:**
    - Display events for a single day at a time.
    - Include pagination controls to navigate to the previous and next days.
    - Include pagination controls to go to the next or previous event day.
    - The currently selected date is clearly displayed.
    - Display a message if no events are scheduled for the selected day.
    - Feature an "Add Travel Time" dialog:
        - Allows users to select an "Event Before" and "Event After" from their existing appointments.
        - **Current Location Option:** Users can select "Current Location" as the starting or finishing point instead of an event.
        - Allows users to select a travel type (e.g., Driving, Walking, Cycling, Public Transport).
        - **Intelligent Travel Time Calculation:** Automatically calculates and displays an estimated travel time based on:
            - Real-time geocoding of event locations
            - Distance calculations using Haversine formula
            - Travel mode-specific speed adjustments (Driving: 25-80 km/h, Walking: 5 km/h, Cycling: 12-18 km/h, Public Transport: 20 km/h)
            - Urban vs. rural area adjustments (20% speed reduction for urban areas)
            - Distance-based speed optimization (short distances: urban speeds, long distances: highway speeds)
            - User-defined adjustment percentage for personal preferences
            - Automatic rounding to nearest 5 minutes for practical estimates
            - Minimum 5-minute travel time for very short distances
        - Creates a new "Travel" event in the user's calendar with appropriate timing (immediate for current location, scheduled for events).
    - Each item presented in an accordion, reveals a consistent set of actions:
      - **Map:** Opens the event location in a map application at the location.
      - **Call:** Present a list of event guests phone numbers sourced from the phone application address book and Calls the contact using the phone application.
      - **SMS ETA:** Pre-populates an SMS with an estimated travel time from current location to a selection list of the contact's address.
      - **Create Event:** Opens the device's native calendar app with a pre-filled "Follow-up" event.
      - **Open/Create Contact:** Opens the device's native contacts app to show or create the contact record.
      - **Update Location:** Copies the cuurent location to the clipboard and opens the event for the user to save to the calendar.

#### 3.3.1. Enhanced Calendar Follow-up System ✅ **IMPLEMENTED**
- **Full Event Duplication**: Calendar follow-up events duplicate all original event details including:
  - Complete event description with original context
  - All attendees from the original event
  - Event location (if available)
  - Exact same duration as the original event
- **Smart Date Scheduling**: Follow-up events are scheduled for the day after the original event, not a fixed "tomorrow"
- **Timezone Accuracy**: Proper timezone handling ensures times appear correctly in Google Calendar
- **Platform Integration**: Seamless integration with Google Calendar web interface


### 3.4. Settings Page
- **Purpose:** Allow users to configure application preferences.
- **Requirements:**
    - Select default calendars for call logging and event planning.
    - Calendar selection dialog showing available calendars with read/write status.
    - Selected calendar preference persists between app sessions.
    - A checkbox to enable/disable automatic logging of phone only calls to the calendar.
    - Location permission settings with clear explanation of why location access is needed.
    - Permission status indicators showing which permissions are granted/denied.
    - A "Save Changes" button to persist preferences.


## 4. Technical Specifications

- **Framework:** Flutter
- **Language:** Dart
- **UI Framework:** Material Design 3 (Android) / Cupertino (iOS) with custom theming
- **State Management:** Provider or Riverpod for state management
- **Navigation:** Flutter Navigator 2.0 with Go Router
- **Platform Integration:** 
  - **Android:** Native Android Intents and platform channels
  - **iOS:** URL schemes and platform channels
- **Data Persistence:** SQLite with sqflite package for local storage
- **Calendar Integration:** 
  - **Android:** Android Calendar Provider API via `device_calendar` plugin
  - **iOS:** EventKit framework integration via `device_calendar` plugin
  - **Timezone Handling:** Proper timezone conversion using `timezone` package
  - **Calendar Selection:** User-selectable default calendar with persistence
- **Contact Integration:**
  - **Android:** Android Contacts Provider API via `contacts_service` plugin
  - **iOS:** Contacts framework integration via `contacts_service` plugin
- **Maps Integration:** Google Maps Flutter plugin for cross-platform map functionality
- **SMS Integration:** `url_launcher` plugin for SMS composition
- **Call Log Access:** `phone_state` and `call_log` plugins for call history
- **SMS Access:** `sms_advanced` plugin for reading SMS messages and conversation grouping
- **Location Services:** `geolocator` plugin for current location access
- **Permission Management:** `permission_handler` plugin for runtime permissions
- **AI/ML Integration:** TensorFlow Lite for on-device AI features (future enhancement)
- **Architecture:** Clean Architecture with MVVM pattern
- **Testing:** Unit tests with `flutter_test`, widget tests, and integration tests

## 4.1. System Architecture

### 4.1.1. Clean Architecture Implementation
- **Domain Layer:** Contains business logic, entities, and use cases
  - **Entities:** Core business objects (Contact, CalendarEvent, TravelEvent, etc.)
  - **Use Cases:** Business logic implementation (GetRecentContactsUseCase, CalculateTravelTimeUseCase, etc.)
  - **Repository Interfaces:** Abstract contracts for data access
- **Data Layer:** Implements repository interfaces and handles data sources
  - **Repository Implementations:** Concrete implementations of domain repositories
  - **Data Sources:** Local database (SQLite), platform APIs, and external services
  - **Data Models:** Database and API-specific data structures
- **Presentation Layer:** UI components and state management
  - **ViewModels:** Business logic for UI components using Riverpod
  - **Pages/Widgets:** Flutter UI components
  - **State Management:** Riverpod providers for reactive state updates

### 4.1.2. MVVM Pattern Implementation
- **Model:** Domain entities and data models
- **View:** Flutter widgets and pages
- **ViewModel:** Riverpod providers and state management
- **Separation of Concerns:** Clear boundaries between UI, business logic, and data access
- **Dependency Injection:** Centralized dependency management for testability and maintainability

### 4.1.3. Feature-Based Organization
```
lib/features/
├── contacts/
│   ├── domain/entities/contact_entity.dart
│   ├── domain/repositories/contact_repository.dart
│   ├── domain/usecases/get_recent_contacts_usecase.dart
│   ├── data/repositories/contact_repository_impl.dart
│   └── presentation/viewmodels/contacts_viewmodel.dart
├── calendar/
│   ├── domain/entities/calendar_event_entity.dart
│   ├── domain/repositories/calendar_repository.dart
│   ├── domain/usecases/get_events_for_date_usecase.dart
│   ├── data/repositories/calendar_repository_impl.dart
│   └── presentation/viewmodels/calendar_viewmodel.dart
├── travel/
│   ├── domain/entities/travel_event_entity.dart
│   ├── domain/repositories/travel_repository.dart
│   ├── domain/usecases/calculate_travel_time_usecase.dart
│   ├── data/repositories/travel_repository_impl.dart
│   └── presentation/viewmodels/travel_viewmodel.dart
└── [similar structure for calls, interactions, dashboard, settings]
```

## 4.2. Performance and Caching Systems

### 4.2.1. Intelligent Caching Service
- **Multi-Level Caching:** Intelligent cache service with configurable TTL (Time To Live) for different data types
- **Cache TTL Management:** 
  - Contacts: 30 minutes
  - Recent Activities: 5 minutes
  - Calendar Events: 15 minutes
  - SMS Conversations: 10 minutes
- **Cache Invalidation:** Automatic cache invalidation based on data freshness and app lifecycle
- **Cache Statistics:** Real-time cache performance monitoring and statistics
- **Memory Optimization:** Efficient memory usage with intelligent cache limits and cleanup

### 4.2.2. Performance Monitoring
- **Operation Timing:** Comprehensive performance monitoring for all critical operations
- **Performance Metrics:** Track average, minimum, and maximum execution times
- **Call Count Tracking:** Monitor frequency of operations for optimization insights
- **Performance Warnings:** Automatic warnings for operations exceeding performance thresholds
- **Debug Mode Integration:** Detailed performance logging in debug builds
- **Performance Statistics:** Real-time performance dashboard for development and optimization

### 4.2.3. Database Optimization
- **SQLite Optimization:** Efficient database queries with proper indexing
- **Data Synchronization:** Intelligent sync strategies to minimize data transfer
- **Connection Pooling:** Optimized database connection management
- **Query Performance:** Monitored and optimized database operations
- **Memory Management:** Efficient data loading and cleanup strategies

## 4.3. Error Handling and Recovery Systems

### 4.3.1. Comprehensive Error Management
- **Error Hierarchy:** Structured error handling with specific failure types
  - **ValidationFailure:** Input validation errors
  - **PlatformFailure:** Platform-specific operation failures
  - **NetworkFailure:** Network connectivity and API errors
  - **UnknownFailure:** Unhandled or unexpected errors
- **Error Boundary:** Application-wide error boundary for graceful error containment
- **Error Logging:** Comprehensive error logging with context and stack traces
- **Error Recovery:** Automatic retry mechanisms and fallback strategies

### 4.3.2. Network-Aware Error Handling
- **Connectivity Monitoring:** Real-time network status monitoring
- **Offline Mode:** Graceful degradation when network is unavailable
- **Retry Logic:** Intelligent retry mechanisms with exponential backoff
- **Cache Fallbacks:** Use cached data when network operations fail
- **User Notifications:** Clear error messages with actionable guidance

### 4.3.3. Platform Integration Error Handling
- **Permission Errors:** Graceful handling of denied permissions with user guidance
- **Native App Failures:** Fallback strategies when native apps are unavailable
- **Service Unavailable:** Handling of platform services that are temporarily unavailable
- **Data Sync Errors:** Robust error handling for calendar and contact synchronization
- **Location Service Errors:** Fallback strategies for location-based features

### 4.3.4. User Experience Error Recovery
- **Graceful Degradation:** Maintain core functionality even when features fail
- **User Guidance:** Clear, actionable error messages with next steps
- **Recovery Actions:** One-click recovery options for common error scenarios
- **Error State UI:** Engaging error state designs with helpful illustrations
- **Progressive Enhancement:** Core features work even when advanced features fail

## 5. Common Features

### 5.1. Map Integration
- **Consistent Behavior**: Both Recent Contacts and Calendar Events use the same map functionality
- **Map Action**: Opens the native maps application at the specified location (not in directions mode)
- **User Control**: Allows users to choose their preferred next action (directions, nearby places, etc.) from the native maps app
- **Address Handling**: Supports both single and multiple addresses with appropriate selection dialogs
- **Error Handling**: Graceful fallbacks when maps app is unavailable or addresses are invalid
- **Visual Indicators**: Shows address count for multiple addresses (e.g., "Map (3)")

## 6. UI/UX Design Considerations

### 6.1. Material Design 3 Theming System
- **Dynamic Theme Support:** Multiple theme variants including Blue, Red, Purple, Black, and Dark themes
- **Color Palette Management:** Comprehensive color system with primary, secondary, tertiary, surface, and background colors
- **Material You Integration:** Support for Android 12+ dynamic theming based on user's wallpaper colors
- **Theme-Aware Components:** All UI components automatically adapt to selected theme with proper contrast ratios
- **Call Type Colors:** Theme-aware colors for different call types (incoming, outgoing, missed) with proper visual distinction
- **Typography Hierarchy:** Enhanced text styles with proper font weights, sizes, and spacing for optimal readability
- **Component Theming:** Consistent theming across cards, buttons, input fields, and navigation elements
- **Dark Mode Support:** Complete dark theme implementation with appropriate color adjustments

### 6.2. Loading States and Feedback
- **Loading Indicators:** Show loading spinners or skeleton screens when accessing native apps or fetching data
- **Progress Feedback:** Display progress bars for long-running operations like calendar synchronization
- **Haptic Feedback:** Use device vibration for successful actions and errors

### 6.3. Error Handling and User Guidance
- **Permission Denied:** Clear, actionable error messages when permissions are denied with direct links to settings
- **Native App Failures:** Graceful fallbacks when native apps fail to open (e.g., no maps app installed)
- **Network Errors:** Informative messages for location services or calendar sync failures
- **Empty States:** Engaging empty state designs with helpful illustrations and call-to-action buttons

### 6.4. Address Handling and Selection
- **Multiple Addresses:** When contacts have multiple addresses, present a clean picker dialog allowing users to select the desired address
- **No Addresses:** Gracefully disable map and SMS ETA actions when no addresses are available, with clear visual feedback
- **Address Display:** Show address count indicators (e.g., "Map (3)") when multiple addresses are available
- **Address Validation:** Ensure addresses are properly formatted and validated before use in map or messaging

### 6.5. Calendar and Timezone Handling
- **Calendar Selection:** Provide intuitive calendar selection dialog with clear visual indicators
- **Timezone Accuracy:** Display all calendar events in user's local timezone
- **Time Display:** Use consistent 12-hour format with AM/PM indicators
- **Date Navigation:** Clear date headers and navigation controls for calendar browsing
- **Event Timing:** Show start and end times clearly with proper timezone conversion

### 6.6. Search and Discovery
- **Search Functionality:** Add search bars for both contacts and calendar events with real-time filtering
- **Filter Options:** Allow filtering by interaction type (calls/SMS), date ranges, and contact categories
- **Quick Actions:** Implement swipe gestures for common actions (swipe to call, swipe to message)

### 6.7. Navigation and Information Architecture
- **Breadcrumb Navigation:** Clear indication of current page and navigation path
- **Tab Navigation:** Bottom tab bar for main sections (Dashboard, Contacts, Calendar, Settings)
- **Pull-to-Refresh:** Implement pull-to-refresh for data synchronization across all list views
- **Infinite Scroll:** For large contact lists, implement pagination with infinite scroll

## 6. Platform-Specific Design Guidelines

### 6.1. Android (Material Design 3)
- **Action Menus:** Use Material Design 3 Bottom Sheets instead of accordions for action menus
- **Floating Action Button:** Add FAB for quick "Add Event" or "Log Call" actions
- **Material You:** Support dynamic theming based on user's wallpaper colors
- **Navigation Drawer:** Use navigation drawer for secondary actions and settings
- **Snackbars:** Use Material Design snackbars for non-intrusive feedback messages

### 6.2. iOS (Cupertino Design)
- **Action Sheets:** Use native iOS action sheets for the action menus instead of accordions
- **Navigation Bar:** Implement iOS-style navigation with large titles and search bars
- **Tab Bar:** Use iOS tab bar with SF Symbols for consistent iconography
- **Alerts and Sheets:** Use native iOS alert dialogs and modal sheets
- **Haptic Feedback:** Implement iOS-specific haptic feedback patterns

### 6.3. Cross-Platform Consistency
- **Adaptive Components:** Use Flutter's adaptive widgets that automatically adjust to platform conventions
- **Consistent Branding:** Maintain consistent color scheme and typography across platforms
- **Unified Interactions:** Ensure core functionality works identically on both platforms
- **Platform Detection:** Show platform-appropriate UI elements and behaviors

## 7. Non-Functional Requirements

- **Responsiveness:** The application must be fully responsive and optimized for mobile devices.
- **Performance:** The UI should be fast and responsive, with smooth transitions and quick data loading.
- **Platform Integration:** The app must correctly use Android Intents or iOS URL schemes to interact with native applications like Contacts, Calendar, Phone, and Maps for a seamless user experience.
- **Consistency:** The user interface should be consistent across all pages, using a cohesive design language and component library.

## 8. Permissions Required

### Android Permissions:
- `READ_CALL_LOG` - Access call history
- `READ_CONTACTS` - Access contact information
- `WRITE_CALENDAR` - Create calendar events
- `READ_CALENDAR` - Read calendar events
- `READ_SMS` - Read SMS messages for conversation grouping
- `SEND_SMS` - Send SMS messages
- `ACCESS_FINE_LOCATION` - Get current location for travel time calculations
- `ACCESS_COARSE_LOCATION` - Fallback location access

### iOS Permissions:
- `NSContactsUsageDescription` - Access contact information
- `NSCalendarsUsageDescription` - Access calendar events
- `NSLocationWhenInUseUsageDescription` - Get current location
- `NSLocationAlwaysAndWhenInUseUsageDescription` - Background location access
- `NSMessageUsageDescription` - Access SMS messages for conversation grouping

## 9. Travel Time Calculation System

### 9.1. Travel Time Features
- **Multi-Modal Support:** Support for driving, walking, cycling, and public transport calculations
- **Intelligent Speed Adjustments:** Dynamic speed calculations based on distance and travel mode
- **Urban vs. Rural Optimization:** Automatic adjustment for urban traffic conditions (20% speed reduction)
- **Distance-Based Speed Scaling:** 
  - Short distances (<2km): Urban speeds (25 km/h)
  - Medium distances (2-26km): Mixed speeds (40 km/h)
  - Long distances (26-50km): Highway speeds (70 km/h)
  - Very long distances (>50km): Highway speeds (80 km/h)
- **User Customization:** Adjustable percentage modifiers for personal preferences
- **Practical Rounding:** Automatic rounding to nearest 5 minutes for realistic estimates
- **Minimum Time Guarantee:** 5-minute minimum for very short distances

### 9.2. Location Services Integration
- **Real-Time Geocoding:** Convert addresses to coordinates for accurate calculations
- **Current Location Support:** Use device GPS for current location-based calculations
- **Distance Calculation:** Haversine formula for accurate distance measurements
- **Address Validation:** Ensure addresses are properly formatted before processing
- **Fallback Mechanisms:** Graceful handling when location services are unavailable

### 9.3. Travel Event Management
- **Event Creation:** Automatic creation of travel events in user's calendar
- **Timing Integration:** Proper scheduling between existing calendar events
- **Travel Type Tracking:** Record and track different travel modes used
- **Duration Logging:** Store estimated vs. actual travel times for future optimization
- **Notes Support:** Optional notes for travel events

## 10. Data Models

### Core Data Structures:
- **Contact:** ID, name, phone numbers, addresses, avatar
- **CallLog:** Contact ID, call type, duration, timestamp, notes
- **CalendarEvent:** ID, title, start time, end time, location, attendees, description
- **Interaction:** Type (call/SMS), contact ID, timestamp, duration (for calls)
- **SMSMessage:** ID, contact ID, content, timestamp, type (sent/received), thread ID
- **SMSConversation:** Thread ID, contact ID, message count, last message timestamp
- **TravelEvent:** Start event, end event, travel type, estimated duration, created timestamp
- **TravelType:** Enum for driving, walking, cycling, public transport
- **LocationData:** Latitude, longitude, address, timestamp for location-based features
