using System;
using System.Diagnostics;
using System.IO;
using System.Runtime.CompilerServices;
using Microsoft.Win32;

namespace Jackett.Updater
{
    internal static class WindowsInstalledAppMetadata
    {
        private const string UninstallKeyPath = @"SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{C2A9FC00-AA48-4F17-9A72-62FBCEE2785B}_is1";

        [ModuleInitializer]
        internal static void Initialize()
        {
            AppDomain.CurrentDomain.ProcessExit += (_, _) => TrySynchronizeDisplayVersion();
        }

        private static void TrySynchronizeDisplayVersion()
        {
            try
            {
                // The current updater executable runs from the extracted update directory,
                // so use Inno Setup's InstallLocation instead of the updater's own path.
                if (TrySynchronizeRegistryView(RegistryView.Registry64))
                    return;

                // Fallback for installations created by older 32-bit installer builds.
                TrySynchronizeRegistryView(RegistryView.Registry32);
            }
            catch (Exception ex)
            {
                // Registry metadata must never make an otherwise successful Jackett update fail.
                Program.logger?.Warn(ex, "Unable to synchronize the Windows installed-app version.");
            }
        }

        private static bool TrySynchronizeRegistryView(RegistryView view)
        {
            try
            {
                using var baseKey = RegistryKey.OpenBaseKey(RegistryHive.LocalMachine, view);
                using var uninstallKey = baseKey.OpenSubKey(UninstallKeyPath, writable: true);
                if (uninstallKey == null)
                    return false;

                var installLocation = uninstallKey.GetValue("InstallLocation") as string;
                if (string.IsNullOrWhiteSpace(installLocation))
                    return true;

                var consolePath = Path.Combine(installLocation, "JackettConsole.exe");
                if (!File.Exists(consolePath))
                    return true;

                var version = FileVersionInfo.GetVersionInfo(consolePath).FileVersion;
                if (string.IsNullOrWhiteSpace(version))
                    return true;

                var currentVersion = uninstallKey.GetValue("DisplayVersion") as string;
                if (!string.Equals(currentVersion, version, StringComparison.Ordinal))
                    uninstallKey.SetValue("DisplayVersion", version, RegistryValueKind.String);

                Program.logger?.Info($"Synchronized Windows installed-app DisplayVersion to {version}");
                return true;
            }
            catch (UnauthorizedAccessException)
            {
                return false;
            }
            catch (System.Security.SecurityException)
            {
                return false;
            }
        }
    }
}
