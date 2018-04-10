////////////////////////////////
// load probabilities
////////////////////////////////

{|parent|
  var dream, probabilities;
  dream = parent.dream; // make it easier
  probabilities = FileReader.read(parent.thisDir ++ "/lib/dream/probabilities", true, true);
  probabilities = probabilities.collect{|array|
    [array[0].asSymbol, array[1].asFloat]; // conver it into the form we need
  };
  probabilities = probabilities.flat.asEvent; // make it an Event
  probabilities; // return
}
