////////////////////////////////
// dream factory
//////////////////////////////

{|dream, dur|

  var env, buff, amp, group;
  buff = dream.buffs.choose; // pick a random dream for now
  dur = (dur*rrand(0.2,0.4)).min(141); // get how long this will be, maximum is 141s
  group = ParGroup.after(dream.control.controlGroup); // make a group for this synth
  amp = dream.control.normalizedBrainBus.getSynchronous(0).linlin(0.2,0.8,-16.dbamp, -7.dbamp);
  dream.server.sync;

  "-----------------------------------\n
  DREAM: %------Dur: % ------------\n
  -----------------------------------\n".postf(buff.path.basename, dur.round(0.01));

  dream.thisDream = Synth(\dream,
    [outBus: 0, buff: buff, dur: dur, revBuffs: dream.sound.buffs.irSpec, normalizedBrainBus: dream.control.normalizedBrainBus, amp: amp],
    target: group
  );

  dur; // return the duration
}
