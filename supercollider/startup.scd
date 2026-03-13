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
        if(thisProcess.argv.includes("--verbose")) { ~dirt.postSampleInfo };

        ~d1 = ~dirt.orbits[0];  ~d2 = ~dirt.orbits[1];
    };

};
";

if(Quarks.isInstalled("SuperDirt").not) {
    "SuperDirt not installed. Installing...".postln;
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
