using Jackett.Common.Services.Interfaces;
using NLog;

namespace Jackett.Server.Services
{
    public class FilePermissionService : IFilePermissionService
    {
        private readonly Logger logger;

        public FilePermissionService(Logger l) => logger = l;

        public void MakeFileExecutable(string path)
        {
            // Windows does not use the Unix executable permission bit.
            // Keep the interface implementation as a no-op because the updater
            // shares this service contract with the upstream cross-platform code.
            logger.Debug($"Executable permission change is not required on Windows: {path}");
        }
    }
}
