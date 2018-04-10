///////////////////////////////////////
// read the files and start sending information
///////////////////////////////////////

{|parent|

  var counter, annotationLineToArray, analysisLineToArray, annotations, analysis;

  counter = 0; // set it to 0 to start
  // annotations = File.open(parent.annotationFile, "r"); // get ready to read the file
  annotations = CSVFileReader.read(parent.annotationFile); // read it into an array
  parent.annotations = annotations; // set it in the parent
  analysis = File.open(parent.analysisFile, "r"); // get ready to read the file
  parent.currentStage = (stage: "None", dur: 0);

  // functions to turn the information into a usable form in an array
  annotationLineToArray = {|line|
    line = line.split($,); // split it by commas
    line[1] = line[1].asInteger; // make sure the seconds are integers
  };

  analysisLineToArray = {|line|
    line = line.split($,); // split by commas
    line = line.asFloat; // convert them all to floats
  };

  parent.readRoutine = Routine.run({
    var thisAnalysis, thisAnnotation, idx;
    // we need to skip the first 30 analysis frames to ensure everything lines up with the annotations (since they start 30s AFTER the start of the EEG recording)
    30.do{
      thisAnalysis = analysis.getLine(1024); // read it
    };
    idx = 1; // the line number of the annotation file that we're on (0 is start of piece)

    // start going through the analysis. Will return nil when we hit the end of the file
    while (
      {thisAnalysis.notNil}, // while we're not at the end of the file
      {
        thisAnalysis = analysis.getLine(1024); // read the line
        // "ANALYSIS: %\n".postf(thisAnalysis); // debugging
        // if we're not at the end of the file by now, read the analysis into the busses
        if (thisAnalysis.notNil) {
          thisAnalysis = analysisLineToArray.(thisAnalysis); // get it into an array in usable form
          // parent.control.analysisBus.setn(thisAnalysis[1..7]); // set the control busses
          parent.control.analysisSynth.set(\vals, thisAnalysis[1..7]); // set it
          parent.control.heartBus.set(thisAnalysis[8]); // set our current heartbeat level
        };

        // if we're in a new stage, set it (check every 1s)
        if (counter == parent.currentStage.dur) {
          try {
            parent.currentStage = (stage: annotations[idx][0], dur: annotations[idx][1].asInteger); // remember it in a larger context
            parent.sound.lastGroup.set(\gate, 0); // start the decay on the previous synths
            // "NEW STAGE: % ----------------\n\n".postf(parent.currentStage.stage); // debugging
            if (parent.prevTask.notNil) {
              parent.prevTask = parent.currentTask; // remember the last Task
              fork {(parent.currentStage.dur*0.15).wait; parent.prevTask.stop}; // stop the last task 15% of the way through
            } {
              parent.prevTask = parent.currentTask;
            };
            ////////////////////////////////////
            // WHERE MAGIC HAPPENS /////////////
            ////////////////////////////////////
            ////////////////////////////////////
            parent.makeStage(parent.currentStage.stage, idx); // make a new stage: group, synth, task, etc.
            ////////////////////////////////////
            ////////////////////////////////////
          } {|error|
            // except when we're at the end, we get an error
            "Error in counterDurationThing: %\n\n".format(error).error;
            parent.currentStage = (stage: "SLEEP-S0", dur: 99999999); // set a huge value so the piece ends long before it throws an error
            parent.sound.lastGroup.set(\gate, 0); // start the decay on the previous synths
            parent.makeStage(parent.currentStage.stage, idx); // make a synth with the current stage
          };
          counter = 0; // reset
          idx = idx + 1;
        } {
          counter = counter + 1; // else, add to the counter
        };

        1.wait; // advance once second later
      };
    );

  });



};
