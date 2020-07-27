#!/bin/bash
# rescu:$RESCUPATH matlab:$MATLAB ppn:$NPROC ntask:$CPUPERPROC calc:A,B,C mpicmd:$mpicommand profile:on

INP="$@"
HOST="$HOSTNAME"
echo "$HOST"

# get input parameters
while [[ $INP == *":"* ]]; do
   VAR="${INP%%:*}" 
   # echo "$VAR"
   INP="${INP#*:}" 
   # echo "$INP"
   VAL="${INP%%[[:blank:]]*}" 
   # echo "$VAL" 
   INP="${INP#*[[:blank:]]}" 
   # echo "$INP"  
   #
   if [ $VAR == "ppn" ]; then PPN="$VAL"; fi
   if [ $VAR == "calc" ]; then CALC="$VAL"; fi      
   if [ $VAR == "ntask" ]; then NTASK="$VAL"; fi      
   if [ $VAR == "rescu" ]; then RESCUSRC="$VAL"; fi 
   if [ $VAR == "matlab" ]; then MATLABVER="$VAL"; fi   
   if [ $VAR == "mpicmd" ]; then MPICMD="$VAL"; fi      
   if [ $VAR == "profile" ]; then PROFILE="$VAL"; fi       
done 

# check and exit if does not exist
if [[ -z $PPN ]]; then echo -e "\e[31mppn is not given.\e[0m" && exit ; fi
if [[ -z $NTASK ]]; then echo -e "\e[31mntask is not given.\e[0m" && exit ; fi
if [[ -z $CALC ]]; then echo -e "\e[31mcalc is not given.\e[0m" && exit ; fi
if [[ -z $MATLABVER ]]; then echo -e "\e[31mmatlab version is not given.\e[0m" && exit ; fi
if [[ -z $RESCUSRC ]] ; then echo -e "\e[31mrescu path is not given.\e[0m" && exit ; fi
if [[ ! -d $RESCUSRC ]] ; then echo -e "\e[31mrescu path does not exist.\e[0m" && exit ; fi

# check and set default if does not exist
if [[ -z $PROFILE ]]; then PROFILE="off"; fi
if [[ -z $MPICMD ]]; then MPICMD="mpiexec --map-by ppr:$PPN:node:pe=$NTASK"; fi

#######################
# checking the inputs #
#######################
# echo "ppn = $PPN"
# echo "calc = $CALC"
# echo "ntask = $NTASK"
# echo "rescu = $RESCUSRC"
# echo "matlab = $MATLABVER"
# echo "mpicmd = $MPICMD"
# echo "profile = $PROFILE"
# CALC=$(sed -e 's/,/ /g' <<< "$CALC")
CALC="${CALC//,/ }"

###########
# execute #
###########
export OMPI_MCA_mca_base_component_show_load_errors=0
export OMP_NUM_THREADS=$NTASK 
export OPENBLAS_NUM_THREADS=$NTASK
if [ $OMP_NUM_THREADS -eq 1 ]; then
   MATCMD="matlab -nodisplay -nojvm -nosplash -singleCompThread -r"
else
   MATCMD="matlab -nodisplay -nojvm -nosplash -r"
fi
module load gcc/7.3.0 openmpi/3.1.2 matlab/"$MATLABVER"
   
for RUN in $CALC; do
   INPUTFILE=$(find . -name "*$RUN.input")
   #echo "$INPUTFILE"
   if [ -z "$INPUTFILE" ]; then echo "no input file found for $RUN calculation." && exit; fi
   echo "----------------------------------"
   echo "| ---------------------- "
   echo "| ---------------------- " 
   echo "| rescu  =  $RESCUSRC    "      
   echo "| matlab =  $MATLABVER   "   
   echo "| calc   =  $RUN         "
   echo "| ppn    =  $PPN         "
   echo "| ntask  =  $NTASK       "
   echo "| ---------------------- "
   echo "| ---------------------- "
   echo "input file found: ${INPUTFILE#./*}"
   echo "----------------------------------"
   #
   if [ $PROFILE == "on" ]; then   
      $MPICMD $MATCMD "addpath(genpath('$RESCUSRC')); rescu --smi --profile -i $INPUTFILE; quit;"
   else
      $MPICMD $MATCMD "addpath(genpath('$RESCUSRC')); rescu --smi -i $INPUTFILE; quit;"   
   fi
   if [ -f resculog.out ]; then 
      cat resculog.out >> "resculog_$CALC.out" && rm resculog.out
   fi
done

# MATLABVER="${INP#*matlab:}"
# if [[ $MATLABVER == "$INP" ]]; then echo "matlab versoin is not given." && exit; fi
# MATLABVER="${MATLABVER%%[[:blank:]]*}"
# #echo "$MATLABVER"

# PPN="${INP#*ppn:}"
# if [[ $PPN == "$INP" ]]; then echo "ppn is not given." && exit; fi
# PPN="${PPN%%[[:blank:]]*}"
# #echo "$PPN"

# NTASK="${INP#*ntask:}"
# if [[ $NTASK == "$INP" ]]; then echo "ntask is not given." && exit; fi
# NTASK="${NTASK%%[[:blank:]]*}"
# #echo "$NTASK"

# CALC="${INP#*calc:}"
# if [[ $CALC == "$INP" ]]; then echo "calculation type(s) is not given." && exit; fi
# CALC="${CALC%%[[:blank:]]*}"
# #echo "$CALC"