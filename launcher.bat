@echo off
rem launcher for Windows (WSL2 + Docker Desktop)
rem This file stays pure ASCII on purpose. Paths (which may contain Cyrillic/spaces)
rem are taken at runtime via %CD% / %~dp0 and converted with wslpath inside bash.

rem Run from the caller's current directory (Explorer cwd when double-clicking the .bat).
wsl.exe -d Ubuntu bash -lic "cd \"$(wslpath -u '%CD%')\" && bash \"$(wslpath -u '%~dp0')launcher\" %*"
set "RC=%errorlevel%"

if not "%RC%"=="0" (
  echo.
  echo [launcher] Exited with code %RC%.
  echo  - "docker: command not found"            -^> enable Docker Desktop WSL Integration for your distro
  echo  - "cannot connect to the Docker daemon"  -^> start Docker Desktop, wait until it is running
  echo  - "No such file or directory"            -^> path conversion failed; check WSL distro name (wsl -l -v)
  echo.
  pause
)
