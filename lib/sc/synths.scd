////////////////////////////
//// synths
////////////////////////////

{|parent|

  SynthDef(\heartbeat, {|outBus = 0, buff, amp = 0.2, rate = 60, env|
    var sig, ampEnv, trig, spd;
    // rate = LFNoise1.kr(0.1).range(rate*0.99, rate*1.1).lag2ud(1,2); // lag up a little quicker than below. Favor slighlty faster heartrate
    // rate = rate.lag2(2).reciprocal; // smooth it out and convert it to Hz
    spd = rate/60; // adjust the speed slightly to pitch up or down when the beat slows or speeds
    sig = GrainBuf.ar(1, Impulse.kr(spd), dur: BufDur.kr(buff), sndbuf: buff, rate: BufRateScale.kr(buff) * spd, interp: 4, envbufnum: env, maxGrains: 5);
    sig = LPF.ar(sig, 100); // low pass
    ampEnv = LFNoise2.kr(0.01).range(0,amp).lag3ud(30, 40); // fade in and out
    sig = LeakDC.ar(sig*ampEnv);
    sig = PanAz.ar(parent.numSpeakers, sig, LFNoise1.kr(0.01), width: 4);
    Out.ar(outBus, sig); // send it out
  }).send(parent.server);

  SynthDef(\analysisReader, {|vals = #[0,0,0,0,0,0,0], brainBus, normalizedBrainBus|
    var normalized, raw;
    raw = vals.lag3(2); // lag by 2 seconds
    normalized = raw.collect{|val| RunningRange.kr(val, resetHi: Dust.kr(0.00001), resetLow: Dust.kr(0.00001))}; // normalize the values, resetting the min and max occasionally
    Out.kr(brainBus, raw);
    Out.kr(normalizedBrainBus, normalized);
  }).send(parent.server);

  SynthDef(\stageSegment, {|outBus = 0, kernel, kernel2, freq = 100, amp = 1, pos = 0, gate = 1, brainBus, normalizedBrainBus, kernelUpdate = 0, qFac = 1|
    var sig, crossfade, env, q, qMod, rq, posBus, posMod, osc, brainAmp, oscIdxs, conv1, conv2;

    brainBus = In.kr(brainBus, 7);
    normalizedBrainBus = In.kr(normalizedBrainBus, 7);

    // the envelope (passed in)
    env = Env.newClear(8); // an empty envelope
    env = \env.kr(env.asArray); // make it an array
    env = EnvGen.kr(env, gate, levelScale: amp, doneAction: 14); // free this synth and the whole group when we're done

    // get two sets of signals the same size as numSpeakers
    // this allows us to have decorrelated signals out of each speaker! At the expense of more processing...
    conv1 = parent.numSpeakers.collect{
      Convolution2.ar(PinkNoise.ar(1), kernel, trigger: kernelUpdate, framesize: parent.sound.kernelSize);
    };
    conv2 = parent.numSpeakers.collect{
      Convolution2.ar(PinkNoise.ar(1), kernel2, trigger: kernelUpdate, framesize: parent.sound.kernelSize);
    };
    sig = XFade2.ar(conv1, conv2, LFNoise1.kr(45.reciprocal), level: 0.707); // fade between the two different signals since Convolution2L glitches

    // calculate frequency
    freq = freq * RunningRange.kr(brainBus[3]+brainBus[5]).linlin(0,1,0.95,1.05); // let it warble
    freq = freq.lag3(10); // smooth it out

    // width of the filter
    qMod = (brainBus[0] + brainBus[1]) * brainBus[5]; // a value
    rq = RunningRange.kr(qMod).linlin(0,1,5,20).lag3(5); // bandwidth between 2 and 100 Hz
    rq = (rq * qFac).max(2); // constrain the Q according to the stage
    q = rq/freq; // get the real q

    // calculate the positions
    posMod = TChoose.kr(1, brainBus) * TChoose.kr(1, brainBus); // get a product
    pos = posMod.linlin(RunningMin.kr(posMod), RunningMax.kr(posMod), pos*0.5, pos*1.5); // make a range
    pos = NaNFilter.kr(pos, Rand(-1,1));
    pos = CircleRamp.kr([pos, pos-1], lagTime: 1, circmin: -1, circmax: 1); // make two positions opposite one another
    pos = PanAz.kr(parent.numSpeakers, DC.kr(1), pos, width: 3).lag3(30); // get the gains for each channel

    // oscillators. Clips????
    // osc = SinOsc.ar([freq, freq*2.02], mul: [amp*0.000001, amp*0.000005]) * RunningRange.kr(brainBus.choose).linexp(0,1,0.01,1).lag3(IRand(10,20)); // some sine tones
    // osc = Mix(osc) * 0.000000000001; // have to make them really really quiet; otherwise they clip??
    // osc = PanAz.ar(parent.numSpeakers, osc, [pos + Rand(-0.5,0.5), (pos + Rand(-0.5,0.5) - 1).abs], width: 2.5); // need to check this
    // osc = osc.collect{|sine| DelayN.ar(sine, 0.1, Rand(0,0.1))}; // random delays on each channel

    sig = Resonz.ar([sig, sig], [freq, freq*2.01], q, mul: [1, 1*0.50118723]); // filter the signal
    sig = Mix(sig); // mix it down from two 8-channel arrays to a single 8 channel array
    sig = Mix([sig*pos[0], sig*pos[1]]); // multiply by the gains in the spatializer
    // sig = Mix([sig, osc]); // mix them down
    sig = HPF.ar(LeakDC.ar(sig), 20, mul: 2);

    brainAmp =  RunningRange.kr(normalizedBrainBus[0]+normalizedBrainBus[1]).linlin(0,1,0.70794,1).lag3(IRand(15,30)); // modulate the amplitude
    sig = Normalizer.ar(sig, 0.1777, 0.2) * brainAmp; // normalize to -15dB and modulate by amp
    Out.ar(outBus, sig * env); // send it out
  }).send(parent.server);

  // just play back a file (for WAKE)
  SynthDef(\playFile, {|outBus = 0, buff, amp = 1, gate = 1|
    var sig, env;
    sig = PlayBuf.ar(2, buff, BufRateScale.kr(buff), loop: 1); // play the file
    // sig = VDiskIn.ar(2, buff, BufRateScale.kr(buff), loop: 1); // play the file from disk (make it's length a factor of the buffer size)
    sig = SplayAz.ar(parent.numSpeakers, sig, spread: 1, width: 4, levelComp: true); // distribute it
    env = Env.newClear(8);
    env = \env.kr(env.asArray);
    env = EnvGen.kr(env, gate, levelScale: amp, doneAction: 2);
    // sig = sig*env;
    Out.ar(outBus, sig*env);
  }).send(parent.server);

  SynthDef(\playFile_decorrelate, {|outBus = 0, buff, amp = 1, gate = 1, startFrames = #[0,0,0,0,0,0,0,0]|
    var sig, env;
    // sig = PlayBuf.ar(2, buff, BufRateScale.kr(buff), loop: 1); // play the file
    // sig = VDiskIn.ar(2, buff, BufRateScale.kr(buff), loop: 1); // play the file from disk (make it's length a factor of the buffer size)
    // sig = SplayAz.ar(parent.numSpeakers, sig, spread: 1, width: 4, levelComp: true); // distribute it
    sig = parent.numSpeakers.collect{|i|
      var sig;
      sig = PlayBuf.ar(2, buff, BufRateScale.kr(buff), loop: 1, startPos: startFrames[i]);
      Select.ar(IRand(0,1), sig);
    };
    // sig.poll;
    env = Env.newClear(8);
    env = \env.kr(env.asArray);
    env = EnvGen.kr(env, gate, levelScale: amp, doneAction: 14);
    sig = sig*env;
    Out.ar(outBus, sig*env);
  }).send(parent.server);

  // synth that makes us dream
  SynthDef(\dream, {|outBus = 0, buff, dur = 10, revBuffs = #[0,0], normalizedBrainBus, amp = 0.2|
    var sig, rev, del, rate, env, brainAmp, fb, fbLevel, initDel, leakSig, mix, delTime;

    initDel = 0.01; // initial delay for the reverb
    normalizedBrainBus = In.kr(normalizedBrainBus, 7);

    env = EnvGen.kr(
      Env([0,1,1,0], [2.5, 5, 2.5].normalizeSum, \sine),
      levelScale: amp,
      timeScale: dur,
      doneAction: 14
    );

    rate = normalizedBrainBus[3].linlin(0,1,0.8,1).lag3(20); // get a rate controlled by sigma
    brainAmp = normalizedBrainBus[0].linexp(0,1,0.707,1).lag3ud(20,30);
    delTime = normalizedBrainBus[4].linlin(0,1,0.1,1.2).lag3(15);
    fbLevel = (normalizedBrainBus[2]+normalizedBrainBus[3]).linlin(0,2,0.8,0.1).lag3(20);
    mix = RunningRange.kr((normalizedBrainBus[5]*2) + normalizedBrainBus[0]).linlin(0,1,-1,0.3).lag3(20);

    // sig = PlayBuf.ar(2, buff, BufRateScale.kr(buff) * rate, loop: 1);
    sig = VDiskIn.ar(2, buff, BufRateScale.kr(buff) * rate, loop: 1); // read from disk
    fb = LocalIn.ar(2, 0) * fbLevel; // feedback from the delay
    sig = sig+fb; // sum it
    del = DelayC.ar(sig, 1.5, delTime); // delay
    LocalOut.ar(sig+del); // send it all back
    sig = SplayAz.ar(parent.numSpeakers, sig, width: 3); // spatialize it

    rev = DelayN.ar(sig, (initDel+Rand(0.0,0.001) ! 16), initDel+0.001); // initial delay
    leakSig = Mix(rev)*0.001; // a little bit of everything for each channel, regardless of position
    rev = [
      PartConv.ar(rev[0]+leakSig, parent.sound.irSize, revBuffs[0], 0.707),
      PartConv.ar(rev[1]+leakSig, parent.sound.irSize, revBuffs[1], 0.707),
      PartConv.ar(rev[2]+leakSig, parent.sound.irSize, revBuffs[0], 0.707),
      PartConv.ar(rev[3]+leakSig, parent.sound.irSize, revBuffs[1], 0.707),
      PartConv.ar(rev[4]+leakSig, parent.sound.irSize, revBuffs[0], 0.707),
      PartConv.ar(rev[5]+leakSig, parent.sound.irSize, revBuffs[1], 0.707),
      PartConv.ar(rev[6]+leakSig, parent.sound.irSize, revBuffs[0], 0.707),
      PartConv.ar(rev[7]+leakSig, parent.sound.irSize, revBuffs[1], 0.707)
    ];

    rev = HPF.ar(rev, 200); // highpass
    rev = CompanderD.ar(rev, 0.707, 1, 0.666); // compress it just to be safe
    sig = XFade2.ar(sig, rev*0.17782, mix); // mix wet and dry
    sig = LeakDC.ar(sig); // make sure we're cool
    Out.ar(outBus, sig*env*brainAmp); // send it out
  }).send(parent.server);

}
