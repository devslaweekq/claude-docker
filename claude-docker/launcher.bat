@echo off
rem launcher for Windows (WSL2 + Docker Desktop)
rem This file stays pure ASCII on purpose. Paths (which may contain Cyrillic/spaces)
rem are taken at runtime via %CD% / %~dp0 and converted with wslpath inside bash.
rem
rem Usage:
rem   launcher.bat                  double-click or no args -> menu / session
rem   launcher.bat auth status      passthrough -> runs `claude auth status` in the container
rem   launcher.bat login            passthrough -> interactive `claude login`
rem   launcher.bat --pull           launcher flag (pull image, then start)
rem
rem Args are forwarded as bash positional parameters ("$@"), not spliced into the
rem command string, so quotes and spaces in arguments survive intact.

rem Run from the caller's current directory (Explorer cwd when double-clicking the .bat).
wsl.exe -d Ubuntu bash -lic "cd \"$(wslpath -u '%CD%')\" && exec bash \"$(wslpath -u '%~dp0')launcher\" \"$@\"" _ %*
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
