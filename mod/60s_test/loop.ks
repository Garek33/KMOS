@lazyglobal off.

parameter proc.

print proc.
set proc["count"] to proc["count"] + 5.
if(proc["count"] > 60) {
  print "done.".
  kmos["exit"]().
}