#define MyAppName "Jackett"
#define MyAppPublisher "DigitalfoxPT"
#define MyAppURL "https://github.com/DigitalfoxPT/Jackett"
#define MyAppExeName "JackettConsole.exe"
#define MyAppWebUI "http://127.0.0.1:9117/UI/Dashboard"

[Setup]
AppId={{C2A9FC00-AA48-4F17-9A72-62FBCEE2785B}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={commonappdata}\{#MyAppName}
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
OutputBaseFilename={#MyOutputFilename}
SetupIconFile=src\Jackett.Server\jackett.ico
UninstallDisplayIcon={commonappdata}\Jackett\{#MyAppExeName}
VersionInfoVersion={#MyAppVersion}
UninstallDisplayName={#MyAppName}
Compression=lzma2
SolidCompression=yes
DisableDirPage=yes
WizardStyle=modern
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
PrivilegesRequired=admin

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Dirs]
Name: "{commonappdata}\Jackett"; Permissions: everyone-modify

[Files]
Source: "{#MySourceFolder}\*"; DestDir: "{commonappdata}\Jackett"; Flags: ignoreversion recursesubdirs createallsubdirs; Permissions: everyone-modify

[Icons]
Name: "{group}\{#MyAppName} Web UI"; Filename: "{#MyAppWebUI}"; IconFilename: "{commonappdata}\Jackett\{#MyAppExeName}"; IconIndex: 0
Name: "{group}\{cm:UninstallProgram,{#MyAppName}}"; Filename: "{uninstallexe}"
Name: "{commondesktop}\{#MyAppName}"; Filename: "{#MyAppWebUI}"; IconFilename: "{commonappdata}\Jackett\{#MyAppExeName}"; IconIndex: 0; Tasks: desktopicon

[Code]
function PrepareToInstall(var NeedsRestart: Boolean): String;
var
  ErrorCode: Integer;
begin
  ShellExec('open', 'taskkill.exe', '/f /im JackettConsole.exe', '', SW_HIDE, ewNoWait, ErrorCode);
  ShellExec('open', 'taskkill.exe', '/f /im JackettService.exe', '', SW_HIDE, ewNoWait, ErrorCode);
end;

[Run]
Filename: "{commonappdata}\Jackett\JackettConsole.exe"; Parameters: "--Uninstall"; Flags: waituntilterminated runhidden;
Filename: "{commonappdata}\Jackett\JackettConsole.exe"; Parameters: "--ReserveUrls"; Flags: waituntilterminated runhidden;
Filename: "{commonappdata}\Jackett\JackettConsole.exe"; Parameters: "--Install"; Flags: waituntilterminated runhidden;
Filename: "{commonappdata}\Jackett\JackettConsole.exe"; Parameters: "--Start"; Flags: waituntilterminated runhidden;
Filename: "{#MyAppWebUI}"; Description: "Open {#MyAppName} Web UI"; Flags: shellexec nowait postinstall skipifsilent;

[UninstallRun]
Filename: "{commonappdata}\Jackett\JackettConsole.exe"; Parameters: "--Uninstall"; Flags: waituntilterminated skipifdoesntexist runhidden;
Filename: "{sys}\taskkill.exe"; Parameters: "/f /im JackettConsole.exe"; Flags: waituntilterminated skipifdoesntexist runhidden;
Filename: "{sys}\taskkill.exe"; Parameters: "/f /im JackettService.exe"; Flags: waituntilterminated skipifdoesntexist runhidden;
