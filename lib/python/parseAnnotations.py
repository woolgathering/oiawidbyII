import os

fname = os.path.expanduser("~/Documents/misc/oiawidbyII/data/n5/n5.txt")
output = open(os.path.expanduser("~/Documents/misc/oiawidbyII/data/n5/n5_annotations"), "w")

with open(fname) as f:
    content = f.readlines()
# content = [x.strip() for x in content]

current_stage = None # set the current_stage to None to start
time = None # set time to None
total_time = 0 # sanity check

for line_as_string in content:
  # print (line)
  line = line_as_string.split('\t') # split it into an array by tab characters
  if len(line) > 4:
    if 'SLEEP-' in line_as_string:
      this_stage = line[3] # get what this line's stage is
      if this_stage == current_stage:
        # if this stage is also the current stage
        time += int(line[4]) # keep counting
      else:
        # else it's not so write the info to a file and reset everything
        # output_line = line[0] ++ ',' ++ line[3] ++ ',' str(time) ++ '\n' # assemble the output line
        if time is not None:
          output_line = ', '.join(map(str, (current_stage, time)))
          output_line += '\n' # add a newline at the end
          print (output_line)
          total_time += time
          output.write(output_line) # write it to the file

        # reset
        current_stage = line[3] # set the current_stage
        time = int(line[4]) # get the time as an integer

# write the last line out
output_line = ', '.join(map(str, (current_stage, time)))
output_line += '\n' # add a newline at the end
print (output_line)
total_time += time
output.write(output_line) # write it to the file

output.close()
print ("Total time: {} seconds -- {} hours".format(total_time, float(total_time)/3600))

