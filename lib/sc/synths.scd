////////////////////////////
//// synths
////////////////////////////

{|parent|

  SynthDef(\heartbeat, {|outBus = 0, buff, env, brainBus, amp = 0.2, rate = 60|
    var sig, ampEnv, trig;
    rate = LFNoise1.kr(0.1).range(rate*0.99, rate*1.1).lag2ud(1,2); // lag up a little quicker than below. Favor slighlty faster heartrate
    trig = Impulse.kr(rate.reciprocal);
    sig = GrainBuf.ar(1, trig, dur: BufDur.kr(buff), sndbuf: buff, rate: BufRateScale.kr(buff), interp: 4, envbufnum: env, maxGrains: 10);
    ampEnv = 1;
    Out.ar(outBus, sig*ampEnv); // send it out
  }).send(parent.server);


}
