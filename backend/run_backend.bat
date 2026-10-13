@echo off
rem Starts the Crimson Campus API on port 8000 (reachable from phones on the same Wi-Fi).
cd /d "%~dp0"
if not exist ".venv\Scripts\python.exe" (
  echo Creating virtual environment...
  py -3 -m venv .venv
  ".venv\Scripts\python.exe" -m pip install -r requirements.txt
)
".venv\Scripts\python.exe" -m uvicorn app:app --host 0.0.0.0 --port 8000 --reload
