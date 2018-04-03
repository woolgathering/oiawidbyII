////////////////////////////
//// synths
////////////////////////////

{|parent|

  SynthDef(\heartbeat, {|outBus = 0, buff, brainBus, amp = 0.2, rate = 60|
    var sig, ampEnv, trig, spd, env;
    // rate = LFNoise1.kr(0.1).range(rate*0.99, rate*1.1).lag2ud(1,2); // lag up a little quicker than below. Favor slighlty faster heartrate
    rate = rate.lag2(2).reciprocal; // smooth it out and convert it to Hz
    spd = 60/rate; // adjust the speed slightly to pitch up or down when the beat slows or speeds
    trig = Impulse.kr(rate); // trigger
    sig = GrainBuf.ar(1, trig, dur: BufDur.kr(buff), sndbuf: buff, rate: BufRateScale.kr(buff) * spd, interp: 4, envbufnum: env, maxGrains: 10);
    ampEnv = 1;
    Out.ar(outBus, sig*ampEnv); // send it out
  }).send(parent.server);


}
