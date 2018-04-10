////////////////////////////////
// CmdPeriod
////////////////////////////////

{|parent|

  CmdPeriod.doOnce({
    parent.freeables.do(_.free); // free the freeables
  });

}
