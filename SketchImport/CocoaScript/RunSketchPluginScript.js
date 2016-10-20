// Usage:
// $ coscript RunSketchPluginScript.js "[Sketch plugin CocoaScript you'd like to run]"


var args = [[NSProcessInfo processInfo] arguments];
var scriptToRun_string;
if (args.length < 3) {
    scriptToRun_string = "[context.document displayMessage:\"SketchImport Plugin: Unspecified Plugin Script!\"]";
} else {
    scriptToRun_string = args[2];
}
log("[RunSketchPluginScript/run.js] Running script.");

var sketchAppIdentifier = @"com.bohemiancoding.sketch3";
var sketchAppBundlePath = [[NSWorkspace sharedWorkspace] absolutePathForAppBundleWithIdentifier:sketchAppIdentifier];
var sketchAppBundleInfo = [[NSBundle bundleWithPath:sketchAppBundlePath] infoDictionary];
if (!sketchAppBundleInfo) {
    log("[RunSketchPluginScript/run.js] Can't get bundle info for the Sketch app. Is Sketch installed?")
    exit(-1); // is this going to work?
}
var sketchAppVersion = sketchAppBundleInfo["CFBundleVersion"];
var sketchAppVersionString = sketchAppBundleInfo["CFBundleShortVersionString"]
log("[RunSketchPluginScript/run.js] Found Sketch.app v" 
                                                + sketchAppVersionString 
                                                + "(" 
                                                + sketchAppVersion 
                                                + ") at " 
                                                + sketchAppBundlePath);
log("[RunSketchPluginScript/run.js] Your script's output follows.")

// '-runPluginScript' only appears to work if run outside a function, like so:
var sketchApp = [COScript app:"Sketch"];
[[sketchApp delegate] runPluginScript:scriptToRun_string];
