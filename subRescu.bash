#!/bin/bash
# bash matlab: time:hour node:xx ppn:xx ntask:xx calc:a,b,c

INP="$@"
HOST="$HOSTNAME"

######################
# default parameters #
######################
if [[ $HOST == *"beluga"* ]]; then
   MATLABDEF="2019a"; MEMDEF="0"
elif [[ $HOST == *"cedar"* ]]; then
   MATLABDEF="2017a"; MEMDEF="0"
elif [[ $HOST == *"graham"* ]]; then
   MATLABDEF="2019a"; MEMDEF="0"
fi
# echo "$MATLABDEF $MEMDEF"

#######################
# checking the inputs #
#######################
if [[ $INP == *"gpu:"*  ]]; then 
   GPU="${INP#*gpu:}"
   GPU="${GPU%%[[:blank:]]*}"
fi
# echo "gpu:$GPU"

if [[ $INP != *"mem:"*  ]]; then 
   MEM="$MEMDEF"
else
   MEM="${INP#*mem:}"
   MEM="${MEM%%[[:blank:]]*}"
fi
# echo "mem:$MEM"

if [[ $INP != *"matlab:"*  ]]; then 
   echo "matlab versoin is set to default: $MATLABDEF"
   MATLABVER="$MATLABDEF"
else
   MATLABVER="${INP#*matlab:}"
   MATLABVER="${MATLABVER%%[[:blank:]]*}"
fi
# echo "matlab:$MATLABVER"

if [[ $INP != *"time:"*  ]]; then 
   echo "time versoin is not given." && exit
else
   TIME="${INP#*time:}"
   TIME="${TIME%%[[:blank:]]*}"
fi
# echo "time:$TIME"

if [[ $INP != *"node:"*  ]]; then 
   echo "node is not given." && exit
else
   NODE="${INP#*node:}"
   NODE="${NODE%%[[:blank:]]*}"
fi
# echo "node:$NODE"

if [[ $INP != *"ppn:"*  ]]; then 
   echo "ppn is not given." && exit
else
   PPN="${INP#*ppn:}"
   PPN="${PPN%%[[:blank:]]*}"
fi
# echo "ppn:$PPN"

if [[ $INP != *"ntask:"* ]]; then 
   echo "ntask is not given." && exit
else
   NTASK="${INP#*ntask:}"
   NTASK="${NTASK%%[[:blank:]]*}"
fi
#echo "ntask:$NTASK"

if [[ $INP != *"mpicmd:"*  ]]; then 
   MPICMD=""
else
   MPICMD="${INP#*mpicmd:}"
   MPICMD="${MPICMD%%[[:blank:]]*}"
fi
# echo "$MPICMD"

if [[ $INP != *"calc:"* ]]; then 
   echo "calc is not given." && exit
else
   CALC="${INP#*calc:}"
   CALC="${CALC%%[[:blank:]]*}"
fi
#echo "calc:$CALC"

if [[ $CALC == *","* ]]; then
   CALC=$(sed -e 's/,/ /g' <<< "$CALC")
fi   
#echo "$CALC"

if [[ $INP == *"rescu:"*  ]]; then 
   RESCUVER="${INP#*rescu:}"
   RESCUVER="${RESCUVER%%[[:blank:]]*}"
else
   RESCUVER="wrkdir_matlab$MATLABVER"
fi

if [[ $INP == *"profile:"*  ]]; then 
   PROFILE="${INP#*profile:}"
   PROFILE="${PROFILE%%[[:blank:]]*}"
else
   PROFILE="off"
fi

##################
# matlab command #
##################
# export OMP_NUM_THREADS=$NTASK && export OPENBLAS_NUM_THREADS=$NTASK
if [ $NTASK -eq 1 ]; then
   MATCMD="matlab -nodisplay -nojvm -nosplash -singleCompThread -r"
else
   MATCMD="matlab -nodisplay -nojvm -nosplash -r"
fi

#############################
# prepare and submit job(s) #
#############################
SCRDIR="$HOME/jobscripts/bashscripts"
for RUN in $CALC; do
	INPUTFILE=$(find . -name "*$RUN.input")
	#echo "$RUN"
	if [ -z "$INPUTFILE" ]; then echo "no input file found for $RUN calculation." && exit; fi
	echo ""
	echo "| ---------------------- "
	echo "| ---------------------- "  
   echo "| host   =  $HOST        "   
	echo "| matlab =  $MATLABVER   "   
	echo "| rescu  =  $RESCUVER    "      
	echo "| time   =  $TIME        "   
	echo "| calc   =  $RUN         "
	echo "| node   =  $NODE        "
	echo "| ppn    =  $PPN         "
	echo "| ntask  =  $NTASK       "
	echo "| gpu    =  $GPU         "   
	echo "| ---------------------- "
	echo "| ---------------------- "
	echo "input file found: ${INPUTFILE#./*}"
	echo ""
	#
	OUTPUTFILE=${INPUTFILE/input/out}
	PBSFILE="$RUN.pbs"
	cp $SCRDIR/jobRescu.pbs $PBSFILE
	sed -i "s|XNODE|${NODE}|g" $PBSFILE
	sed -i "s|XMEM|${MEM}|g" $PBSFILE	
	sed -i "s|XTASK|${PPN}|g" $PBSFILE
	sed -i "s|XPROC|${NTASK}|g" $PBSFILE
	sed -i "s|XHOUR|${TIME}|g" $PBSFILE
	sed -i "s|XIN|${INPUTFILE}|g" $PBSFILE
	sed -i "s|XOUT|${OUTPUTFILE}|g" $PBSFILE
	sed -i "s|XMATCMD|${MATCMD}|g" $PBSFILE	
	sed -i "s|XMPICMD|${MPICMD}|g" $PBSFILE	
	sed -i "s|XRESCU|${RESCUVER}|g" $PBSFILE	
	sed -i "s|XPROFILE|${PROFILE}|g" $PBSFILE	
   
   
   if [[ -z $GPU ]]; then
      sed -i "/XGPU/d" $PBSFILE
   else
      sed -i "s|XGPU|${GPU}|g" $PBSFILE
   fi
   
	#
	sed -i "s|XMATLABVER|${MATLABVER}|g" $PBSFILE	
	sed -i "s|XCALC|${RUN}|g" $PBSFILE	
	#
	sbatch $PBSFILE
done


############################################################
# export NVAR=$#
# export ONT=${2##*/}

# SCFMAT=$(find . -name "*scf.mat" -type f)
# if [[ $CALC == *"scf"* ]] && [ ! -z "$SCFMAT" ] ; then 
   # echo "WARNING: scf data will be overwritten."
# elif [[ ! $CALC == *"scf"* ]] && [ -z "$SCFMAT" ] ; then  
   # echo "ERROR: scf data is not provided."
   # exit 1
# fi

