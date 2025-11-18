using Jellyfin.Plugin.MediaBar.Configuration;
using MediaBrowser.Common.Configuration;
using MediaBrowser.Common.Plugins;
using MediaBrowser.Model.Plugins;
using MediaBrowser.Model.Serialization;

namespace Jellyfin.Plugin.MediaBar
{
    public class MediaBarPlugin : BasePlugin<PluginConfiguration>, IHasPluginConfiguration, IHasWebPages
    {
        // Changed GUID to avoid conflict with original plugin
        public override Guid Id => Guid.Parse("a8b4c5d6-3210-4f04-89cc-fe9876543210");

        public override string Name => "Media Bar (Performance)";

        public static MediaBarPlugin Instance { get; private set; } = null!;
        
        public IServiceProvider ServiceProvider { get; }
        
        public MediaBarPlugin(IApplicationPaths applicationPaths, IXmlSerializer xmlSerializer, IServiceProvider serviceProvider) : base(applicationPaths, xmlSerializer)
        {
            Instance = this;
            
            ServiceProvider = serviceProvider;
        }
        
        public IEnumerable<PluginPageInfo> GetPages()
        {
            string? prefix = GetType().Namespace;

            yield return new PluginPageInfo
            {
                Name = Name,
                EmbeddedResourcePath = $"{prefix}.Configuration.config.html"
            };
        }
    }
}