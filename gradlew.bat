@echo off
setlocal enabledelayedexpansion
set "GRADLE_VERSION=8.6"
set "WRAPPER_DIR=%~dp0.gradle-wrapper"
set "DIST_DIR=%WRAPPER_DIR%\gradle-%GRADLE_VERSION%"
set "ZIP=%WRAPPER_DIR%\gradle-%GRADLE_VERSION%-bin.zip"
if not exist "%DIST_DIR%" (
  echo Downloading Gradle %GRADLE_VERSION%...
  if not exist "%WRAPPER_DIR%" mkdir "%WRAPPER_DIR%"
  powershell -Command "Invoke-WebRequest -Uri 'https://services.gradle.org/distributions/gradle-%GRADLE_VERSION%-bin.zip' -OutFile '%ZIP%'"
  powershell -Command "Expand-Archive -Force '%ZIP%' -DestinationPath '%WRAPPER_DIR%'"
  del /q "%ZIP%"
)
"%DIST_DIR%\bin\gradle" %*
