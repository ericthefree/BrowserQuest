({
    appDir: "../",
    baseUrl: "js/",
    dir: "../../client-build",
    optimize: "uglify",
    optimizeCss: "standard.keepLines",
    
    paths: {
        "jquery": "lib/jquery"
    },

    modules: [
        //Optimize jquery.js by applying any minification
        //that is desired via the optimize: setting above.
        {
            name: "jquery"
        },
        
        {
            name: "game",
            exclude: ["jquery"]
        },
         
        {
            name: "home",
            // Exclude the jquery module since it is included already in require-jquery.js
            exclude: ["jquery", "game"]
        }
    ],
    
    pragmas: {
        devHost: false,
        prodHost: true
    }
})