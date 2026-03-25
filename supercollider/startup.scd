(
var dirtCode = "
s.reboot {
    s.options.outDevice = \"pipewire\";
    s.options.numBuffers = 1024 * 16;
    s.options.memSize = 8192 * 32;
    s.options.numWireBufs = 128;
    s.options.blockSize = 64;
    s.options.maxNodes = 1024 * 4;
    s.options.numOutputBusChannels = 2;
    s.options.numInputBusChannels = 2;

    s.waitForBoot {
        ~dirt = SuperDirt(2, s);

        // use an explicit sample path if you prefer:
        // ~dirt.loadSoundFiles(\"/home/artist/samples/Dirt-Samples/*\");
        ~dirt.loadSoundFiles;

        s.sync;
        ~dirt.start(57120);
        s.latency = 0.3;
        if(thisProcess.argv.includes(\"--verbose\")) { ~dirt.postSampleInfo };

        ~d1 = ~dirt.orbits[0];  ~d2 = ~dirt.orbits[1];
    };

};
";

if(Quarks.isInstalled("SuperDirt").not) {
    "SuperDirt not installed. Installing...".postln;

    // Ensure SC user directories and config file exist (NixOS doesn't create them)
    File.mkdir(Platform.userAppSupportDir);
    File.mkdir(Platform.userAppSupportDir +/+ "downloaded-quarks");
    File.mkdir(Platform.userExtensionDir);

    // sclang needs a config file for Quarks to record include paths.
    // On NixOS LanguageConfig.currentPath is nil unless one exists.
    if(LanguageConfig.currentPath.isNil) {
        var confPath = Platform.userConfigDir +/+ "sclang_conf.yaml";
        File.mkdir(Platform.userConfigDir);
        File.use(confPath, "w", { |f| f.write("includePaths: []\nexcludePaths: []\npostInlineWarnings: false\n") });
        LanguageConfig.store(confPath);
    };

    Quarks.checkForUpdates({
        Quarks.install("SuperDirt", "v1.7.4");
        "SuperDirt installed. Recompiling class library now.".postln;
        thisProcess.recompile;
        "Restart sclang once after this.".postln;
    });
} {
    dirtCode.interpret;
};
)
