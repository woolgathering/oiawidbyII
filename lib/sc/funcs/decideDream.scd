////////////////
// dream
////////////////

{|parent, sleepStage, annotationIdx|

  var prob, dur, thisDur, annotations, thisDreamDur;
  // probabilities = parent.dream.probabilities; // get the dictionary of probabilities
  annotations = parent.annotations; // make life easier
  prob = parent.dream.probabilities.at(sleepStage); // get the probability of dreaming in this stage
  thisDur = annotations[annotationIdx][1].asInteger; // get the duration of this stage

  ///////////////////////////////////
  // if we haven't dreamt
  ///////////////////////////////////
  if (parent.dream.happened.not) {
    var prevStage;
    try {
      prevStage = annotations[annotationIdx-1][0]; // try to get the name of the previous stage

      // if the previous stage was waking...
      if (prevStage == "SLEEP-S0") {
        if (prob.coin) {
          // if we do in fact happen to dream, do it!
          thisDreamDur = parent.dream.makeDream(thisDur); // makes a dream and returns its duration
          parent.dream.happened = true;
        };
      } {
        // else the previous stage wasn't waking but we haven't yet dreamt
        if (prob.coin) {
          // if we do in fact happen to dream, do it!
          thisDreamDur = parent.dream.makeDream(thisDur); // makes a dream and returns its duration
          parent.dream.happened = true;
        };
      };

    } {|error|
      // if it throws an error, this is the first stage so don't do anything
      "error in parent.makeDream()... unless this is the first stage: %\n".format(error).error;
    };

  };

  ///////////////////////////////////
  // if we've previously dreamt
  ///////////////////////////////////
  if (parent.dream.happened) {
    // more likley to stay in the same dream
    var prevStage;
    try {
      prevStage = annotations[annotationIdx-1][0]; // try to get the name of the previous stage

      if (prob.coin) {
        // if we do in fact happen to dream, do it!
        parent.dream.makeDream(thisDur);
      };

    } {|error|
      // if it throws an error, this is the first stage so don't do anything
      "error in parent.makeDream()... unless this is the first stage: %\n".format(error).error;
    };
  };

  thisDreamDur = thisDreamDur ?? {rrand(thisDur*0.1, thisDur*0.2)}; // if we don't have a duration, get one
  thisDreamDur; // return
}
