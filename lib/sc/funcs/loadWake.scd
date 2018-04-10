////////////////////////
// collect files for SLEEP-S0 (WAKE)
/////////////////////////

{|parent|

  var sound, paths;

  sound = parent.sound;
  // sound.wake = (); // an empty dict
  paths = (parent.thisDir ++ "/lib/sound/wake/*.wav").pathMatch; // collect the paths for our wake sounds

  sound.wake.buffers = paths.collect{|path|
    var buff;
    buff = Buffer.read(parent.server, path).normalize;
    parent.server.sync; // wait until it's done
    parent.freeables.add(buff);
    buff; // return
  };

}
