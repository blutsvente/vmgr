# Get platform
######################################################################
  set machine=`uname -s -r`
  switch ("$machine")
    case "HP-UX B.10*":
      set os="HPPA10"
      breaksw
    case "HP-UX B.11*":
      set os="HPPA11"
      breaksw
    case "Linux*":
      set os="Linux"
      breaksw
    default:
      echo "\nERROR: Unknown Operating System.\n  Exiting."
      exit
  endsw

