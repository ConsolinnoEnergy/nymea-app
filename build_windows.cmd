"C:\Qt\5.15.2\msvc2019_64\bin\qmake.exe" -spec win32-msvc OVERLAY_PATH=%cd%\overlay BRANDING=%BRANDING% SSL_LIBS="C:\SSL"
echo "******** running qmake all"
nmake qmake_all
echo "******** running lrelease"
nmake lrelease
echo "******** running building"
nmake
echo "******** running wininstaller"
nmake wininstaller
