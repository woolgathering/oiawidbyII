/////////////////////////////////
// make sound for a stage
////////////////////////////////

{|parent, stageName, annotationIdx|

  var sound, group, transpositions, pitches, convertStageName, synths, stageSymbol, fundamental, annotations, bag, qFac, amp;

  sound = parent.sound; // make life easier
  group = ParGroup.after(parent.control.controlGroup); // put a group after all the busses and whatnot
  convertStageName = {|name|
    var symbol;
    switch (name)
      {"SLEEP-S0"} {symbol = \wake}
      {"SLEEP-S1"} {symbol = \stage1}
      {"SLEEP-S2"} {symbol = \stage2}
      {"SLEEP-S3"} {symbol = \stage3}
      {"SLEEP-S4"} {symbol = \stage4}
      {"SLEEP-REM"} {symbol = \stageREM};
    symbol; // return
  };
  stageSymbol = convertStageName.(stageName); // convert the stage name into a usable form
  pitches = sound.at(stageSymbol).pitches; // get the correct pitches for this stage
  // fundamental = parent.control.fundamentalPattern.next; // using a pattern, get a fundamental
  fundamental = 200; // fixed for now
  annotations = parent.annotations;

  "% ------------------------------------------ % seconds long\n".postf(stageName, annotations[annotationIdx][1]); // print the stage name

  ////////////////////////////////////////////////////////
  // if the stage is WAKE
  ////////////////////////////////////////////////////////
  if (stageName == "SLEEP-S0") {
    var env, buff, startFrames;
    "WOKE UP --------------------------".postln;
    env = parent.makeEnv(annotationIdx); // make an envelope
    buff = sound.wake.buffers.choose; // pick a buffer to read from
    // better to use a decorrelated sources for the WAKE stages???? Would need to listen to them very carefully
    parent.dream.happened = false; // now we can select a new dream
    parent.dream.prevRem = false; // for checking if we've had REM before. Resets here.
    startFrames = parent.numSpeakers.collect{|i|
      rrand(0, buff.numFrames);
    };

    // play sound
    Synth(\playFile_decorrelate,
      [outBus: 0, buff: buff, amp: -12.dbamp, gate: 1, env: env, startFrames: startFrames],
      target: group
    );
  };

  ////////////////////////////////////////////////////////
  // if it's not WAKE
  ////////////////////////////////////////////////////////
  if (stageName != "SLEEP-S0") {

    // no transpositions for WAKE
    switch (stageName)
      {"SLEEP-S1"} {
        transpositions = [1, 2, 2, 2, 4, 4];
        qFac = 1;
        amp = -9.dbamp;
      }
      {"SLEEP-S2"} {
        transpositions = [1, 2, 2, 4];
        qFac = 0.66;
        amp = -7.dbamp;
      }
      {"SLEEP-S3"} {
        transpositions = [1, 2, 2];
        qFac = 0.5;
        amp = -5.dbamp;
      }
      {"SLEEP-S4"} {
        transpositions = [1, 1, 1.5, 2];
        qFac = 0.333;
        amp = -3.dbamp;
      }
      {"SLEEP-REM"} {
        transpositions = [1, 2, 2, 4];
        qFac = 0.2;
        amp = -7.dbamp;
        parent.dream.prevRem = true;
      };

    bag = Bag.new(); // a Bag of pitches
    pitches = pitches.collect{|fac| bag.add(fac)};
    pitches = bag;

    // actually choose the pitches, make the synths, and play them
    synths = 4.collect{|i|
      // something here with Bag to select pitches
      var pitch, env, kernel, pos;
      pitch = pitches.choose; // choose a pitch at random
      pitches.remove(pitch); // remove that pitch from our possible selection
      pitch = pitch * fundamental; // make it into an actual frequency
      pitch = pitch * transpositions.choose; // transpose it
      env = parent.makeEnv(annotationIdx); // get a unique envelope
      kernel = 2.collect{sound.at(stageSymbol).kernels.choose}; // pick a kernel
      pos = (i-1)*0.5; // get a position
      // "NOT WAKING~~~~~~~~~~~~~~~~~GOT HERE\n".postln;
      "\tpitch: %\n\tenv: %\n\tkernel:%\n\tpos: %\n\n".postf(pitch, env, kernel, pos);
      // defer {env.plot};

      // make a Synth
      Synth(\stageSegment,
        [outBus: 0, kernel: kernel[0], kernel2: kernel[1], freq: pitch, amp: amp, pos: pos, gate: 1, brainBus: parent.control.brainBus, normalizedBrainBus: parent.control.normalizedBrainBus, env: env, qFac: qFac],
        target: group, addAction: \addToTail
      );
    };

    // a Task that periodically changes the kernels
    // this also gives 25% of the same kernels as the last stage for the first 1/3 of the duration of the stage, gradually falling to 0 by 1/3.
    // this also selects whether or not we'll dream.
    parent.currentTask = Task({
      var lastStage, prob, dur, probDur, firstPass;

      try {
        lastStage = annotations[annotationIdx-1][0]; // get the last stage. Throws an error if it doesn't exist
        lastStage = convertStageName.(lastStage); // convert it to an appropriate symbol
        prob = [25,100]; // 25% probability if the kernal being from the last stage
        dur = annotations[annotationIdx-1][1].asInteger; // get the duration in seconds
        probDur = (dur/3)/25; // get the incremement in time of 1% of 1/3 of the duration change in prob
        firstPass = true; // this will be the first pass through the dream loop

        ////////////////////////////////////////////////////////////////////////////////
        // independent loop for calculating probability of previous stage kernel being selected
        ////////////////////////////////////////////////////////////////////////////////
        fork {
          loop {
            probDur.wait; // go by the increment in time of 1% of 1/3 of this duration
            // if we still have a change of selecting a kernel from the previous
            if (prob[0] > 0) {
              prob = [prob[0]-1, prob[1]+1]; // adjust one percent at a time
            };
          };
        };

        ////////////////////////////////////////////////////////////////////////////////
        // change the kernals periodically of a random synth
        ////////////////////////////////////////////////////////////////////////////////
        fork {
          loop {
            var thisSynth, kernels;
            (rrand(1,20)*5).wait; // wait a bit in increments of 5s
            thisSynth = synths.choose; // pick a new synth to change the kernel of
            kernels = [sound.at(lastStage).kernels, sound.at(stageSymbol).kernels].wchoose(prob.normalizeSum); // choose a set of kernels according to prob
            thisSynth.set([\kernel, \kernal2].choose, kernels.choose); // pick a new kernel for this synth
            thisSynth.set(\kernelUpdate, 1); // tell it to update
            0.1.wait;
            thisSynth.set(\kernelUpdate, 0); // reset it
          };
        };

        // loop where we decide if we dream or not. And we wait between them, perhaps returning to dream after we're done
        fork {
          parent.dream.makeDream(120);
          loop {
            // dream
            var dreamDur;
            // wait 20% of the duration before deciding whether or not we will dream on the first time through
            if (firstPass) {(dur*0.2).wait; firstPass = false};
            dreamDur = parent.dream.decide(stageSymbol, annotationIdx); // decide whether or not we'll dream and return the duration until the next time we check (dream or not)
            (dreamDur*rrand(0.9,1.2)).wait; // wait before we check again
          };
        };

      } {|error|
        // if it throws an error, we're at the beginning of the piece (i.e. first stage)
        // same thing with NO PROB
        error.warn;
        "NOT AN ERROR! Piece has begun... If you didn't just start the piece, it's a real error.".postln;
        loop {
          // change the kernals periodically of a random synth
          var thisSynth;
          (rrand(1,20)*5).wait; // wait a bit in increments of 5s
          thisSynth = synths.choose; // pick a new synth to change the kernel of
          thisSynth.set(\kernel, sound.at(stageSymbol).kernels.choose); // pick a new kernel
          thisSynth.set(\kernelUpdate, 1); // tell it to update
          0.1.wait;
          thisSynth.set(\kernelUpdate, 0); // reset it
        };
      };
    }).play;


  };


  sound.lastGroup = group; // remember this group
}
