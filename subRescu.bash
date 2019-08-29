#!/bin/bash
# bash matlab: time:hour node:xx ppn:xx ntask:xx calc:a,b,c

export INP="$@"

if [[ $INP != *"mem:"*  ]]; then 
   MEM="0"
else
   MEM="${INP#*mem:}"
   MEM="${MEM%%[[:blank:]]*}"
fi
echo "mem:$MEM"

if [[ $INP != *"matlab:"*  ]]; then 
   echo "matlab versoin is not given." && exit
else
   MATLABVER="${INP#*matlab:}"
   MATLABVER="${MATLABVER%%[[:blank:]]*}"
fi
echo "matlab:$MATLABVER"

if [[ $INP != *"time:"*  ]]; then 
   echo "time versoin is not given." && exit
else
   TIME="${INP#*time:}"
   TIME="${TIME%%[[:blank:]]*}"
fi
echo "time:$TIME"

if [[ $INP != *"node:"*  ]]; then 
   echo "node is not given." && exit
else
   NODE="${INP#*node:}"
   NODE="${NODE%%[[:blank:]]*}"
fi
echo "node:$NODE"

if [[ $INP != *"ppn:"*  ]]; then 
   echo "ppn is not given." && exit
else
   PPN="${INP#*ppn:}"
   PPN="${PPN%%[[:blank:]]*}"
fi
echo "ppn:$PPN"

if [[ $INP != *"ntask:"* ]]; then 
   echo "ntask is not given." && exit
else
   NTASK="${INP#*ntask:}"
   NTASK="${NTASK%%[[:blank:]]*}"
fi
echo "ntask:$NTASK"

if [[ $INP != *"calc:"* ]]; then 
   echo "calc is not given." && exit
else
   CALC="${INP#*calc:}"
   CALC="${CALC%%[[:blank:]]*}"
fi
echo "calc:$CALC"
CALC=$(sed -e 's/,/ /g' <<< "$CALC")
echo "$CALC"

#export OMP_NUM_THREADS=$NTASK && export OPENBLAS_NUM_THREADS=$NTASK
if [ $NTASK -eq 1 ]; then
   MATCMD="matlab -nodisplay -nojvm -nosplash -singleCompThread -r"
else
   MATCMD="matlab -nodisplay -nojvm -nosplash -r"
fi

SCRDIR="$HOME/jobscripts/bashscripts"
for RUN in $CALC; do
	INPUTFILE=$(find . -name "*$RUN.input")
	#echo "$RUN"
	if [ -z "$INPUTFILE" ]; then echo "no input file found for $RUN calculation." && exit; fi
	echo ""
	echo "| ---------------------- "
	echo "| ---------------------- "   
	echo "| matlab =  $MATLABVER   "   
	echo "| time   =  $TIME        "   
	echo "| calc   =  $RUN         "
	echo "| node   =  $NODE        "
	echo "| ppn    =  $PPN         "
	echo "| ntask  =  $NTASK       "
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
	#
	sed -i "s|XMATLABVER|${MATLABVER}|g" $PBSFILE	
	sed -i "s|XCALC|${RUN}|g" $PBSFILE	
	#
	sbatch $PBSFILE
done


# export NVAR=$#
# export ONT=${2##*/}

# SCFMAT=$(find . -name "*scf.mat" -type f)
# if [[ $CALC == *"scf"* ]] && [ ! -z "$SCFMAT" ] ; then 
   # echo "WARNING: scf data will be overwritten."
# elif [[ ! $CALC == *"scf"* ]] && [ -z "$SCFMAT" ] ; then  
   # echo "ERROR: scf data is not provided."
   # exit 1
# fi
