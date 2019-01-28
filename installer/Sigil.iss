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
; Win XP is the lowest supported version
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
Filename: {tmp}\vcredist2010.exe; Check: NeedsVC2010RedistInstall; Parameters: "/passive /Q:a /c:""msiexec /qb /i vcredist2010.msi"" "; StatusMsg: Checking for 2010 RunTime for Python...
Filename: {tmp}\vcredist2013.exe; Check: NeedsVC2013RedistInstall; Parameters: "/passive /Q:a /c:""msiexec /qb /i vcredist2013.msi"" "; StatusMsg: Checking for VS 2013 RunTime ...

[Code]

function NeedsVC2010RedistInstall: Boolean;
// Return True if VS 2010 redist included with Sigil Installer needs to be run.
var
  reg_key, installed_ver: String;
begin
  Result := True;

  if IsWin64 and not Is64BitInstallMode then
    // 32-bit version being installed on 64-bit machine
    reg_key := 'SOFTWARE\WoW6432Node\Microsoft\DevDiv\vc\servicing\10.0\red\1033'
  else
    reg_key := 'SOFTWARE\Microsoft\DevDiv\vc\servicing\10.0\red\1033';

  // If there's a VS2010 compatible version of the runtime already installed; use it.
  if RegQueryStringValue(HKEY_LOCAL_MACHINE, reg_key, 'Version', installed_ver) then
    begin
      MsgBox('Installed version: ' + installed_ver, mbInformation, MB_OK);
      Result := False;
    end
 end;

function NeedsVC2013RedistInstall: Boolean;
// Return True if VS 2013 redist included with Sigil Installer needs to be run.
var
  reg_key, installed_ver: String;
begin
  Result := True;

  if IsWin64 and not Is64BitInstallMode then
    // 32-bit version being installed on 64-bit machine
    reg_key := 'SOFTWARE\WoW6432Node\Microsoft\DevDiv\vc\servicing\12.0\RuntimeMinimum'
  else
    reg_key := 'SOFTWARE\Microsoft\DevDiv\vc\servicing\12.0\RuntimeMinimum';

  // If there's a VS2013 compatible version of the runtime already installed; use it.
  if RegQueryStringValue(HKEY_LOCAL_MACHINE, reg_key, 'Version', installed_ver) then
    begin
      MsgBox('Installed version: ' + installed_ver, mbInformation, MB_OK);
      Result := False;
    end
 end;
