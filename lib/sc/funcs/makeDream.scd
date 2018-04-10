////////////////////////////////
// dream factory
//////////////////////////////

{|dream, dur|

  var env, buff, amp, group;
  buff = dream.buffs.choose; // pick a random dream for now
  dur = dur*rrand(0.2,0.4); // get how long this will be
  dream.parent.postln;
  group = ParGroup.after(dream.parent.control.controlGroup); // make a group for this synth

  "DREAM: %---------------------------\n".postf(buff.path.basename);

  dream.thisDream = Synth(\dream,
    [outBus: 0, buff: buff, dur: dur, revBuffs: dream.parent.sound.buffs.irSpec, normalizedBrainBus: dream.parent.control.normalizedBrainBus, amp: -6.dbamp],
    target: group
  );

  dur; // return the duration
}
