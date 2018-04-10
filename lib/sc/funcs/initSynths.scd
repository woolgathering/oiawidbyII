//////////////////////
// start synths
//////////////////////

{|parent|

  var control;
  control = parent.control;

  control.analysisSynth = Synth(\analysisReader,
    [vals: [0,0,0,0,0,0,0], brainBus: control.brainBus, normalizedBrainBus: control.normalizedBrainBus],
    target: control.controlGroup
  );

  parent.sound.heartbeatSynth = Synth(\heartbeat,
    [outBus: 0, buff: parent.sound.buffs.hr, rate: parent.control.heartBus.asMap, amp: -3.dbamp, env: parent.sound.buffs.hrEnv],
    target: control.controlGroup, addAction: \addToTail
  );

}
