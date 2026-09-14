using System;
using System.IO;
using Autofac.Extensions.DependencyInjection;
using Jackett.Common.Models.Config;
using Jackett.Server;
using Microsoft.Extensions.Configuration;
using NUnit.Framework;

namespace Jackett.Test.Server
{
    [TestFixture]
    [NonParallelizable]
    public class HostBuilderTests
    {
        [Test]
        public void GenericHostBuildsWithAutofacAndRuntimeSettings()
        {
            var previousConfiguration = Program.Configuration;
            var settings = new RuntimeSettings
            {
                CustomDataFolder = Path.Combine(Path.GetTempPath(), Guid.NewGuid().ToString()),
                ClientOverride = "httpclient2",
                NoUpdates = true
            };
            try
            {
                Program.Configuration = new ConfigurationBuilder()
                    .AddInMemoryCollection(Program.GetValues(settings)).Build();
                using var host = Program.CreateWebHostBuilder(Array.Empty<string>(),
                    new[] { "http://127.0.0.1:0" }, TestContext.CurrentContext.TestDirectory).Build();
                Assert.That(host.Services.GetAutofacRoot(), Is.Not.Null);
                var resolvedSettings = (RuntimeSettings)host.Services.GetService(typeof(RuntimeSettings));
                Assert.That(resolvedSettings.CustomDataFolder, Is.EqualTo(settings.CustomDataFolder));
                Assert.That(resolvedSettings.NoUpdates, Is.True);
            }
            finally
            {
                Program.Configuration = previousConfiguration;
            }
        }
    }
}
