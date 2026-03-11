(
var dirtCode = "
s.reboot {
    s.options.outDevice = \"pipewire\";
    s.options.numBuffers = 1024 * 256;
    s.options.memSize = 8192 * 32;
    s.options.numWireBufs = 64;
    s.options.maxNodes = 1024 * 32;
    s.options.numOutputBusChannels = 2;
    s.options.numInputBusChannels = 2;

    s.waitForBoot {
        ~dirt = SuperDirt(2, s);

        // use an explicit sample path if you prefer:
        // ~dirt.loadSoundFiles(\"/home/artist/samples/Dirt-Samples/*\");
        ~dirt.loadSoundFiles;

        s.sync;
        ~dirt.start(57120);
        ~dirt.postSampleInfo;

        ~d1 = ~dirt.orbits[0];  ~d2 = ~dirt.orbits[1];
        ~d3 = ~dirt.orbits[2];  ~d4 = ~dirt.orbits[3];
        ~d5 = ~dirt.orbits[4];  ~d6 = ~dirt.orbits[5];
        ~d7 = ~dirt.orbits[6];  ~d8 = ~dirt.orbits[7];
        ~d9 = ~dirt.orbits[8];  ~d10 = ~dirt.orbits[9];
        ~d11 = ~dirt.orbits[10]; ~d12 = ~dirt.orbits[11];
    };

    s.latency = 0.3;
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
