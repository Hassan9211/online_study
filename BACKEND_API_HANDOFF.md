# Backend API Handoff

This app is now structured so current local repositories can be replaced by remote/API repositories without changing the UI flow.

## Core modules

### Auth
- Frontend session model: `AuthSessionRecord`
- Current local repository: `LocalAuthSessionRepository`
- Expected backend ownership:
  - sign up
  - OTP send/verify
  - login
  - logout
  - refresh token
  - change password
- Important stored fields:
  - `userId`
  - `email`
  - `accessToken`
  - `refreshToken`
  - `isLoggedIn`

### Profile
- Frontend profile model: `ProfileRecord`
- Current local repository: `LocalProfileRepository`
- Expected backend ownership:
  - fetch profile
  - update profile
  - upload avatar
- Important stored fields:
  - `id`
  - `name`
  - `email`
  - `phone`
  - `bio`
  - `avatarUrl`

### Messages and Notifications
- Frontend state model: `MessageCenterState`
- Current local repository: `LocalMessageCenterRepository`
- Expected backend ownership:
  - conversations list
  - AI Guest replies
  - notifications feed
  - mark notifications read
- Important stored fields:
  - conversation:
    - `id`
    - `name`
    - `status`
    - `preview`
    - `timestamp`
  - message:
    - `id`
    - `text`
    - `senderType`
    - `timestamp`
  - notification:
    - `id`
    - `title`
    - `message`
    - `type`
    - `timestamp`
    - `isRead`

### Course Purchase
- Frontend purchase model: `ProductDesignPurchaseRecord`
- Current local repository: `LocalProductDesignPurchaseRepository`
- Expected backend ownership:
  - checkout
  - payment verification
  - course entitlement
  - purchased course list
- Important stored fields:
  - `isPurchased`
  - `purchaseId`
  - `purchasedAt`

### Support
- Frontend support model: `SupportRequestRecord`
- Current local repository: `LocalSupportRepository`
- Expected backend ownership:
  - create support ticket
  - support ticket list/detail if needed later
- Important stored fields:
  - `id`
  - `topic`
  - `subject`
  - `message`
  - `email`
  - `createdAt`

## API endpoint reference

Use `lib/core/network/api_endpoints.dart` as the frontend endpoint contract source.

Main groups already defined there:
- `auth`
- `user`
- `courses`
- `payments`
- `notifications`
- `messages`
- `support`

## Swap strategy

When backend is ready:

1. Keep controllers and screens unchanged.
2. Replace local repositories with remote repositories.
3. Return the same frontend models from remote repositories.
4. Keep local repositories only for cache/offline fallback if needed.

## Recommended backend response shape

### Auth login
```json
{
  "user": {
    "id": "user_1",
    "name": "Kristin Watson",
    "email": "kristin.watson@email.com"
  },
  "session": {
    "accessToken": "token",
    "refreshToken": "refresh",
    "expiresAt": "2026-03-27T10:00:00Z"
  }
}
```

### Profile
```json
{
  "id": "user_1",
  "name": "Kristin Watson",
  "email": "kristin.watson@email.com",
  "phone": "+92 300 1234567",
  "bio": "Product designer who loves learning, prototyping, and clean UI.",
  "avatarUrl": "https://cdn.example.com/avatar.jpg"
}
```

### Purchased course
```json
{
  "courseId": "product_design_v1",
  "isPurchased": true,
  "purchaseId": "pay_1001",
  "purchasedAt": "2026-03-27T10:00:00Z"
}
```

### Notification item
```json
{
  "id": "notification_1001",
  "title": "Successful purchase!",
  "message": "Your course has been unlocked and is ready to play.",
  "type": "purchase",
  "timestamp": "2026-03-27T10:00:00Z",
  "isRead": false
}
```
