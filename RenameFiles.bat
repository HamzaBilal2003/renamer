@echo off
title File Renamer - Audio / Image / Video
color 0A

echo ================================================
echo      FILE RENAMER  (Audio / Image / Video)
echo ================================================
echo.

:: ── Check if Python is installed ─────────────────────────────
python --version >nul 2>&1
if %errorlevel% == 0 goto :RUN

py --version >nul 2>&1
if %errorlevel% == 0 goto :RUN_PY

:: ── Python not found — auto download and install ─────────────
echo [!] Python is not installed on this PC.
echo [*] Downloading Python installer... please wait.
echo.

:: Download Python 3.11 installer silently
curl -L -o "%temp%\python_installer.exe" https://www.python.org/ftp/python/3.11.9/python-3.11.9-amd64.exe

if not exist "%temp%\python_installer.exe" (
    echo [ERROR] Download failed. Please install Python manually from:
    echo         https://www.python.org/downloads
    pause
    exit /b 1
)

echo [*] Installing Python silently... please wait.
"%temp%\python_installer.exe" /quiet InstallAllUsers=0 PrependPath=1 Include_test=0

:: Refresh PATH
call refreshenv >nul 2>&1

python --version >nul 2>&1
if %errorlevel% == 0 goto :RUN

echo [ERROR] Installation failed. Please restart this file after installing Python manually.
pause
exit /b 1


:RUN_PY
:: Use 'py' launcher
echo [OK] Python found.
echo.

:: Write the Python script next to this BAT file
set "SCRIPT=%~dp0rename_files_runner.py"
call :WRITE_SCRIPT
py "%SCRIPT%"
goto :CLEANUP

:RUN
echo [OK] Python found.
echo.

set "SCRIPT=%~dp0rename_files_runner.py"
call :WRITE_SCRIPT
python "%SCRIPT%"
goto :CLEANUP


:CLEANUP
del "%SCRIPT%" >nul 2>&1
echo.
pause
exit /b 0


:: ── Writes the Python script inline ──────────────────────────
:WRITE_SCRIPT
(
echo import os, re, sys
echo.
echo AUDIO_EXTS  = {'.mp3','.wav','.aac','.flac','.ogg','.m4a','.wma','.opus','.aiff'}
echo IMAGE_EXTS  = {'.jpg','.jpeg','.png','.gif','.bmp','.webp','.tiff','.tif','.svg','.ico','.heic'}
echo VIDEO_EXTS  = {'.mp4','.mkv','.avi','.mov','.wmv','.flv','.webm','.m4v','.3gp','.mpeg','.mpg'}
echo.
echo def get_file_type^(ext^):
echo     ext = ext.lower^(^)
echo     if ext in AUDIO_EXTS: return "Audio"
echo     if ext in IMAGE_EXTS: return "Image"
echo     if ext in VIDEO_EXTS: return "Video"
echo     return None
echo.
echo def scan_folder^(folder^):
echo     results = []
echo     try:
echo         entries = sorted^(os.listdir^(folder^)^)
echo     except PermissionError:
echo         print^(f"  [!] Cannot read folder: {folder}"^)
echo         return results
echo     for name in entries:
echo         path = os.path.join^(folder, name^)
echo         if not os.path.isfile^(path^): continue
echo         _, ext = os.path.splitext^(name^)
echo         ftype = get_file_type^(ext^)
echo         if ftype:
echo             results.append^(^(name, path, ftype^)^)
echo     return results
echo.
echo def rename_files^(files, folder, base_name, add_number, dry_run=False^):
echo     renamed = []
echo     used_names = set^(os.listdir^(folder^)^)
echo     for idx, ^(orig_name, orig_path, ftype^) in enumerate^(files, start=1^):
echo         _, ext = os.path.splitext^(orig_name^)
echo         if add_number and len^(files^) ^> 1:
echo             new_stem = f"{base_name} {idx}"
echo         else:
echo             new_stem = base_name
echo         new_name = new_stem + ext.lower^(^)
echo         if new_name in used_names and new_name != orig_name:
echo             counter = 1
echo             while True:
echo                 candidate = f"{new_stem} ^({counter}^){ext.lower^(^)}"
echo                 if candidate not in used_names or candidate == orig_name:
echo                     new_name = candidate
echo                     break
echo                 counter += 1
echo         new_path = os.path.join^(folder, new_name^)
echo         if dry_run:
echo             print^(f"  [{ftype}]  {orig_name}  -^>  {new_name}"^)
echo         else:
echo             if orig_path != new_path:
echo                 os.rename^(orig_path, new_path^)
echo                 print^(f"  OK [{ftype}]  {orig_name}  -^>  {new_name}"^)
echo             else:
echo                 print^(f"  -- [{ftype}]  {orig_name}  ^(no change^)"^)
echo         used_names.discard^(orig_name^)
echo         used_names.add^(new_name^)
echo         renamed.append^(^(orig_name, new_name^)^)
echo     return renamed
echo.
echo def ask^(prompt, default=None^):
echo     if default is not None:
echo         prompt = f"{prompt} [{default}]: "
echo     else:
echo         prompt = f"{prompt}: "
echo     answer = input^(prompt^).strip^(^)
echo     return answer if answer else default
echo.
echo def main^(^):
echo     print^("=" * 55^)
echo     print^("       FILE RENAMER  ^(Audio / Image / Video^)"^)
echo     print^("=" * 55^)
echo     folder = ask^("Enter folder path ^(press Enter for current directory^)", "."^)
echo     folder = os.path.expanduser^(folder^)
echo     if not os.path.isdir^(folder^):
echo         print^(f"[ERROR] Not a valid directory: {folder}"^)
echo         sys.exit^(1^)
echo     print^("\nWhich file types do you want to rename?"^)
echo     print^("  1^) Audio only"^)
echo     print^("  2^) Image only"^)
echo     print^("  3^) Video only"^)
echo     print^("  4^) All ^(Audio + Image + Video^)"^)
echo     choice = ask^("Choose", "4"^)
echo     type_filter = {"1": {"Audio"}, "2": {"Image"}, "3": {"Video"}, "4": {"Audio","Image","Video"}}.get^(choice, {"Audio","Image","Video"}^)
echo     files = [^(n,p,t^) for n,p,t in scan_folder^(folder^) if t in type_filter]
echo     if not files:
echo         print^("\n[!] No matching files found."^)
echo         sys.exit^(0^)
echo     print^(f"\nFound {len^(files^)} file^(s^):"^)
echo     for name, _, ftype in files:
echo         print^(f"  [{ftype}]  {name}"^)
echo     print^(^)
echo     base_name = ask^("Enter the new base name for the files"^)
echo     if not base_name:
echo         print^("[ERROR] Name cannot be empty."^)
echo         sys.exit^(1^)
echo     add_num = ask^("Add a number after the name? ^(yes/no^)", "yes"^).lower^(^)
echo     add_number = add_num in ^("yes","y","1","true"^)
echo     if add_number:
echo         print^(f"\n  Example: '{base_name} 1.mp3',  '{base_name} 2.jpg', ..."^)
echo     else:
echo         print^(f"\n  Example: '{base_name}.mp3',  '{base_name}.jpg', ..."^)
echo     print^("\n-- Preview ^(no changes yet^) ---"^)
echo     rename_files^(files, folder, base_name, add_number, dry_run=True^)
echo     confirm = ask^("\nProceed with renaming? ^(yes/no^)", "yes"^).lower^(^)
echo     if confirm not in ^("yes","y"^):
echo         print^("Cancelled."^)
echo         sys.exit^(0^)
echo     print^("\n-- Renaming ---"^)
echo     rename_files^(files, folder, base_name, add_number, dry_run=False^)
echo     print^("\nDone!"^)
echo.
echo main^(^)
) > "%SCRIPT%"
goto :EOF
