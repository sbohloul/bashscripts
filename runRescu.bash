#!/bin/bash

INP="$@"

MATLABVER="${INP#*matlab:}"
if [[ $MATLABVER == "$INP" ]]; then echo "matlab versoin is not given." && exit; fi
MATLABVER="${MATLABVER%%[[:blank:]]*}"
#echo "$MATLABVER"

PPN="${INP#*ppn:}"
if [[ $PPN == "$INP" ]]; then echo "ppn is not given." && exit; fi
PPN="${PPN%%[[:blank:]]*}"
#echo "$PPN"

NTASK="${INP#*ntask:}"
if [[ $NTASK == "$INP" ]]; then echo "ntask is not given." && exit; fi
NTASK="${NTASK%%[[:blank:]]*}"
#echo "$NTASK"

CALC="${INP#*calc:}"
if [[ $CALC == "$INP" ]]; then echo "calculation type(s) is not given." && exit; fi
CALC="${CALC%%[[:blank:]]*}"
#echo "$CALC"
CALC=$(sed -e 's/,/ /g' <<< "$CALC")

if [[ $MATLABVER == "2014a" ]]; then
   module load gcc/7.3.0 openmpi/3.1.2 matlab/2014a
   export RESCUSRC=/home/sbohloul/bin_rescu/rescu_wrkdir_matlab2014a/rescumat/Functions
elif [[ $MATLABVER == "2017a" ]]; then
   module load gcc/4.8.5 openmpi/1.8.8 matlab/2017a
   export RESCUSRC=/home/sbohloul/bin_rescu/rescu_wrkdir_matlab2017a/rescumat/Functions
else
   echo "RESCU is not installed for matlab $MATLABVER version." && exit
fi

# matlab command
export OMPI_MCA_mca_base_component_show_load_errors=0
export OMP_NUM_THREADS=$NTASK && export OPENBLAS_NUM_THREADS=$NTASK
if [ $OMP_NUM_THREADS -eq 1 ]; then
   MATCMD="matlab -nodisplay -nojvm -nosplash -singleCompThread -r"
else
   MATCMD="matlab -nodisplay -nojvm -nosplash -r"
fi
#


for RUN in $CALC; do
   INPUTFILE=$(find . -name "*$RUN.input")
   #echo "$INPUTFILE"
   if [ -z "$INPUTFILE" ]; then echo "no input file found for $RUN calculation." && exit; fi
   echo "----------------------------------"
   echo "| ---------------------- "
   echo "| ---------------------- "   
   echo "| matlab =  $MATLABVER   "   
   echo "| calc   =  $RUN         "
   echo "| ppn    =  $PPN         "
   echo "| ntask  =  $NTASK       "
   echo "| ---------------------- "
   echo "| ---------------------- "
   echo "input file found: ${INPUTFILE#./*}"
   echo "----------------------------------"
   
   mpiexec --map-by ppr:$PPN:node:pe=$OMP_NUM_THREADS $MATCMD "addpath(genpath('$RESCUSRC')); rescu -i $INPUTFILE"
done