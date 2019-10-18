program SmartPatcher1V2;

{$APPTYPE CONSOLE}

uses SysUtils,Classes,patchcreator;

function CloseHandle(handle:Integer):integer;
stdcall; external 'kernel32.dll';
function CreateProcessA(name,comm:PChar;p1,p2,p3,p4,p5,p6,INFO,LPI:integer):integer;
stdcall; external 'kernel32.dll';
function GetEnvironmentVariableA(stin,stout,size:integer):integer;
stdcall; external 'kernel32.dll';
function GetTempPathA(size,name:integer):integer;
stdcall; external 'kernel32.dll';

function envget(name:AnsiString):AnsiString;
var i:Cardinal;s:ShortString;
begin i:=GetEnvironmentVariableA(Integer(PChar(name)),Integer(@s)+1,255);
SetLength(s,i);Result:=s;end;

function tempget():AnsiString;
var i:Cardinal;s:ShortString;
begin i:=GetTempPathA(255,Integer(@s)+1);
SetLength(s,i);Result:=s;end;

const CRCBufferSize=$F000;
var CRCTable:array [0..256] of integer;
CRCBuffer,CompareBuffer:array [0..CRCBufferSize+1] of byte;
tableused:boolean;

function streamcompare(Stream1,Stream2:TFileStream;count:int64):boolean;
var
  BufSize, N,P1,P2: int64;
begin
P1:=Stream1.Position;
P2:=Stream2.Position;
  Result := true;
  if Count > CRCBufferSize then BufSize := CRCBufferSize else BufSize := Count;
  try
    while Count <> 0 do
    begin
      if Count > BufSize then N := BufSize else N := Count;
      Stream1.ReadBuffer(CRCBuffer, N);
      Stream2.ReadBuffer(CompareBuffer, N);
      Dec(Count, N);
      if not CompareMem(@CRCBuffer,@CompareBuffer,N) then
        begin
        Result:=false;
        Count:=0;
        end;
    end;
  finally
    Stream1.Seek(P1,soFromBeginning);
    Stream2.Seek(P2,soFromBeginning);
    end;
end;

procedure makecrctable;
var i,c,k:integer;
 begin
  i:=0;
  repeat
   c:=i;
   k:=0;
   repeat
    if (c and 1)=1 then c:=(c shr 1) xor $EDB88320
    else c:=c shr 1;
    k:=k+1;
   until (k>7);
   CRCTable[i]:=c;
   i:=i+1;
  until (i>255);
 end;

function getcrc(filename:AnsiString):cardinal;
var crc,i,n:Cardinal;
f:TFileStream;
begin
  if tableused then
  begin
   makecrctable;
   tableused:=false;
  end;
  f:=TFileStream.Create(filename,fmOpenRead or fmShareDenyNone);
  n:=f.Read(CRCBuffer,CRCBufferSize);
  crc:=$FFFFFFFF;
  while(n>0) do
  begin
   i:=0;
   while (i<n) do
   begin
    crc:=CRCTable[(crc xor CRCBuffer[i])and 255]xor((crc shr 8)and $00FFFFFF);
    Inc(i);
   end;
  n:=f.Read(CRCBuffer,CRCBufferSize);
  end;
  f.Free;
  Result:=(crc xor $FFFFFFFF);
end;

type
LPI=record proc,thrd,PID,TID:integer;end;
INFO=record cb:integer;p:array [1..70] of byte;end;

const
FF64=int64(-1);
WAITTIME=50;
batch='@cd /D "%~dp0"&@SmartPatcher1V2.exe %0 %1&@exit'+chr(10);
iPAD='³   ';
PatchCreatorCmd='PatchCreator.cmd';

var
mINFO:INFO;
mLPI:LPI;
a:char;
e,b1,b2,WARP,auto:boolean;
namepcrc,line,temppath,PAD:AnsiString;
i,mode:byte;
ucrc1,ucrc2,ucrc3,ucrc4,ret:cardinal;
comspec:PChar;
stream,save,fs1,fs2,fs3,fs4:TFileStream;
r1,r2,r0,r3,r5,count,offset,lastoff:int64;

procedure writelm(o:AnsiString);
var s:AnsiString;begin
if auto then PAD:='';
if o[Length(o)]='_' then begin
s:=copy(o,1,Length(o)-1);
if WARP then write('  ',s) else begin
WARP:=true;write(PAD+s);end;
end else begin s:=o;if WARP then begin
writeln('');writeln(PAD);writeln(PAD+s);writeln(PAD);
end else begin writeln(PAD+s);writeln(PAD);
end;WARP:=false;end;
if auto then PAD:=iPAD;end;

procedure wcont(s:AnsiString);begin
if auto then begin
writelm(s);if WARP then writeln('');
end else begin
writelm(s);if WARP then begin writeln('');writeln(PAD);end;
writeln('³               ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿');
writeln('³               ³ Press ENTER to continue: ³');
writeln('³               ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ');
write(PAD);readln(a);end;end;
procedure wexit(s:AnsiString);begin
if auto then begin
writelm(s);if WARP then writeln('');
Halt(ret);
end else begin
writelm(s);if WARP then begin writeln('');writeln(PAD);end;
writeln('³            ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿');
writeln('³            ³ Press ENTER to exit program... ³');
writeln('³            ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ');
writeln(PAD);
writeln('ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ');
readln(a);Halt(ret);end;end;

procedure logo;
begin
if auto then begin
writeln('SmartPatcher v1.2! Kly_Men_COmpany.');writeln('');
end else begin
writeln('³          ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿');
writeln('³          ³ SmartPatcher v1.2! Kly_Men_COmpany. ³');
writeln('³          ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ');
writeln(PAD);
end;end;procedure dline;begin
if not auto then begin
writeln('ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿');
writeln(PAD);end;end;

const
int_bit:array[0..7]of byte=(
0,1,3,7,15,31,63,127);
int_size:array[0..6]of int64=(
127,16383,2097151,268435455,34359738367,4398046511103,562949953421311);
int_neg:array[0..7]of byte=(
0,128,192,224,240,248,252,254);
var int_v:int64;
int_x,int_n,int_b:byte;
int_p:array[0..7] of byte absolute int_v;

procedure intwrite(s:TFileStream;val:int64);
begin
int_v:=val;
int_n:=0;
while int_v>int_size[int_n] do inc(int_n);
if (int_n=8) then begin int_n:=0;int_v:=0;end;
if (int_n=0) then begin
save.WriteBuffer(int_v,1);
end else begin
int_x:=int_p[int_n] or int_neg[int_n];
s.WriteBuffer(int_x,1);
s.WriteBuffer(int_v,int_n);
end;
end;

function intread(s:TFileStream):int64;
begin
s.ReadBuffer(int_x,1);
if int_x=255 then begin
Result:=FF64;
end else begin
int_n:=7;
while ((1 shl int_n)and(int_x))>0 do dec(int_n);
int_b:=7-int_n;
int_v:=0;
s.ReadBuffer(int_v,int_b);
int_p[int_b]:=int_x and int_bit[int_n];
Result:=int_v;
end;
end;

label cmp0,cmp1,cmp2,cmp3,cmp4,creating,pathcing;

begin WARP:=false;tableused:=true;auto:=false;PAD:=iPAD;ret:=1;
if ParamCount>3 then begin
auto:=true;writeln('');logo;
if (ParamCount=4)and(ParamStr(4)='*') then
begin
line:=ParamStr(3);
if (line='1') then begin mode:=1;goto pathcing;end;
if (line='2') then begin mode:=2;goto pathcing;end;
if (line='*') then begin mode:=0;goto pathcing;end;
end;
if (ParamCount=5)and(ParamStr(4)='*')and(ParamStr(5)='*') then goto creating;
dline;wexit('Wrong usage!');end;
temppath:=tempget()+'SmartPatcher1V2.';
comspec:=PChar(envget('ComSpec'));
if ParamCount<1 then begin try
save:=TFileStream.Create(temppath+PatchCreatorCmd,fmCreate or fmShareDenyNone);
save.WriteBuffer(patchcreator_data,sizeof(patchcreator_data));save.Free;
save:=TFileStream.Create(temppath+PatchCreatorCmd,fmOpenRead or fmShareDenyWrite);
CreateProcessA(comspec,PChar('cmd.exe /A /D /C '+temppath+PatchCreatorCmd+' "'+ParamStr(0)+'"'),0,0,0,0,0,0,Integer(@mINFO),Integer(@mLPI));
CloseHandle(mLPI.proc);CloseHandle(mLPI.thrd);exit;
except dline;logo;wexit('Starting `Patch Creator` error!');end;end;
if ParamCount<2 then begin
dline;logo;
try try
fs1:=TFileStream.Create(ParamStr(1),fmOpenRead or fmShareDenyNone);
fs1.Seek(-1,soFromEnd);
fs1.ReadBuffer(int_b,1);
if (int_b<6) then begin
fs1.Free;wexit('Patch script wrong!');end;
fs1.Seek(int_b,soFromBeginning);
fs1.ReadBuffer(int_b,1);
if int_b<>1 then wexit('Patch script wrong!');
fs1.ReadBuffer(ucrc3,4);
fs1.ReadBuffer(ucrc4,4);
ucrc1:=intread(fs1);
ucrc2:=intread(fs1);
writelm('Original file must have:');
writelm('     CRC : '+IntToHex(ucrc3,8)+'     Size: '+IntToStr(ucrc1));
writelm('Modified file must have:');
writelm('     CRC : '+IntToHex(ucrc4,8)+'     Size: '+IntToStr(ucrc2));
finally fs1.Free;end;
except wexit('Drag and drop target file to BAT to use this patch!');end;
wexit('Drag and drop target file to BAT to use this patch!');
end;
if ParamCount<3 then dline;
logo;

if ParamCount=3 then begin creating:
if not FileExists(ParamStr(1)) then wexit('Original file not found!');
if not FileExists(ParamStr(2)) then wexit('Modified file not found!');
try fs1:=TFileStream.Create(ParamStr(1),fmOpenRead or fmShareDenyWrite);
fs2:=TFileStream.Create(ParamStr(2),fmOpenRead or fmShareDenyWrite);
except wexit('Input files open error!');end;
ucrc1:=fs1.Size;ucrc2:=fs2.Size;fs1.Free;fs2.Free;
if ucrc1<>ucrc2 then wcont('Input files different sizes!');
writelm('Comparing..._');
ucrc3:=getcrc(ParamStr(1));ucrc4:=getcrc(ParamStr(2));
if ucrc3=ucrc4 then wcont('Input files seem identical!');
writelm('Creating..._');
try save:=TFileStream.Create(ParamStr(3),fmCreate or fmShareExclusive);
except wexit('Cannot create target file!');end;
try try fs1:=TFileStream.Create(ParamStr(1),fmOpenRead or fmShareDenyWrite);
fs2:=TFileStream.Create(ParamStr(2),fmOpenRead or fmShareDenyWrite);
fs3:=TFileStream.Create(ParamStr(1),fmOpenRead or fmShareDenyWrite);
fs4:=TFileStream.Create(ParamStr(2),fmOpenRead or fmShareDenyWrite);
except wexit('Input files open error!');end;
try save.WriteBuffer(batch,length(batch));
int_b:=1;save.WriteBuffer(int_b,1);
save.WriteBuffer(ucrc3,4);save.WriteBuffer(ucrc4,4);
intwrite(save,ucrc1);intwrite(save,ucrc2);
lastoff:=0;
r2:=FF64;
r3:=FF64;
r5:=0;
cmp0:
r0:=r2;
r1:=fs3.Read(CRCBuffer,CRCBufferSize);
r2:=fs4.Read(CompareBuffer,CRCBufferSize);
if r1>r2 then r1:=r2;
if r0<>FF64 then r2:=r0+r5 else r2:=0;
r5:=r1;r0:=0;
if r1<1 then begin Inc(r0);if r3=FF64 then goto cmp3 else goto cmp2;end;
cmp1:
if r0>r1 then goto cmp0;
if CRCBuffer[r0]<>CompareBuffer[r0] then
begin
if r3=FF64 then r3:=r2+r0;
end else begin
if r3<>FF64 then begin Inc(r0);goto cmp2;end;
end;
Inc(r0);
goto cmp1;
cmp2:
offset:=r3-lastoff;
count:=r2+r0-r3-1;
lastoff:=lastoff+offset+count;
intwrite(save,offset);
intwrite(save,count);
fs1.Seek(r3,soFromBeginning);fs2.Seek(r3,soFromBeginning);
save.CopyFrom(fs1,count);save.CopyFrom(fs2,count);
r3:=FF64;
if r1>0 then goto cmp1;
cmp3:;
int_b:=length(batch);int_n:=255;
save.WriteBuffer(int_n,1);
save.WriteBuffer(int_b,1);
finally
fs1.Free;fs2.Free;fs3.Free;fs4.Free;
save.Free;
end;except wexit('I/O error!');end;
ret:=0;wexit('Done!_');end;

if ParamCount=2 then begin pathcing:
if not FileExists(ParamStr(1)) then wexit('Patch script not found!');
if not FileExists(ParamStr(2)) then wexit('Target file not found!');
try fs1:=TFileStream.Create(ParamStr(1),fmOpenRead or fmShareDenyWrite);
fs2:=TFileStream.Create(ParamStr(2),fmOpenReadWrite or fmShareDenyWrite);
except wexit('File open error!');end;
try
fs1.Seek(-1,soFromEnd);
fs1.ReadBuffer(int_b,1);
if (int_b<6) then begin
fs1.Free;fs2.Free;wexit('Patch script wrong!');end;
fs1.Seek(int_b,soFromBeginning);
fs1.ReadBuffer(int_b,1);
if int_b<>1 then wexit('Patch script wrong!');
writelm('Comparing..._');
fs1.ReadBuffer(ucrc3,4);fs1.ReadBuffer(ucrc4,4);b1:=true;
ucrc1:=intread(fs1);ucrc2:=intread(fs1);
if (fs2.Size<>ucrc1)and(fs2.Size<>ucrc2) then begin b1:=false;
wcont('Target file size maybe wrong for this patch!');end;
ucrc1:=getcrc(ParamStr(2));
if (ucrc1<>ucrc3)and(ucrc1<>ucrc4)and(b1) then
wcont('Target file CRC seems incorrect for this patch!');
writelm('Testing..._');lastoff:=fs1.Position;
i:=1;b1:=true;b2:=true;
except fs1.Free;fs2.Free;wexit('I/O error!');end;
try repeat
offset:=intread(fs1);count:=intread(fs1);
if (offset=FF64)or(fs2.Position+offset+count>fs2.Size) then break;
fs2.Seek(offset,soFromCurrent);
if b1 then b1:=streamcompare(fs1,fs2,count);
fs1.Seek(count,soFromCurrent);
if b2 then b2:=streamcompare(fs1,fs2,count);
fs2.Seek(count,soFromCurrent);
fs1.Seek(count,soFromCurrent);
if (b1=false)and(b2=false) then begin i:=2;break;end;
until false;except i:=0;end;
fs1.Seek(lastoff,soFromBeginning);
fs2.Seek(0,soFromBeginning);
if i=0 then begin fs1.Free;fs2.Free;wexit('I/O error!');end;
if mode>0 then begin if i=2 then
wcont('Target is different than original or patched data!');i:=1;b1:=true;b2:=false;end;
if i=1 then begin try try
if b2=b1 then begin fs1.Free;fs2.Free;wexit('Patch cannot be applied!');end;
if mode=1 then b2:=false;
if mode=2 then b2:=true;
if b2 then begin
if not auto then wcont('File already was patched!     Restore to original ?');
writelm('Restoring..._');
repeat
offset:=intread(fs1);count:=intread(fs1);
if (offset=FF64)or(fs2.Position+offset+count>fs2.Size) then break;
fs2.Seek(offset,soFromCurrent);
fs2.CopyFrom(fs1,count);
fs1.Seek(count,soFromCurrent);
until false;
end else begin writelm('Patching..._');
repeat
offset:=intread(fs1);count:=intread(fs1);
if (offset=FF64)or(fs2.Position+offset+count>fs2.Size) then break;
fs1.Seek(count,soFromCurrent);
fs2.Seek(offset,soFromCurrent);
if count>0 then fs2.CopyFrom(fs1,count);
until false;
end;
finally fs1.Free;fs2.Free;end
except wexit('I/O error!');end;
ret:=0;wexit('Done!_');end;
if i=2 then begin e:=true;try try
wcont('Target is different than original or patched data!');
writelm('Backuping..._');
line:=ParamStr(2)+'.backup_';i:=1;
while FileExists(line+inttostr(i)+'.bat') do inc(i);line:=line+inttostr(i)+'.bat';
try save:=TFileStream.Create(line,fmCreate or fmShareExclusive);
except wexit('Cannot Create .backup_'+inttostr(i)+'.bat file!');end;
save.WriteBuffer(batch,length(batch));
int_b:=1;save.WriteBuffer(int_b,1);
i:=0;save.WriteBuffer(i,4);save.WriteBuffer(ucrc1,4);
ucrc2:=fs2.size;
intwrite(save,ucrc2);intwrite(save,ucrc2);
repeat
offset:=intread(fs1);count:=intread(fs1);
intwrite(save,offset);intwrite(save,count);
if (offset=FF64)or(fs2.Position+offset+count>fs2.Size) then break;
fs1.Seek(count,soFromCurrent);
fs2.Seek(offset,soFromCurrent);
save.CopyFrom(fs1,count);
save.CopyFrom(fs2,count);
until false;
writelm('Patching..._');
fs1.Seek(lastoff,soFromBeginning);
fs2.Seek(0,soFromBeginning);
repeat
offset:=intread(fs1);count:=intread(fs1);
if (offset=FF64)or(fs2.Position+offset+count>fs2.Size) then break;
fs1.Seek(count,soFromCurrent);
fs2.Seek(offset,soFromCurrent);
if count>0 then fs2.CopyFrom(fs1,count);
until false;
e:=false;fs2.Free;
ucrc4:=getcrc(ParamStr(2));
save.Seek(length(batch)+1,soFromBeginning);
save.WriteBuffer(ucrc4,4);
finally fs1.Free;if e then fs2.Free;save.Free;end
except wexit('I/O error!');end;
ret:=0;wexit('Done!_');end;
end;
end.

