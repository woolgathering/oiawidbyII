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
  parent.currentTasks = List.new(0); // give it something here so it's not nil

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
    var thisAnalysis, thisAnnotation, idx, startLine;
    // we need to skip the first 30 analysis frames to ensure everything lines up with the annotations (since they start 30s AFTER the start of the EEG recording)
    idx = 5; // the line number of the annotation file that we're on (0 is start of piece)
    startLine = 0; // start at 0
    if (idx > 0) {
      idx.do{|i|
        i = i+1; // correct for offset
        startLine = startLine + annotations[i-1][1].asInteger; // only add if were
      };
    };
    startLine = startLine + 30; // always at least 30
    startLine.do{
      thisAnalysis = analysis.getLine(1024); // offset so we read from the correct place
    };

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
            parent.prevTasks = parent.currentTasks;  // remember and reassign
            fork {(parent.currentStage.dur*0.1).wait; parent.prevTasks.do(_.stop)}; // stop the last task 5% of the way through and make an empty list here
            // if (parent.prevTask.notNil) {
            //   parent.prevTask = parent.currentTask; // remember the last Task
            // } {
            //   parent.prevTask = parent.currentTask; // else set it if it's nil
            // };
            ////////////////////////////////////
            // WHERE MAGIC HAPPENS /////////////
            ////////////////////////////////////
            ////////////////////////////////////
            parent.makeStage(parent.currentStage.stage, idx); // make a new stage: group, synth, task, etc. Also where a new currentTask is created
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
