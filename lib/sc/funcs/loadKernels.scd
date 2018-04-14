////////////////////////
// collect files for SLEEP-S1 (STAGE 1)
/////////////////////////

{|parent, stage|

  var sound, paths, kernelStarts, kernels;

  sound = parent.sound;
  kernels = List.new(0); // an empty list
  paths = (parent.thisDir ++ "/lib/sound/%/*.wav".format(stage)).pathMatch; // collect the paths for our wake sounds
  kernelStarts = FileReader(parent.thisDir ++ "/lib/sound/%/kernelStarts".format(stage), true, true); // get it into an array

  kernelStarts.do{|line, i|
    var filename, starts;
    filename = line[0]; // get the filename
    starts = line[1..].asInteger; // get the starting samples as integers
    "\tCreating kernels for %...\n".postf(filename);

    // check to see which path matches the filename
    paths.do{|path, j|
      var source, kernel; // a variable to store the buffer for the source sound and a placeholder for kernels
      if(path.contains(filename)) {
        // if it contains the filename, read the file into a buffer
        source = Buffer.readChannel(parent.server, path, channels: [0]); // load the buffer
        parent.server.sync; // wait for it to finish

        // then make kernals on each of the starting samples in starts[]
        starts.do{|start, k|
          kernel = source.makeKernel(start, sound.kernelSize, winType: 'hann'); // make the kernel
          parent.server.sync; // wait for it to finish
          kernels.add(kernel); // put it in the array of kernels
        };
        source.free; // free the source since we no longer need it
      };
    };

    parent.freeables.addAll(kernels);
    sound.at(stage.asSymbol).kernels = kernels; // remember the kernel list in the appropriate place
  };

}
