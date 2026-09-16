
define(['text!../config/config_build.json'],
function(build) {
    var runtime = window.BROWSERQUEST_SERVER || {},
        pagePort = window.location.port ? parseInt(window.location.port, 10) : null;

    var config = {
        dev: {
            host: runtime.host || window.location.hostname || "localhost",
            port: runtime.port !== undefined ? runtime.port : pagePort,
            secure: runtime.secure !== undefined ? runtime.secure : window.location.protocol === "https:",
            dispatcher: false
        },
        build: JSON.parse(build)
    };
    
    //>>excludeStart("prodHost", pragmas.prodHost);
    require(['text!../config/config_local.json'], function(local) {
        try {
            config.local = JSON.parse(local);
        } catch(e) {
            // Exception triggered when config_local.json does not exist. Nothing to do here.
        }
    });
    //>>excludeEnd("prodHost");
    
    return config;
});
