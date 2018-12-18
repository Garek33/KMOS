@lazyglobal off.

parameter proc.

print proc["ppi"].
set proc["ppi"]["counter"] to proc["ppi"]["counter"] + 5.
if(proc["ppi"]["counter"] > 60) {
  print "done.".
  kmos["exit"]().
}