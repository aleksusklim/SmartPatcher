@echo off
set program=%1
if _%program%_ == __ set program=SmartPatcher1V2.exe
goto begin
:logo
cls
echo �����������������������������������������������������������Ŀ
echo �
echo �                      �����������Ŀ
echo �    Patch creator!    � STEP %step%/4: �     For SmartPatcher:
echo �                      �������������
echo �
goto :eof
:begin
set step=0
if not exist %program% (
call :logo
echo �   `SmartPatcher1V2.exe' not found!
echo �
echo �   Close this window or press ENTER to exit...
echo �
echo �������������������������������������������������������������

pause>nul
exit)
set step=1
call :logo
:p1
echo �         Drag-and-drop or type name an ORIGINAL file
echo �               to this window and press ENTER:
echo �
set /P f1=�   Original=
call :quote %f1%
set f1=%ret%
if _%f1%_ == __ (
call :logo
goto p1)
if not exist %f1% (
call :logo
echo �                 ��������������������������Ŀ
echo �                 � Original file not found! �
echo �                 ����������������������������
echo �
goto p1)
set step=2
call :logo
:p2
echo �         Drag-and-drop (or type name) a MODIFIED file
echo �               to this window and press ENTER:
echo �
set /P f2=�   Modified=
call :quote %f2%
set f2=%ret%
if _%f2%_ == __ (
call :logo
goto p2)
if not exist %f2% (
call :logo
echo �                 ��������������������������Ŀ
echo �                 � Modified file not found! �
echo �                 ����������������������������
echo �
goto p2)
set step=3
call :logo
:p3
echo �     Type name for patch file or drag-and-drop existing
echo �      or new empty file to this window and press ENTER:
echo �            (extension will be changed to .bat)
echo �
set /P f3=�   Save BAT to=
call :extbat %f3%
set f3=%ret%
call :logo
if _%f3%_ == __ goto p3
if not exist %f3% (
echo !>%f3%
call :logo
if not exist %f3% (
echo �                 ���������������������������Ŀ
echo �                 � Wrong filename for patch! �
echo �                 �����������������������������
echo �
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