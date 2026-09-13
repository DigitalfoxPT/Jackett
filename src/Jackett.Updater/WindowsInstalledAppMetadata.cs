using System;
using System.Diagnostics;
using System.IO;
using System.Runtime.CompilerServices;
using Jackett.Common.Utils;
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
                var consolePath = Path.Combine(EnvironmentUtil.JackettInstallationPath(), "JackettConsole.exe");
                if (!File.Exists(consolePath))
                    return;

                var version = FileVersionInfo.GetVersionInfo(consolePath).FileVersion;
                if (string.IsNullOrWhiteSpace(version))
                    return;

                var updated = TryUpdateRegistryView(RegistryView.Registry64, version);
                updated |= TryUpdateRegistryView(RegistryView.Registry32, version);

                if (updated)
                    Program.logger?.Info($"Updated Windows installed-app DisplayVersion to {version}");
            }
            catch (Exception ex)
            {
                // Registry metadata must never make an otherwise successful Jackett update fail.
                Program.logger?.Warn(ex, "Unable to synchronize the Windows installed-app version.");
            }
        }

        private static bool TryUpdateRegistryView(RegistryView view, string version)
        {
            try
            {
                using var baseKey = RegistryKey.OpenBaseKey(RegistryHive.LocalMachine, view);
                using var uninstallKey = baseKey.OpenSubKey(UninstallKeyPath, writable: true);
                if (uninstallKey == null)
                    return false;

                var currentVersion = uninstallKey.GetValue("DisplayVersion") as string;
                if (!string.Equals(currentVersion, version, StringComparison.Ordinal))
                    uninstallKey.SetValue("DisplayVersion", version, RegistryValueKind.String);

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
