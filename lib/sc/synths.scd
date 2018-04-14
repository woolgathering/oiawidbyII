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
    ampEnv = LFDNoise3.kr(300.reciprocal).range(0.5*amp,amp).lag3ud(30, 40) * LFDNoise3.kr(240.reciprocal).range(0,1); // fade in and out
    sig = LeakDC.ar(sig*ampEnv);
    sig = PanAz.ar(parent.numSpeakers, sig, LFDNoise1.kr(0.01), width: 4);
    Out.ar(outBus, sig); // send it out
  }).send(parent.server);

  SynthDef(\analysisReader, {|vals = #[0,0,0,0,0,0,0], brainBus, normalizedBrainBus|
    var normalized, raw;
    raw = vals.lag3(2); // lag by 2 seconds
    normalized = raw.collect{|val| RunningRange.kr(val, resetHi: Dust.kr(0.00001), resetLow: Dust.kr(0.00001))}; // normalize the values, resetting the min and max occasionally
    Out.kr(brainBus, raw);
    Out.kr(normalizedBrainBus, normalized);
  }).send(parent.server);

  SynthDef(\stageSegment, {|outBus = 0, kernel, kernel2, freq = 100, amp = 1, pos = 0, gate = 1, brainBus, normalizedBrainBus, kernelUpdate = 0, qFac = 1, dreamDur = 10, dreamTrig = 0|
    var sig, crossfade, env, q, qMod, rq, freqMod, posBus, posMod, osc, brainAmp, brainMod, oscIdxs, conv1, conv2, dreamEnv;

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
    sig = XFade2.ar(conv1, conv2, LFDNoise1.kr(45.reciprocal), level: 0.707); // fade between the two different signals since Convolution2L glitches

    // calculate frequency
    freqMod = TChoose.kr(1, brainBus) + TChoose.kr(1, brainBus);
    freq = freq * RunningRange.kr(freqMod*2, resetHi: Dust.kr(0.001), resetLow: Dust.kr(0.001)).linlin(0,2,0.91,1.09); // let it warble
    freq = freq.lag3(15); // smooth it out

    // width of the filter
    qMod = (brainBus[0] + brainBus[1]) * brainBus[5]; // a value
    rq = RunningRange.kr(qMod, resetHi: Dust.kr(0.001), resetLow: Dust.kr(0.001)).linlin(0,1,5,20).lag3(IRand(5,10)); // bandwidth between 2 and 100 Hz
    rq = (rq * qFac).max(2); // constrain the Q according to the stage
    q = rq/freq; // get the real q

    // calculate the positions
    posMod = TChoose.kr(1, brainBus) * TChoose.kr(1, brainBus); // get a product
    pos = posMod.linlin(RunningMin.kr(posMod), RunningMax.kr(posMod), pos*0.5, pos*1.5); // make a range
    pos = NaNFilter.kr(pos, Rand(-1,1));
    pos = CircleRamp.kr([pos, pos-1], lagTime: 1, circmin: -1, circmax: 1); // make two positions opposite one another
    pos = PanAz.kr(parent.numSpeakers, DC.kr(1), pos, width: 2.5).lag3(30); // get the gains for each channel

    // oscillators. Clips????
    osc = SinOsc.ar([freq * 0.49, freq, freq*2.02], phase: [Rand(0.2pi), Rand(0.2pi), Rand(0,2pi)],  mul: [amp*0.008, amp*0.01, amp*0.005]); // some sine tones
    osc = Mix(osc) * 0.0002; // have to make them really really quiet; otherwise they clip??
    osc = Mix([PanAz.ar(parent.numSpeakers, osc, pos[0], width: 2.5), PanAz.ar(parent.numSpeakers, osc, pos[1], width: 2.5)]); // need to check this
    // osc = osc.collect{|sine| DelayN.ar(sine, 0.1, Rand(0,0.1))}; // random delays on each channel

    sig = Resonz.ar([sig, sig], [freq, freq*2.01], q, mul: [1, 1*0.50118723]); // filter the signal
    sig = Mix(sig); // mix it down from two 8-channel arrays to a single 8 channel array
    sig = Mix([sig*pos[0], sig*pos[1]]); // multiply by the gains in the spatializer
    // sig = Mix([sig, osc]); // mix them down

    sig = XFade2.ar(sig, osc,
      RunningRange.kr(brainBus[5]*brainBus[1], Dust.kr(0.001), Dust.kr(0.001).linlin(0,1,-0.1,-1)).lag3(Rand(50,70));
    );

    brainMod = TChoose.kr(1,brainBus) + TChoose.kr(1,brainBus);
    brainAmp =  RunningRange.kr(brainMod, resetHi: Dust.kr(0.001), resetLow: Dust.kr(0.001)).linlin(0,1,0.630,1).lag3(IRand(15,30)); // modulate the amplitude
    sig = HPF.ar(LeakDC.ar(sig), 20, mul: brainAmp); // filter and multiply
    sig = Normalizer.ar(sig, 0.1777, 0.2); // normalize to -15dB
    Out.ar(outBus, sig * env * 0.06309); // reduce by -24dB since there are four of these and send it out
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
    sig = HPF.ar(LeakDC.ar(sig), 50);
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

    rate = normalizedBrainBus[3].lag3(90).linlin(0,1,0.75,0.92); // get a rate controlled by sigma
    brainAmp = normalizedBrainBus[0].linexp(0,1,0.707,1).lag3ud(20,30);
    delTime = normalizedBrainBus[4].linlin(0,1,0.8,1).lag3(15);
    fbLevel = (normalizedBrainBus[2]+normalizedBrainBus[3]).linlin(0,2,0.8,0.5);
    mix = RunningRange.kr((normalizedBrainBus[5]*2) + normalizedBrainBus[0]).linlin(0,1,-0.3,0.9).lag3(20);

    // sig = PlayBuf.ar(2, buff, BufRateScale.kr(buff) * rate, loop: 1);
    sig = VDiskIn.ar(2, buff, rate, loop: 1); // read from disk
    // sig = PitchShift.ar(sig, pitchRatio: LFNoise2.kr(0.2).range(0.7,0.9).lag2ud(20,7), timeDispersion: 0.2);
    fb = LocalIn.ar(2); // feedback from the delay
    sig = Mix([sig,fb]) * 0.5; // sum it
    sig = LeakDC.ar(sig);
    del = DelayC.ar(sig * fbLevel, 1.5, delTime); // delay
    LocalOut.ar(LeakDC.ar(del)); // send it all back
    // Out.ar(0, sig);
    sig = SplayAz.ar(parent.numSpeakers, sig, width: 2.5,
        orientation: LFDNoise1.kr(90.reciprocal).range(0,7));
    sig = Mix(sig);
    // sig = SplayAz.ar(parent.numSpeakers, sig, width: 3,
    //   orientation: LFNoise1.kr(90.reciprocal).range(0,7)
    // ); // spatialize it
    sig = sig * 0.15;

    initDel = 0.01;
    rev = DelayN.ar(sig, 0.1, ((initDel+Rand(0.0,0.05)) ! parent.numSpeakers)); // initial delay
    leakSig = Mix(rev)*0.021; // a little bit of everything for each channel, regardless of position
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

    rev = LPF.ar(HPF.ar(rev, 200), Rand(4000,10000)); // highpass
    rev = CompanderD.ar(rev, 0.707, 1, 0.666); // compress it just to be safe
    sig = XFade2.ar(sig, rev, mix); // mix wet and dry
    // sig = LeakDC.ar(sig); // make sure we're cool
    Out.ar(outBus, sig*brainAmp*env); // send it out
  }).send(parent.server);

}
