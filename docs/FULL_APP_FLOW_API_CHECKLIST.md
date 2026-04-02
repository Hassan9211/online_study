# Full App Flow and API Checklist

This document expands the existing [`BACKEND_API_HANDOFF.md`](../BACKEND_API_HANDOFF.md) and maps the current Flutter app flow to the backend APIs it needs.

Goal: give backend and frontend a single handoff document so no screen, state dependency, or endpoint requirement is missed while building new APIs.

## 1. App shell and global behavior

- App entry: `lib/main.dart` -> `OnlineStudyApp`
- Initial route: `AppRoutes.launch` (`/`)
- First screen: `SessionGateScreen`
- Global network gate: `NetworkController` wraps the whole app and shows `NoInternetScreen` when connectivity check fails
- Permanent controllers/repositories are registered in `lib/app/app.dart`

### Session gate logic

- If `auth_session.isLoggedIn == true` -> go to `HomeScreen`
- Else if saved credentials exist -> go to `LogInScreen`
- Else -> go to `OnboardingScreen`

### Main logged-in navigation

`HomeScreen` is a 5-tab container:

1. Home dashboard
2. Course catalog
3. Search
4. Messages / notifications
5. Account

## 2. End-to-end app flow

### A. First launch and onboarding

1. App starts on `/`
2. `SessionGateScreen` decides route
3. New users go to onboarding
4. Last onboarding slide shows actions:
   - `Sign Up`
   - `Log In`

### B. Sign up flow

1. User enters email + password + accepts terms
2. App stores those values temporarily in `AuthSessionController`
3. User goes to phone verification flow
4. Step 1: enter phone number
5. Step 2: send OTP
6. Step 3: enter 4-digit OTP
7. Step 4: verify OTP and create account
8. On success:
   - session is saved
   - profile/settings/messages/courses/dashboard are refreshed
   - user goes to `HomeScreen`

### C. Login flow

1. User enters email + password
2. App calls login
3. On success:
   - session is saved
   - profile/settings/messages/courses/dashboard are refreshed
   - user goes to `HomeScreen`

### D. Forgot password flow

1. Enter email
2. Request reset OTP/token
3. Enter OTP/token
4. Enter new password + confirm password
5. Submit reset password
6. Return to login

### E. Home dashboard flow

The Home tab uses:

- profile first name
- dashboard stats
- learning cards
- learning plan
- meetup card

The "Learned today" card opens `MyCoursesScreen`.

### F. My courses flow

1. User opens My Courses from dashboard
2. Screen shows:
   - learned today
   - goal progress
   - my course cards
3. Tapping a course:
   - opens `ProductDesignCourseScreen` for product design
   - opens `CourseDetailScreen` for all other courses

### G. Browse courses flow

`CourseScreen` and `SearchScreen` both depend on the same course catalog data.

User can:

- browse categories
- search by title / teacher / category
- filter by category / duration / price
- open course detail
- for product-design-matched items, app opens the dedicated product design flow instead of generic course detail

### H. Generic course detail flow

1. User opens a course
2. App loads:
   - course detail
   - lesson list
3. User can:
   - favorite the whole course
   - inspect lessons
   - start first playable lesson
4. Locked lessons are blocked if course is not purchased

### I. Generic course player flow

1. User opens a lesson
2. App streams remote `videoUrl`
3. User can:
   - play/pause
   - scrub video
   - switch lessons
   - favorite current lesson
4. Progress is synced periodically and on pause/dispose
5. Dashboard/My Courses progress is refreshed after playback changes

### J. Product Design premium flow

This is a special hybrid flow:

- course metadata and lessons are still local/static
- videos are local assets
- purchase state, payment methods, checkout, pin verification, favorites, and progress sync are backend-aware

Flow:

1. User opens `ProductDesignCourseScreen`
2. First 2 lessons are previewable
3. Remaining lessons are locked until purchase
4. User taps `Buy Now`
5. Payment screen loads saved/available payment methods
6. User chooses card
7. User enters cardholder/card/expiry/cvv
8. App sends checkout request
9. Backend returns payment id
10. User enters 6-digit payment password/pin
11. App verifies payment
12. Purchase record becomes active
13. Success notification is added
14. User returns to player/course and full course becomes unlocked

### K. Messages and notifications flow

`MessageScreen` has 2 tabs:

- message conversations
- notifications

Conversations:

- AI Guest conversation
- normal support/instructor/user conversations

User can:

- open AI Guest chat
- send AI prompt
- open conversation
- load conversation messages
- send message in conversation

Notifications:

- load feed
- mark all seen when notification tab opens
- mark single notification read on tap

### L. Account flow

User can open:

- Favourite videos
- Edit account
- Settings and Privacy
- Help

#### Favourite videos

- shows favorite lessons
- for Product Design lessons:
  - opens player if unlocked
  - falls back to course screen if locked
- for generic courses:
  - opens generic course detail

#### Edit account

User can update:

- full name
- email
- phone
- bio
- avatar/photo upload

On success:

- profile is updated
- auth session email is mirrored
- local notification is added

#### Settings and Privacy

User can update:

- push notifications
- course reminders
- wifi-only downloads
- private profile

User can also:

- change password
- read privacy policy
- read terms and conditions
- log out

#### Change password

1. Enter current password
2. Enter new password
3. Confirm password
4. Submit change
5. App adds a local security notification

#### Help center

User can:

- open AI Guest chat
- submit email support request

#### Support request

User submits:

- topic
- subject
- message
- current account email

On success:

- ticket id is shown in a local notification
- user gets success snackbar

## 3. API checklist by feature

## 3.1 Onboarding

### `GET /onboarding`

- Auth: no
- Used by: onboarding slides
- Minimum response fields per slide:
  - `title`
  - `description`
  - `show_actions`
  - `illustration_key`

Notes:

- If this endpoint fails, app falls back to local onboarding slides

## 3.2 Auth

### `POST /auth/send-otp`

- Auth: no
- Used by: sign up phone step
- Canonical request:
  - `phone`

### `POST /auth/verify-otp`

- Auth: no
- Used by: sign up OTP step
- Canonical request:
  - `phone`
  - `otp`

### `POST /auth/signup`

- Auth: no
- Used by: final registration after OTP verify
- Canonical request:
  - `name`
  - `email`
  - `password`
  - `password_confirmation`
  - `phone`
  - `terms_accepted`
- Minimum response:
  - `user.id`
  - `user.email`
  - `session.accessToken`
  - `session.refreshToken`

Notes:

- If signup succeeds but access token is missing, frontend immediately tries login

### `POST /auth/login`

- Auth: no
- Used by: login
- Canonical request:
  - `email`
  - `password`
- Minimum response:
  - `user.id`
  - `user.email`
  - `session.accessToken`
  - `session.refreshToken`

### `POST /auth/logout`

- Auth: yes
- Used by: logout
- Request body can be empty

### `POST /auth/change-password`

- Auth: yes
- Used by: change password screen
- Canonical request:
  - `current_password`
  - `new_password`
  - `new_password_confirmation`

### `POST /auth/forgot-password`

- Auth: no
- Used by: forgot password email step
- Canonical request:
  - `email`

Fallback:

- frontend also retries `POST /forgot-password` if `/auth/forgot-password` returns 404

### `POST /auth/reset-password`

- Auth: no
- Used by: forgot password reset step
- Canonical request:
  - `email`
  - `token`
  - `password`
  - `password_confirmation`

Fallback:

- frontend also retries `POST /reset-password` if `/auth/reset-password` returns 404

## 3.3 Profile

### `GET /me`

- Auth: yes
- Used by: profile load, account header/avatar
- Minimum response:
  - `id`
  - `name`
  - `email`
  - `phone`
  - `bio`
  - `avatar_url`

### `PUT /me`

- Auth: yes
- Used by: edit account save
- Canonical request:
  - `name`
  - `email`
  - `phone`
  - `bio`
- Minimum response:
  - updated profile fields

Fallback:

- if `PUT /me` returns 404 or 405, frontend retries `POST /me` with `_method=PUT`

### `POST /me/avatar`

- Auth: yes
- Used by: profile photo update
- Content type: multipart/form-data
- Required file field:
  - `avatar`
- Minimum response:
  - `avatar_url` or equivalent image url/path

## 3.4 Settings and privacy

### `GET /me/settings`

- Auth: yes
- Used by: settings screen initial load
- Minimum response:
  - `push_notifications`
  - `course_reminders`
  - `wifi_downloads_only`
  - `private_profile`

### `PUT /me/settings`

- Auth: yes
- Used by: settings toggles
- Canonical request:
  - `push_notifications`
  - `course_reminders`
  - `wifi_downloads_only`
  - `private_profile`
- Minimum response:
  - updated settings object

Fallback:

- if PUT fails without HTTP status, frontend retries `POST /me/settings` with `_method=PUT`

## 3.5 Dashboard and my courses

### `GET /home/dashboard`

- Auth: yes
- Used by: Home dashboard screen
- Minimum response:
  - `learned_today_seconds` or `learned_today_minutes`
  - `daily_goal_minutes`
  - `total_hours`
  - `total_days`
  - `learning_cards[]`
  - `learning_plan[]`
  - `meetup.title`
  - `meetup.subtitle`

### `GET /me/stats`

- Auth: yes
- Used by: optional dashboard stat merge
- Minimum response:
  - any of:
    - `learned_today_seconds`
    - `learned_today_minutes`
    - `daily_goal_minutes`
    - `total_hours`
    - `total_days`

### `GET /me/my-courses`

- Auth: yes
- Used by:
  - My Courses screen
  - Product Design purchase detection
- Minimum response per item:
  - `course.id`
  - `course.title`
  - `completed_lessons`
  - `lessons_count`
  - optionally `purchased_at` / `purchase_id`

Important:

- This single endpoint is currently used for both:
  - rendering enrolled courses
  - deciding whether Product Design is purchased

## 3.6 Catalog, search, and course detail

### `GET /courses`

- Auth: optional or yes, depending on backend design
- Used by: Course tab and Search tab
- Minimum response per course:
  - `id`
  - `title`
  - `teacher.name`
  - `price`
  - `duration_hours`
  - `category.name`
  - `lessons_count`
  - `description`
  - `is_popular`
  - `is_new`
  - `is_favourite`

Important:

- Search/filter happens client-side after catalog load, so this endpoint must return enough fields up front

### `GET /courses/categories`

- Auth: optional or yes
- Used by: Course/Search category chips and filters
- Minimum response:
  - list of strings or list of objects with `name`

### `GET /courses/{courseId}`

- Auth: optional or yes
- Used by: generic course detail
- Minimum response:
  - `id`
  - `title`
  - `teacher.name`
  - `price`
  - `duration_hours`
  - `category.name`
  - `lessons_count`
  - `description`
  - `is_popular`
  - `is_new`
  - `is_favourite`
  - `is_purchased`
  - optionally embedded `lessons[]`

### `GET /courses/{courseId}/lessons`

- Auth: optional or yes
- Used by: fallback if lessons are missing from course detail
- Minimum response per lesson:
  - `id`
  - `title`
  - `duration_label` or `duration_seconds`
  - `description`
  - `video_url`
  - `is_locked`
  - `is_completed`
  - `position_seconds`

## 3.7 Playback progress

### `POST /courses/{courseId}/lessons/{lessonId}/progress`

- Auth: yes
- Used by:
  - generic course player
  - Product Design player
- Request:
  - `position_seconds`
  - `delta_seconds`
  - `duration_seconds`
  - `progress_percent`
  - `completed`

Important:

- Frontend sends this every 5 seconds while watching and again on pause/dispose
- Backend should make this idempotent enough for frequent syncs

## 3.8 Favorites

### `GET /me/favourites`

- Auth: yes
- Used by: Favourite videos screen
- Minimum response per item:
  - `id`
  - `lesson.id`
  - `lesson.title`
  - `lesson.duration_label`
  - `course.id`
  - `course.title`

### `POST /courses/{courseId}/favourite`

- Auth: yes
- Used by: favorite/unfavorite whole course

### `DELETE /courses/{courseId}/favourite`

- Auth: yes
- Used by: unfavorite whole course

### `POST /me/favourites/lessons/{lessonId}`

- Auth: yes
- Used by: favorite lesson

### `DELETE /me/favourites/lessons/{lessonId}`

- Auth: yes
- Used by: unfavorite lesson

## 3.9 Payments and entitlement

### `GET /payments/methods`

- Auth: yes
- Used by: Product Design payment step 1
- Minimum response per method:
  - `id`
  - `label`
  - `masked_number` or `last4`

### `POST /payments/checkout`

- Auth: yes
- Used by: Product Design payment details submit
- Canonical request:
  - `course_id`
  - `payment_method_id`
  - `payment_method_label`
  - `cardholder_name`
  - `card_number`
  - `expiry_month`
  - `expiry_year`
  - `expiry_date`
  - `cvv`
  - `amount`
  - `currency`
- Minimum response:
  - `payment.id`

### `POST /payments/verify-pin`

- Auth: yes
- Used by: Product Design payment password step
- Canonical request:
  - `payment_id`
  - `pin`
- Minimum response:
  - `payment.id`
  - `success` or `paid` or `completed`
  - `paid_at`

Important:

- Successful verification is what unlocks Product Design purchase state

## 3.10 Messages, notifications, and AI Guest

### `GET /messages/conversations`

- Auth: yes
- Used by: message list
- Minimum response per conversation:
  - `id`
  - `name`
  - `status`
  - `preview`
  - `updated_at`
  - `is_online`
  - `is_ai_guest`
  - `show_media_preview`

### `GET /messages/{conversationId}`

- Auth: yes
- Used by: open conversation
- Minimum response:
  - `messages[]`
- Minimum per message:
  - `id`
  - `text`
  - `sender_type`
  - `timestamp`

### `POST /messages/{conversationId}`

- Auth: yes
- Used by: send message in conversation
- Canonical request:
  - `message`
- Minimum response:
  - created message object

### `GET /notifications`

- Auth: yes
- Used by: notifications tab
- Minimum response per item:
  - `id`
  - `title`
  - `message`
  - `type`
  - `timestamp`
  - `is_read`

### `POST /notifications/read`

- Auth: yes
- Used by: mark all read or mark a list read
- Request:
  - empty body for mark all
  - or `ids[]` for batch mark read

### `POST /notifications/{notificationId}/read`

- Auth: yes
- Used by: single notification tap

### `POST /ai/guest-chat`

- Auth: yes, as currently coded
- Used by: AI Guest chat when remote AI guest is enabled
- Canonical request:
  - `message`
  - `context`
  - `instruction`
  - `history[]`
- Minimum response:
  - `reply`

Important:

- `USE_REMOTE_AI_GUEST` is `false` by default, so local AI fallback is currently used unless this flag is enabled at build time

## 3.11 Support

### `POST /support/tickets`

- Auth: optional or yes, depending on backend design
- Used by: support request screen
- Canonical request:
  - `topic`
  - `subject`
  - `message`
  - `email`
- Minimum response:
  - `id`
  - `topic`
  - `subject`
  - `message`
  - `email`
  - `created_at`

## 4. Hidden implementation notes and gaps

These are the things most likely to be missed during backend work.

### 4.1 Product Design is a hybrid feature

- lesson list is local
- lesson videos are local assets
- backend currently influences:
  - purchase state
  - payment methods
  - checkout
  - pin verification
  - my-courses entitlement
  - progress sync
  - favorites

### 4.2 Generic course player does not yet auto-resume from saved position

- backend can already store `position_seconds`
- current player syncs progress but does not seek to saved position on load yet

### 4.3 Some endpoints are defined but not currently consumed by Flutter UI

Defined but unused right now:

- `/auth/refresh-token`
- social auth redirect/callback endpoints
- `/courses/{courseId}/purchase`
- `/payments/{paymentId}`
- `/notifications/unread-count`
- web/app page route endpoint groups

### 4.4 Some UI actions create local notifications, not backend notifications

Local notifications are added after:

- purchase success
- profile update
- profile photo update
- password change
- support request submit
- AI Guest reply

If backend later also emits these, duplication rules should be agreed.

### 4.5 PUT fallback exists for profile/settings

If backend does not accept `PUT`, the app may retry as `POST` with `_method=PUT`.

### 4.6 Forgot/reset fallback exists

If the new auth endpoints return 404, the app retries older paths:

- `/forgot-password`
- `/reset-password`

### 4.7 `/me/my-courses` has high importance

This endpoint currently powers both:

- My Courses UI
- Product Design purchase detection

If it is incomplete, more than one part of the app breaks.

### 4.8 Search and filter are local

The app does not call server-side search endpoints right now.

That means `/courses` should already return:

- title
- teacher
- category
- duration
- price
- flags like `is_popular`, `is_new`

### 4.9 Social login UI is present but not wired

- Google/Facebook buttons exist visually on login screen
- no click behavior is connected yet

## 5. Recommended backend implementation priority

If backend work will happen in phases, this order gives the least breakage:

1. Auth:
   - send OTP
   - verify OTP
   - signup
   - login
   - logout
   - forgot/reset password
   - change password
2. Profile:
   - `/me`
   - `/me/avatar`
3. Dashboard and enrolled courses:
   - `/home/dashboard`
   - `/me/stats`
   - `/me/my-courses`
4. Catalog and detail:
   - `/courses`
   - `/courses/categories`
   - `/courses/{id}`
   - `/courses/{id}/lessons`
5. Payments and entitlement:
   - `/payments/methods`
   - `/payments/checkout`
   - `/payments/verify-pin`
6. Progress and favorites:
   - lesson progress endpoint
   - course favorite endpoints
   - lesson favorite endpoints
7. Messages and notifications:
   - conversations
   - conversation detail/send
   - notifications list/read
   - AI Guest
8. Settings and support:
   - `/me/settings`
   - `/support/tickets`

## 6. Minimum "nothing should break" API set

If the backend team wants the shortest list that keeps the whole visible app usable, this is the minimum set:

- `GET /onboarding`
- `POST /auth/send-otp`
- `POST /auth/verify-otp`
- `POST /auth/signup`
- `POST /auth/login`
- `POST /auth/logout`
- `POST /auth/change-password`
- `POST /auth/forgot-password`
- `POST /auth/reset-password`
- `GET /me`
- `PUT /me`
- `POST /me/avatar`
- `GET /me/settings`
- `PUT /me/settings`
- `GET /home/dashboard`
- `GET /me/stats`
- `GET /me/my-courses`
- `GET /courses`
- `GET /courses/categories`
- `GET /courses/{courseId}`
- `GET /courses/{courseId}/lessons`
- `POST /courses/{courseId}/lessons/{lessonId}/progress`
- `GET /me/favourites`
- `POST /courses/{courseId}/favourite`
- `DELETE /courses/{courseId}/favourite`
- `POST /me/favourites/lessons/{lessonId}`
- `DELETE /me/favourites/lessons/{lessonId}`
- `GET /payments/methods`
- `POST /payments/checkout`
- `POST /payments/verify-pin`
- `GET /messages/conversations`
- `GET /messages/{conversationId}`
- `POST /messages/{conversationId}`
- `GET /notifications`
- `POST /notifications/read`
- `POST /notifications/{notificationId}/read`
- `POST /ai/guest-chat`
- `POST /support/tickets`

## 7. Recommended backend response rule

Frontend parsing is tolerant, but backend should still prefer a clean shape:

```json
{
  "data": {}
}
```

or

```json
{
  "data": []
}
```

For validation errors:

```json
{
  "message": "Validation failed.",
  "errors": {
    "email": ["The email field is required."]
  }
}
```

This matches how the shared API client extracts error messages.
