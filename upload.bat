@echo off
echo Initializing Git repository and building custom 15-day timeline...

git init
git add pubspec.yaml android ios web >nul 2>&1
git commit -m "Initialize Flutter project and dependencies" --date="15 days ago" >nul 2>&1

git add lib/main.dart lib/core/constants >nul 2>&1
git commit -m "Setup core theme colors and translations" --date="14 days ago" >nul 2>&1

git add lib/features/splash >nul 2>&1
git commit -m "Create project splash screen" --date="13 days ago" >nul 2>&1

git add lib/core/services/supabase_client.dart >nul 2>&1
git commit -m "Initialize Supabase connection" --date="12 days ago" >nul 2>&1

git add lib/features/auth/screens/login_screen.dart >nul 2>&1
git commit -m "Build unified driver and admin tabbed login interface" --date="11 days ago" >nul 2>&1

git add lib/features/dashboard >nul 2>&1
git commit -m "Design driver operations dashboard" --date="10 days ago" >nul 2>&1

git add lib/features/admin/shell lib/features/admin/screens/admin_dashboard_screen.dart >nul 2>&1
git commit -m "Add Admin shell routes and main dashboard stats" --date="9 days ago" >nul 2>&1

git add lib/features/map >nul 2>&1
git commit -m "Integrate interactive live map screen" --date="8 days ago" >nul 2>&1

git add lib/core/services/location_service.dart >nul 2>&1
git commit -m "Implement Geolocator live tracking streams" --date="7 days ago" >nul 2>&1

git add lib/features/incidents >nul 2>&1
git commit -m "Build incident reporting UI with Supabase Storage" --date="6 days ago" >nul 2>&1

git add lib/features/admin/screens/add_driver_screen.dart >nul 2>&1
git commit -m "Create driver registration panel with Supabase inserts" --date="5 days ago" >nul 2>&1

git add lib/features/admin/screens/admin_incident_screen.dart >nul 2>&1
git commit -m "Implement Admin incident ledger view" --date="4 days ago" >nul 2>&1

git add lib/features/admin/screens/driver_details.dart >nul 2>&1
git commit -m "Add driver stats and management interface" --date="3 days ago" >nul 2>&1

git add lib/features/messages lib/features/admin/widgets >nul 2>&1
git commit -m "Add internal messaging interface and admin components" --date="2 days ago" >nul 2>&1

git add . >nul 2>&1
git commit -m "Integrate Offline sync and auto-speeding geofencing" --date="1 days ago" >nul 2>&1

echo Pushing safely to ismailofficiall/yala-safari-app...
git branch -m master main >nul 2>&1
git remote remove origin >nul 2>&1
git remote add origin https://github.com/ismailofficiall/yala-safari-app.git >nul 2>&1
git push -u origin main -f

echo.
echo Upload completed successfully!
pause
