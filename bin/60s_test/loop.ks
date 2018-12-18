@lazyglobal off.

parameter proc.

print proc["ppi"].
set proc["ppi"]["count"] to proc["ppi"]["count"] + 5.
if(proc["ppi"]["count"] > 60) {
  print "done.".
  kmos["exit"]().
}