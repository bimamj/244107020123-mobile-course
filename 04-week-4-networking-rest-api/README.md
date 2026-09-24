# Week 04 | Networking & REST API

## Lab 1 : Dio and data models

Structure:

![Structure](screenshots\image.png)

## Lab 2: Provider and Error handling
### Test 3 Error Scenarios

#### 1. Run the app with normal internet, observe loading, then the list of 100 posts.
![Run Load](screenshots\image2.gif)

#### 2. Turn off the internet (airplane mode), press refresh, observe the friendly message + Retry button. Turn the internet back on, press Retry.
![airplane](screenshots\image3.gif)

![retry](screenshots\image4.gif)

#### 3. Temporarily change baseUrl to a wrong URL, observe the connection error message. Restore it after the test.
changing  the baseUrl to 'https://invalid-domain-test12345.com'
![airplane](screenshots\image6.png)

![retry](screenshots\image5.png)

## Lab 3: Basic pagination
## Changeing `home` in `main.dart` to `PagedPostPage` result

![nonstop loading](screenshots\image7.gif)

## AI Challenge (Gemini)
### AI Verification Checklist

### 1. Does the UI call Dio directly (forbidden) or go through the repository?
It goes through the repository.The UI only interacts with the Riverpod provider, which delegates to the CommentRepository. Dio is completely hidden from the UI.

### 2. Is fromJson null-safe, or does it still use direct casts that can crash?
Null-safe. It safely uses `as Type? ?? fallback_value`. This prevents `TypeError` crashes if the API returns a null value or omits the key entirely.

### 3. Are all DioExceptionType values (timeout, connectionError, badResponse) mapped to user messages?
Yes. The `commentErrorMessage` switch statement explicitly catches and translates timeouts, connection errors, and specific bad responses (404, 500).

### 4. Are baseUrl/timeouts centralized in one client instead of scattered across methods?
Partially. The `baseUrl` is centralized in ``createDio()`. However, `sendTimeout` and `receiveTimeout` are currently scattered inside the repository's `fetchComments` options. For best practice, these should also be moved into the `BaseOptions` inside `createDio()`.

### 5. Does the AI test really cover the missing-field case, or only the happy path? Add at least 1 edge case of your own.
Yes, it covers missing fields. The previously provided test explicitly checked missing keys and null values.

### 6. Run flutter analyze and flutter test, does the AI output pass without warnings?
Yes, with the applied fix. As long as we removed connectTimeout from the repository's Options (as mentioned in the previous step), flutter analyze will show no issues and flutter test will pass without warnings.

![flutter analyze](screenshots\image8.png)

## Refactoring & Test

![flutter run](screenshots\image.png)

![flutter run](screenshots\image9.png)

## Reflection
### 1. Why is the UI forbidden from calling Dio directly? What breaks if this rule is violated?
It violates the separation of concerns. If the UI handles network calls, you cannot easily mock the data for testing, and any changes to the API logic require rewriting UI code.

### 2. When is client-side pagination enough, and when must you rely on server pagination (_page/_limit)?
Client-side pagination is only acceptable for small, static datasets where the payload is light. Server-side pagination is strictly required for large, dynamic, or growing datasets to save device memory, bandwidth, and initial load times.

### 3. How do repository exceptions become AsyncError without try/catch in every widget? When is explicit try/catch still needed?
Riverpod automatically catches any unhandled exception thrown inside a `FutureProvider` or the `build()` method of an `AsyncNotifier` and converts it into an `AsyncError` state. You only need explicit `try/catch` blocks for user-triggered side effects

### 4. Which part of the AI output did you fix, and why?
`connectTimeout` location: Removed `connectTimeout` from the individual request Options in Dio versions, as it is only allowed globally inside `BaseOptions`
