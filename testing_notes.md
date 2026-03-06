# Testing Strategy & Notes

## Module Coverage
1. **Authentication**: Verify multi-role login flow (Driver vs Admin).
2. **GPS Tracking**: Test background location updates and Firebase writes.
3. **Offline Sync**: Verify SharedPreferences queuing and automatic Supabase push upon reconnection.
4. **Localization**: Ensure UI text strings update across all three supported languages.

## Manual Test Cases
- [ ] Emergency SOS trigger inside and outside park boundaries.
- [ ] Wildlife logging form validation with/without image.
- [ ] Admin dashboard real-time data subscription.
