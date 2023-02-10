@echo off


:: Copy links to the programs folder for detection check and Win10 compatibility
if not exist "C:\Program Files\SVC Tools\"  mkdir "C:\Program Files\SVC Tools\"
if not exist "C:\Program Files\SVC Tools\"  echo Error while creating SVC Tools folder: "%errorlevel%"


REM clear out old files 
if exist "C:\Program Files\SVC Tools\ITComputerInfo\" Del "C:\Program Files\SVC Tools\ITComputerInfo\*" /s /q
if not exist "C:\Program Files\SVC Tools\ITComputerInfo\" mkdir "C:\Program Files\SVC Tools\ITComputerInfo\"
if Not exist "C:\Program Files\SVC Tools\ITComputerInfo\" echo Error while creating ITComputerInfo folder: "%errorlevel%"



REM Move Files Over
xcopy "*" "C:\Program Files\SVC Tools\ITComputerInfo\" /y /s

REM Create shortcut in start menu
xcopy "ITComputerInfo.lnk" "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\" /y



powershell.exe set-executionpolicy RemoteSigned 
Powershell.exe -command (New-Object -ComObject shell.application).Namespace('C:\ProgramData\Microsoft\Windows\Start Menu\Programs\').parsename('ITComputerInfo.lnk').invokeverb('pintostartscreen')

exit
