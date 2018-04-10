/////////////////////////////////////////////
// calculate the envelope for a section
/////////////////////////////////////////////

{|parent, idx|

  var att, dec, prevAnnotation, nextAnnotation, env;

  // these are returned as strings in an array or nil if it's out of bounds
  prevAnnotation = try {parent.annotations[idx-1][1].asInteger} {nil}; // get the last annotation
  nextAnnotation = try {parent.annotations[idx+1][1].asInteger} {nil}; // get the next annotation

  // attack (between 10 and 60 seconds)
  if (prevAnnotation.notNil) {
    // if it's not nil, we need to set the attack according to the duration of the attack of the previous annotation
    att = (prevAnnotation * 0.1).max(20) * rrand(0.9,1.1); // make it a little random
  } {
    // if it's nil, it means this is the first section
    att = parent.currentStage.dur * 0.1;
  };
  att = att.min(75); // maximum of 60 seconds

  // decay (between 10 and 60 seconds)
  if (nextAnnotation.notNil) {
    // if it's not nil, we need to set the attack according to the duration of the attack of the previous annotation
    dec = (parent.currentStage.dur * 0.1).max(20) * rrand(0.9, 1.1);
  } {
    // if it's nil, it means this is the last section
    dec = parent.currentStage.dur * 0.3; // make it a little long
  };
  dec = dec.min(75); // maximum of 60 seconds

  // env = Env.asr(att, 1, dec); // get an envelope
  env = Env([ 0, 1, 0 ], [ att, dec ], 'sine', 1);
  "\tENV--- att: %\tdec: %\n".postf(att,dec);
  env; // return that envelope
}
