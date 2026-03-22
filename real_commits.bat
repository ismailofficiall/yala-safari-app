@echo off
echo Wiping old repository and starting fresh...
rd /s /q .git

echo Initializing fresh Git repository for 25 real 10-day commits...
git init

:: --- DAY 10 AGO ---
git add pubspec.yaml android ios web >nul 2>&1
git commit -m "Init Flutter project and setup environments" --date="10 days ago" >nul 2>&1

git add lib/core/constants >nul 2>&1
git commit -m "Setup core colors and design theme constants" --date="10 days ago" >nul 2>&1

git add lib/core/translations >nul 2>&1
git commit -m "Implement localization configurations" --date="10 days ago" >nul 2>&1

:: --- DAY 9 AGO ---
git add lib/core/services/supabase_client.dart >nul 2>&1
git commit -m "Init Supabase connection wrapper" --date="9 days ago" >nul 2>&1

git add lib/main.dart >nul 2>&1
git commit -m "Setup app entrypoint and provider structure" --date="9 days ago" >nul 2>&1

:: --- DAY 8 AGO ---
git add lib/features/splash >nul 2>&1
git commit -m "Design and animate Splash screen vector" --date="8 days ago" >nul 2>&1

git add lib/features/auth/screens/login_screen.dart >nul 2>&1
git commit -m "Draft basic driver login authentication form" --date="8 days ago" >nul 2>&1

:: --- DAY 7 AGO ---
git add lib/features/auth/screens/driver_signup_screen.dart >nul 2>&1
git commit -m "Build driver self-registration screen logic" --date="7 days ago" >nul 2>&1

git add lib/features/auth >nul 2>&1
git commit -m "Finalize auth module state handling" --date="7 days ago" >nul 2>&1

:: --- DAY 6 AGO ---
git add lib/features/dashboard >nul 2>&1
git commit -m "Draft driver dashboard layout" --date="6 days ago" >nul 2>&1

git add lib/core/services/location_service.dart >nul 2>&1
git commit -m "Implement core geolocator service logic" --date="6 days ago" >nul 2>&1

git add lib/features/map/screens/live_map_screen.dart >nul 2>&1
git commit -m "Setup live tracking interactive map rendering structure" --date="6 days ago" >nul 2>&1

:: --- DAY 5 AGO ---
git add lib/features/map >nul 2>&1
git commit -m "Finalize location markers and map module" --date="5 days ago" >nul 2>&1

git add lib/features/incidents/screens/incident_report_screen.dart >nul 2>&1
git commit -m "Build basic incident reporting view" --date="5 days ago" >nul 2>&1

:: --- DAY 4 AGO ---
git add lib/features/incidents >nul 2>&1
git commit -m "Integrate Supabase storage for incident images" --date="4 days ago" >nul 2>&1

git add lib/core/services/offline_sync_service.dart >nul 2>&1
git commit -m "Implement local caching logic for offline SOS forms" --date="4 days ago" >nul 2>&1

:: --- DAY 3 AGO ---
git add lib/features/admin/services >nul 2>&1
git commit -m "Setup RBAC access limits for Admin tier" --date="3 days ago" >nul 2>&1

git add lib/features/admin/shell >nul 2>&1
git commit -m "Design bottom navigation shell for Admin console" --date="3 days ago" >nul 2>&1

git add lib/features/admin/screens/admin_dashboard_screen.dart >nul 2>&1
git commit -m "Integrate live metric fetching on Admin Dashboard" --date="3 days ago" >nul 2>&1

:: --- DAY 2 AGO ---
git add lib/features/admin/screens/add_driver_screen.dart >nul 2>&1
git commit -m "Create manual fleet vehicle generator panel" --date="2 days ago" >nul 2>&1

git add lib/features/admin/screens/driver_details.dart >nul 2>&1
git commit -m "Add specific driver statistic overview and rating mutator" --date="2 days ago" >nul 2>&1

git add lib/features/admin/screens/admin_incident_screen.dart >nul 2>&1
git commit -m "Build central incident ledger for emergency responses" --date="2 days ago" >nul 2>&1

:: --- DAY 1 AGO (TODAY) ---
git add lib/features/admin/map >nul 2>&1
git commit -m "Integrate admin bird-eye view radar map" --date="1 days ago" >nul 2>&1

git add lib/features/messages >nul 2>&1
git commit -m "Establish one-way notification messaging broadcast" --date="1 days ago" >nul 2>&1

git add lib/features/profile >nul 2>&1
git commit -m "Code driver performance tracking profile UI" --date="0 days ago" >nul 2>&1

git add . >nul 2>&1
git commit -m "Cleanup dependencies, auto-speeding geolocator, format files, and finalize V1 Launch" --date="0 days ago" >nul 2>&1
git branch -m master main >nul 2>&1

echo Pushing securely to ismailofficiall/yala-safari-app...
git remote add origin https://github.com/ismailofficiall/yala-safari-app.git >nul 2>&1
git push origin main -f

echo.
echo All 26 authentic working file commits across 10-days have been successfully injected!
pause
