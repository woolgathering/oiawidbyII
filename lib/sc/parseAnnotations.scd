////////////////////////////////////////////////////////
// parses annotations
// necessary to check the first few lines and delete them
////////////////////////////////////////////////////////

(
var file, annotations, line, array, string;

file = File.open("/home/roger/Documents/jacob/pieces/eoiayidbyII/data/n11/n11.txt", "r"); // read the file
annotations = File.open("/home/roger/Documents/jacob/pieces/eoiayidbyII/data/n11/n11_annotations", "w");

line = file.getLine(2048);
while(
  {line.notNil}, // while we're not at the end of the file
  {
    // check if the line contains a sleep section
    if (line.contains("SLEEP-S"))
      {
        // line.postln;
        array = line.split($\t); // split the line by the tab character
        array.do{|word, i|
          if (i==0) {
            string = word; // set the first to the first in the line
          } {
            string = string ++ ", " ++ word; // add a comma and add all subsequent words
          };
        };
        string = string ++ "\n"; // add a newline at the end
        annotations.write(string); // write it to the file
      };
    line = file.getLine(2048); // get another line
  };
);
annotations.close; // close the file
"done".postln;
)
