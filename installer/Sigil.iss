; We use CMake's configure_file command to replace ${VAR_NAME} variables
; with actual values. Note the dollar sign; {VAR_NAME} variables are from
; Inno, the ones with the dollar we define with CMake.

[Setup]
AppName=Sigil
AppVerName=Sigil ${SIGIL_FULL_VERSION}
VersionInfoVersion=${SIGIL_FULL_VERSION}
DefaultDirName={pf}\Sigil
DefaultGroupName=Sigil
UninstallDisplayIcon={app}\Sigil.exe
AppPublisher=Sigil-Ebook
AppPublisherURL=https://github.com/Sigil-Ebook/Sigil
WizardImageFile=compiler:wizmodernimage-IS.bmp
WizardSmallImageFile=compiler:wizmodernsmallimage-IS.bmp
Compression=lzma2/ultra
SolidCompression=yes
OutputDir=..\installer
LicenseFile=${LICENSE_LOCATION}
; Win Vista is the lowest supported version
MinVersion=0,5.1
PrivilegesRequired=admin
OutputBaseFilename=Sigil-${SIGIL_FULL_VERSION}-Legacy-Windows${ISS_SETUP_FILENAME_PLATFORM}-Setup
ChangesAssociations=yes

; "ArchitecturesAllowed=x64" specifies that Setup cannot run on
; anything but x64.
; The ${ISS_ARCH} var is substituted with "x64" or an empty string
ArchitecturesAllowed="${ISS_ARCH}"
; "ArchitecturesInstallIn64BitMode=x64" requests that the install be
; done in "64-bit mode" on x64, meaning it should use the native
; 64-bit Program Files directory and the 64-bit view of the registry.
; The ${ISS_ARCH} var is substituted with "x64" or an empty string
ArchitecturesInstallIn64BitMode="${ISS_ARCH}"

[Files]
Source: "Sigil\*"; DestDir: "{app}"; Flags: createallsubdirs recursesubdirs ignoreversion
Source: vendor\vcredist2010.exe; DestDir: {tmp}
Source: vendor\vcredist2013.exe; DestDir: {tmp}

[Components]
; Main files cannot be unchecked. Doesn't do anything, just here for show
Name: main; Description: "Sigil"; Types: full compact custom; Flags: fixed
; Desktop icon.
Name: dicon; Description: "Create a desktop icon"; Types: full custom
Name: dicon\common; Description: "For all users"; Types: full custom; Flags: exclusive
Name: dicon\user; Description: "For the current user only"; Flags: exclusive
; File associations
Name: afiles; Description: "Associate ebook files with Sigil"
Name: afiles\epub; Description: "EPUB"

[Registry]
; Add Sigil as a global file handler for EPUB and HTML.
Root: HKLM; Subkey: "Software\Classes\.epub\OpenWithList\Sigil.exe"; Flags: uninsdeletekey
Root: HKLM; Subkey: "Software\Classes\.htm\OpenWithList\Sigil.exe"; Flags: uninsdeletekey
Root: HKLM; Subkey: "Software\Classes\.html\OpenWithList\Sigil.exe"; Flags: uninsdeletekey
Root: HKLM; Subkey: "Software\Classes\.xhtml\OpenWithList\Sigil.exe"; Flags: uninsdeletekey
; Associate EPUB files if requested.
Components: afiles\epub; Root: HKCR; Subkey: ".epub"; ValueType: string; ValueName: ""; ValueData: "SigilEPUB"; Flags: uninsdeletevalue uninsdeletekeyifempty
Components: afiles\epub; Root: HKCR; Subkey: "SigilEPUB"; ValueType: string; ValueName: ""; ValueData: "EPUB"; Flags: uninsdeletekey
Components: afiles\epub; Root: HKCR; Subkey: "SigilEPUB\DefaultIcon"; ValueType: string; ValueName: ""; ValueData: "{app}\Sigil.exe,0"; Flags: uninsdeletekey
Components: afiles\epub; Root: HKCR; Subkey: "SigilEPUB\shell\open\command"; ValueType: string; ValueName: ""; ValueData: """{app}\Sigil.exe"" ""%1"""; Flags: uninsdeletekey

[Icons]
Name: "{group}\Sigil"; Filename: "{app}\Sigil.exe"
Name: "{group}\Uninstall Sigil"; Filename: "{uninstallexe}"
; Optional desktop icon.
Components: dicon\common; Name: "{commondesktop}\Sigil"; Filename: "{app}\Sigil.exe"
Components: dicon\user; Name: "{userdesktop}\Sigil"; Filename: "{app}\Sigil.exe"

[InstallDelete]
; Restructuring done in 0.9.8 makes this folder residual.
Type: filesandordirs; Name: "{app}\python3"
; Might be moving to precompiled python files in future.
; and to keep install directory clean for future enhancement possibilities
Type: filesandordirs; Name: "{app}\plugin_launchers\python"
Type: filesandordirs; Name: "{app}\python3lib"
Type: filesandordirs; Name: "{app}\Lib"
Type: filesandordirs; Name: "{app}\DLLs"
Type: filesandordirs; Name: "{app}\Scripts"
; Moving to standard naming of python interpreter. 
; So remove the old name if present.
Type: files; Name: "{app}\sigil-python3.exe"

[UninstallDelete]
; Remove any compiled launcher folders/files created after installation
Type: filesandordirs; Name: "{app}\plugin_launchers\python"

[Run]
; The following command detects whether or not the c++ runtime need to be installed.
Filename: {tmp}\vcredist2010.exe; Check: NeedsVC2010redistInstall; Parameters: "/passive /Q:a /c:""msiexec /qb /i vcredist2010.msi"" "; StatusMsg: Checking for 2010 RunTime for Python...
Filename: {tmp}\vcredist2013.exe; Check: NeedsVC2013RedistInstall; Parameters: "/passive /Q:a /c:""msiexec /qb /i vcredist2013.msi"" "; StatusMsg: Checking for VS 2013 RunTime ...

[Code]

function IsWindowsVersion(Major, Minor: Integer): Boolean;
// Check the major and minor versions of Windows version numbers
var
  Version: TWindowsVersion;
begin
  GetWindowsVersionEx(Version);
  Result := ((Version.Major = Major) and (Version.Minor = Minor));
end;

function IsSPLevelOrMore(SPMajor: Integer): Boolean;
// Version agnostic Service Pack check
var
  Version: TWindowsVersion;
begin
  GetWindowsVersionEx(Version);
  Result := (Version.ServicePackMajor >= SPMajor);
end;


// Windows version checks
function IsWindows7: Boolean;
begin
  Result := IsWindowsVersion(6, 1);
end;

function IsWindowsVista: Boolean;
begin
  Result := IsWindowsVersion(6, 0);
end;

function IsWindowsXP: Boolean;
begin
  Result := IsWindowsVersion(5, 1);
end;


function CompareVersion(V1, V2: string): Integer;
// Compare version strings
// Returns 0, if the versions are equal.
// Returns -1, if the V1 is older than the V2.
// Returns 1, if the V1 is newer than the V2.
var
  P, N1, N2: Integer;
begin
  Result := 0;
  while (Result = 0) and ((V1 <> '') or (V2 <> '')) do
  begin
    P := Pos('.', V1);
    if P > 0 then
    begin
      N1 := StrToInt(Copy(V1, 1, P - 1));
      Delete(V1, 1, P);
    end
      else
    if V1 <> '' then
    begin
      N1 := StrToInt(V1);
      V1 := '';
    end
      else
    begin
      N1 := 0;
    end;

    P := Pos('.', V2);
    if P > 0 then
    begin
      N2 := StrToInt(Copy(V2, 1, P - 1));
      Delete(V2, 1, P);
    end
      else
    if V2 <> '' then
    begin
      N2 := StrToInt(V2);
      V2 := '';
    end
      else
    begin
      N2 := 0;
    end;

    if N1 < N2 then Result := -1
      else
    if N1 > N2 then Result := 1;
  end;
end;


function NeedsVC2015RedistInstall: Boolean;
// Return True if VC 2015 redist included
// with Sigil Installer needs to be run.
var
  reg_key, installed_ver, sigil_ver: String;
  R: Integer;
begin
  Result := True;
  // version of the VC++ Redistributable included with Sigil Installer
  sigil_ver := '14.0.24210';
  if IsWin64 and not Is64BitInstallMode then
    // 32-bit version being installed on 64-bit machine
    reg_key := 'SOFTWARE\WoW6432Node\Microsoft\DevDiv\vc\servicing\14.0\RuntimeMinimum'
  else
    reg_key := 'SOFTWARE\Microsoft\DevDiv\vc\servicing\14.0\RuntimeMinimum';

  if RegQueryStringValue(HKEY_LOCAL_MACHINE, reg_key, 'Version', installed_ver) then
  begin
     //MsgBox('Registry key: ' + reg_key, mbInformation, MB_OK);
     //MsgBox('Version: ' + installed_ver, mbInformation, MB_OK);
     R := CompareVersion(installed_ver, sigil_ver);
     // If installed VC++ 2015 runtime version is equal or newer than
     // the one included with the Sigil installer, then skip
     // executing the VC++ redistributable installer
     if R >= 0 then
       Result := False;
  end
end;

function NeedsVC2013RedistInstall: Boolean;
// Return True if VC 2013 redist included
// with Sigil Installer needs to be run.
var
  reg_key, installed_ver, sigil_ver: String;
  R: Integer;
begin
  Result := True;
  // version of the VC++ Redistributable included with Sigil Installer
  sigil_ver := '12.0.21005';
  if IsWin64 and not Is64BitInstallMode then
    // 32-bit version being installed on 64-bit machine
    reg_key := 'SOFTWARE\WoW6432Node\Microsoft\DevDiv\vc\servicing\12.0\RuntimeMinimum'
  else
    reg_key := 'SOFTWARE\Microsoft\DevDiv\vc\servicing\12.0\RuntimeMinimum';

  if RegQueryStringValue(HKEY_LOCAL_MACHINE, reg_key, 'Version', installed_ver) then
  begin
     //MsgBox('Registry key: ' + reg_key, mbInformation, MB_OK);
     //MsgBox('Version: ' + installed_ver, mbInformation, MB_OK);
     R := CompareVersion(installed_ver, sigil_ver);
     // If installed VC++ 2013 runtime version is equal or newer than
     // the one included with the Sigil installer, then skip
     // executing the VC++ redistributable installer
     if R >= 0 then
       Result := False;
  end
end;

function NeedsVC2010RedistInstall: Boolean;
// Return True if VC 2010 redist included
// with Sigil Installer needs to be run.
var
  reg_key, installed_ver, sigil_ver: String;
  R: Integer;
begin
  Result := True;
  // version of the VC++ Redistributable included with Sigil Installer
  sigil_ver := '40219.01';
  if IsWin64 and not Is64BitInstallMode then
    // 32-bit version being installed on 64-bit machine
    reg_key := 'SOFTWARE\WoW6432Node\Microsoft\DevDiv\vc\servicing\10.0\red\x86\1033'
  else
    if IsWin64 then
	  reg_key := 'SOFTWARE\Microsoft\DevDiv\vc\servicing\10.0\red\amd64\1033'
	else
      reg_key := 'SOFTWARE\Microsoft\DevDiv\vc\servicing\10.0\red\x86\1033';

  if RegQueryStringValue(HKEY_LOCAL_MACHINE, reg_key, 'Version', installed_ver) then
  begin
     //MsgBox('Registry key: ' + reg_key, mbInformation, MB_OK);
     //MsgBox('Version: ' + installed_ver, mbInformation, MB_OK);
     R := CompareVersion(installed_ver, sigil_ver);
     // If installed VC++ 2010 runtime version is equal or newer than
     // the one included with the Sigil installer, then skip
     // executing the VC++ redistributable installer
     if R >= 0 then
       Result := False;
  end
end;


function InitializeSetup(): Boolean;
// Make sure Windows XP is at least at SP3.
begin
  Result := True;

  if IsWindowsXP and not IsSPLevelOrMore(3) then
  begin
    MsgBox('The Sigil installer requires SP3 on this version of Windows.', mbCriticalError, MB_OK);
    Result := False;
  end;
end;
