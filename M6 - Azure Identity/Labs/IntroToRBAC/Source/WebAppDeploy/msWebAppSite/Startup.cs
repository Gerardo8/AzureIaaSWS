using Microsoft.Owin;
using Owin;

[assembly: OwinStartupAttribute(typeof(msWebAppSite.Startup))]
namespace msWebAppSite
{
    public partial class Startup
    {
        public void Configuration(IAppBuilder app)
        {
            ConfigureAuth(app);
        }
    }
}
