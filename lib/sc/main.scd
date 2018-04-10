////////////////////////////
//// every once in a while i dont believe you II
////////////////////////////

(
Server.supernova;
s.options.threads = nil; // default to 1 per
s.options.memSize = 131072;
s.options.numOutputBusChannels = 8;
s.options.numInputBusChannels = 0;
)

(
var parent, sound;

parent = (); // an empty Dict
parent.thisDir = "~/Documents/jacob/pieces/eoiayidbyII".standardizePath; // this directory
parent.server = Server.default; // default server
parent.freeables = List.new(0); // an emtpy list for the freeables
parent.hrEnv = Env([0,1,1,0], [1, 50, 1].normalizeSum, \sine); // an almost rectangular envelope
parent.numSpeakers = 8;

parent.control = ();

parent.dream = ();
parent.dream.parent = parent; // cause it get weird
parent.dream.happened = false;
parent.dream.prevRem = false;
parent.dream.decide = File.include(parent.thisDir ++ "/lib/sc/funcs/decideDream.scd");
parent.dream.makeDream = File.include(parent.thisDir ++ "/lib/sc/funcs/makeDream.scd");
parent.dream.probabilities = File.include(parent.thisDir ++ "/lib/sc/funcs/loadDreamProbabilities.scd", parent); // get the probabilities

parent.sound = ();
sound = parent.sound;
sound.parent = parent; // because it gets weird
sound.stage1 = ();
sound.stage2 = ();
sound.stage3 = ();
sound.stage4 = ();
sound.stageREM = ();
sound.wake = ();
sound.kernelSize = 8192; // the size of the kernels
sound.ir = parent.thisDir ++ "/lib/sound/ir/BatteryBenson.wav"; // path to the IR
sound.irSize = 4096; // size for impulse response reverb

parent.analysisFile = parent.thisDir ++ "/data/n11/n11_analysis"; // path to the analysis file
parent.annotationFile = parent.thisDir ++ "/data/n11/n11_annotations"; // path to the annotations

File.include(parent.thisDir ++ "/lib/sc/funcs/makePitches.scd", parent); // get the pitches
File.include(parent.thisDir ++ "/lib/sc/funcs/cmdPeriod.scd", parent); // CmdPeriod to free stuff

parent.loadKernels = File.include(parent.thisDir ++ "/lib/sc/funcs/loadKernels.scd"); // make the function
parent.readAnalysis = File.include(parent.thisDir ++ "/lib/sc/funcs/readFiles.scd"); // make the function that starts reading the files

Routine.run({
  // boot server here and load everything
  parent.server.waitForBoot({
    File.include(parent.thisDir ++ "/lib/sc/synths.scd", parent); // load the synths
    parent.control.controlGroup = ParGroup.new(); // a new group at the head
    parent.control.brainBus = Bus.control(parent.server, 7);
    parent.control.normalizedBrainBus = Bus.control(parent.server, 7);
    parent.control.analysisBus = Bus.control(parent.server, 7);
    parent.control.heartBus = Bus.control(parent.server, 1);

    parent.freeables.addAll(
      [parent.control.controlGroup, parent.control.brainBus, parent.control.normalizedBrainBus, parent.control.analysisBus, parent.control.heartBus]
    );

    parent.makeStage = File.include(parent.thisDir ++ "/lib/sc/funcs/makeStage.scd"); // function to make sound
    parent.makeEnv = File.include(parent.thisDir ++ "/lib/sc/funcs/makeEnv.scd");
    parent.server.sync;

    // load the kernels
    ["stage1", "stage2", "stage3", "stage4", "stageREM"].do{|stage|
      parent.loadKernels(stage);
    };

    File.include(parent.thisDir ++ "/lib/sc/funcs/loadWake.scd", parent); // load the wake sounds
    File.include(parent.thisDir ++ "/lib/sc/funcs/loadBuffs.scd", parent); // load the wake sounds
    File.include(parent.thisDir ++ "/lib/sc/funcs/initSynths.scd", parent); // start the synths that are always on

    parent.server.sync;
    parent.readAnalysis; // start

    parent.server.sync;
    // parent.keysValuesDo{|key, item| "%::  %\n\n".postf(key, item)};
    // sound.keysValuesDo{|key, item|  "%::  %\n\n".postf(key, item)};
    a = sound;
    p = parent;
    b = parent.sound.buffs.hr;
  });

});

"~~~~ Starting every once in a while i dont believe you II~~~~~\n\n".post;

)

a.stage1.kernels[6].plot
a.stage1.kernels.size
a.parent
p
a.parent = p
a.parent.control
a
a.wake.buffers[0].numFrames
s.makeGui
s.meter
s.plotTree
s.quit

p.currentTask
