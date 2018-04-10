///////////////////////////
// sound buffers
///////////////////////////

{|parent|
  var buffs, dreamBuffs, buffSize;

  buffs = (); // an empty dict

  //////////////////////////////////////////////////////////////////////
  // buffs for heartbeat
  //////////////////////////////////////////////////////////////////////
  buffs.hrEnv = Buffer.sendCollection(parent.server, parent.hrEnv.discretize, 1); // load the envelope into a buffer for the heartbeat
  buffs.hr = Buffer.read(parent.server, parent.thisDir ++ "/lib/sound/heartbeat.wav").normalize;

  //////////////////////////////////////////////////////////////////////
  // impulse response generation for reverb in dream (stereo)
  //////////////////////////////////////////////////////////////////////
  buffs.irSample = 2.collect{|i|
    var buf;
    buf = Buffer.readChannel(parent.server, parent.sound.ir, channels: [i]);
    parent.server.sync;
    buf; // return
  };
  buffSize = PartConv.calcBufSize(parent.sound.irSize, buffs.irSample[0]); // get the size of the buffer we need
  buffs.irSpec = 2.collect{
    var buf;
    buf = Buffer.alloc(parent.server, buffSize, 1); // allocate a buffer of the correct size
    parent.server.sync;
    buf; // return
  };
  buffs.irSpec.do{|buff, i|
    buff.preparePartConv(buffs.irSample[i], parent.sound.irSize); // make the spectrum
    parent.server.sync;
  };
  parent.server.sync; // wait for stuff to do
  buffs.irSample.do(_.free); // free the time domain data
  parent.server.sync;

  //////////////////////////////////////////////////////////////////////
  // dream buffers
  //////////////////////////////////////////////////////////////////////
  parent.dream.paths = (parent.thisDir ++ "/lib/sound/stageREM/dreams/*.wav").pathMatch;
  dreamBuffs = parent.dream.paths.collect{|path, i|
    var buff;
    buff = Buffer.cueSoundFile(parent.server, path, bufferSize: 131072);
    parent.server.sync;
    buff; // return
  };
  parent.server.sync;
  parent.dream.buffs = dreamBuffs;
  "DREAM BUFFERS: %\n\n".postf(parent.dream.buffs);

  parent.freeables.addAll(buffs); // add all this stuff to freeables
  parent.freeables.addAll(dreamBuffs); // add the dream buffers
  parent.sound.buffs = buffs; // remember
}
