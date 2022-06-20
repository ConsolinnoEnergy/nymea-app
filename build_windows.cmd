@echo off
call "C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\VC\Auxiliary\Build\vcvars64.bat"
set
IF "%OVERLAY_REPOSITORY%"=="" (
  "C:\Qt\5.15.2\msvc2019_64\bin\qmake.exe" -spec win32-msvc BRANDING=%BRANDING% SSL_LIBS="C:\SSL"
) ELSE (
  echo "********* Using overlay path"
  git clone %OVERLAY_REPOSITORY% overlay
  "C:\Qt\5.15.2\msvc2019_64\bin\qmake.exe" -spec win32-msvc OVERLAY_PATH=%cd%\overlay BRANDING=%BRANDING% SSL_LIBS="C:\SSL"
)
echo "******** running qmake all"
C:\Qt\Tools\QtCreator\bin\jom.exe qmake_all
echo "******** running lrelease"
C:\Qt\Tools\QtCreator\bin\jom.exe lrelease
echo "******** running building"
C:\Qt\Tools\QtCreator\bin\jom.exe -j9
echo "******** running wininstaller"
C:\Qt\Tools\QtCreator\bin\jom.exe wininstaller
