@echo off
set program=%1
if _%program%_ == __ set program=SmartPatcher1V2.exe
goto begin
:logo
cls
echo зддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд©
echo Ё
echo Ё                      зддддддддддд©
echo Ё    Patch creator!    Ё STEP %step%/4: Ё     For SmartPatcher:
echo Ё                      юддддддддддды
echo Ё
goto :eof
:begin
set step=0
if not exist %program% (
call :logo
echo Ё   `SmartPatcher1V2.exe' not found!
echo Ё
echo Ё   Close this window or press ENTER to exit...
echo Ё
echo юддддддддддддддддддддддддддддддддддддддддддддддддддддддддддды

pause>nul
exit)
set step=1
call :logo
:p1
echo Ё         Drag-and-drop or type name an ORIGINAL file
echo Ё               to this window and press ENTER:
echo Ё
set /P f1=Ё   Original=
call :quote %f1%
set f1=%ret%
if _%f1%_ == __ (
call :logo
goto p1)
if not exist %f1% (
call :logo
echo Ё                 здддддддддддддддддддддддддд©
echo Ё                 Ё Original file not found! Ё
echo Ё                 юдддддддддддддддддддддддддды
echo Ё
goto p1)
set step=2
call :logo
:p2
echo Ё         Drag-and-drop (or type name) a MODIFIED file
echo Ё               to this window and press ENTER:
echo Ё
set /P f2=Ё   Modified=
call :quote %f2%
set f2=%ret%
if _%f2%_ == __ (
call :logo
goto p2)
if not exist %f2% (
call :logo
echo Ё                 здддддддддддддддддддддддддд©
echo Ё                 Ё Modified file not found! Ё
echo Ё                 юдддддддддддддддддддддддддды
echo Ё
goto p2)
set step=3
call :logo
:p3
echo Ё     Type name for patch file or drag-and-drop existing
echo Ё      or new empty file to this window and press ENTER:
echo Ё            (extension will be changed to .bat)
echo Ё
set /P f3=Ё   Save BAT to=
call :extbat %f3%
set f3=%ret%
call :logo
if _%f3%_ == __ goto p3
if not exist %f3% (
echo !>%f3%
call :logo
if not exist %f3% (
echo Ё                 зддддддддддддддддддддддддддд©
echo Ё                 Ё Wrong filename for patch! Ё
echo Ё                 юддддддддддддддддддддддддддды
echo Ё
goto p3)
)
set step=4
call :logo
call :make %f1% %f2% %f3%
goto :eof
:make
%program% %1 %2 "%~dpn3.bat"
goto :eof
:quote
set ret="%~1"
if not _%2_ == __ set ret="%*"
goto :eof
:extbat
set ret="%~dpn1.bat"
goto :eof