#!/bin/bash

INP="$@"
HOST="$HOSTNAME"
echo "$HOST"
######################
# default parameters #
######################
if [[ $HOST == *"beluga"* ]] || [[ $HOST == *"blg"* ]] ; then
   MATLABDEF="2019a"; MEMDEF="0"; 
elif [[ $HOST == *"cedar"* ]] || [[ $HOST == *"crd"* ]]; then
   MATLABDEF="2017a"; MEMDEF="0"; 
elif [[ $HOST == *"graham"* ]]; then
   MATLABDEF="2019a"; MEMDEF="0"; 
fi
# echo "$MATLABDEF $MEMDEF"

# # get input parameters
# while [[ $INP == *":"* ]]; do
   # VAR="${INP%%:*}" && echo "$VAR"
   # INP="${INP#*:}" && echo "$INP"
   # VAL="${INP%%[[:blank:]]*}" && echo "$VAL" 
   # INP="${INP#*[[:blank:]]}" && echo "$INP"  
   # #
   # if [ $VAR == "ppn" ]; then PPN="$VAL"; fi
   # if [ $VAR == "calc" ]; then CALC="$VAL"; fi      
   # if [ $VAR == "ntask" ]; then NTASK="$VAL"; fi      
   # if [ $VAR == "rescu" ]; then RESCUVER="$VAL"; fi 
   # if [ $VAR == "matlab" ]; then MATLABVER="$VAL"; fi   
   # if [ $VAR == "mpicmd" ]; then MPICMD="$VAL"; fi      
   # if [ $VAR == "mpicmd" ]; then MPICMD="$VAL"; fi   
   # if [ $VAR == "profile" ]; then PROFILE="$VAL"; fi       
# done 

# # check and exit
# if [[ -z $PPN ]]; then echo -e "\e[31mppn is not given.\e[0m" && exit ; fi
# if [[ -z $NTASK ]]; then echo -e "\e[31mntask is not given.\e[0m" && exit ; fi
# if [[ -z $CALC ]]; then echo -e "\e[31mcalc is not given.\e[0m" && exit ; fi

# # check and set default
# if [[ -z $PROFILE ]]; then PROFILE="off"; fi
# if [[ -z $MATLABVER  ]]; then MATLABVER="$MATLABDEF"; fi
# if [[ -z $RESCUVER  ]]; then RESCUVER="wrkdir_matlab$MATLABVER"; fi


#######################
# checking the inputs #
#######################
if [[ $INP != *"matlab:"*  ]]; then 
   echo "matlab versoin is set to default: $MATLABDEF"
   MATLABVER="$MATLABDEF"
else
   MATLABVER="${INP#*matlab:}"
   MATLABVER="${MATLABVER%%[[:blank:]]*}"
fi
#echo "$MATLABVER"

if [[ $INP != *"ppn:"*  ]]; then 
   echo "ppn is not given." && exit
else
   PPN="${INP#*ppn:}"
   PPN="${PPN%%[[:blank:]]*}"
fi
#echo "$PPN"

if [[ $INP != *"ntask:"* ]]; then 
   echo "ntask is not given." && exit
else
   NTASK="${INP#*ntask:}"
   NTASK="${NTASK%%[[:blank:]]*}"
fi
#echo "$NTASK"

if [[ $INP != *"mpicmd:"*  ]]; then 
   MPICMD="mpiexec --map-by ppr:$PPN:node:pe=$NTASK"
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
# echo "$CALC"
# CALC=$(sed -e 's/,/ /g' <<< "$CALC")
CALC="${CALC//,/ }"

if [[ $MATLABVER == "2014a" ]]; then
   module load gcc/7.3.0 openmpi/3.1.2 matlab/2014a
elif [[ $MATLABVER == "2017a" ]]; then
   #module load gcc/4.8.5 openmpi/1.8.8 matlab/2017a
   module load gcc/7.3.0 openmpi/3.1.2 matlab/2017a   
elif [[ $MATLABVER == "2019a" ]]; then
   module load gcc/7.3.0 openmpi/3.1.2 matlab/2019a
else
   echo "RESCU is not installed for matlab $MATLABVER version." && exit
fi


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
# echo "rescu versoin is set to default: $RESCUDEF"
# echo "$PROFILE"

RESCUDIR="rescu_$RESCUVER/rescumat/Functions"
RESCUSRC="/home/sbohloul/bin_rescu/$RESCUDIR"   

##################
# matlab command #
##################
export OMPI_MCA_mca_base_component_show_load_errors=0
export OMP_NUM_THREADS=$NTASK && export OPENBLAS_NUM_THREADS=$NTASK
if [ $OMP_NUM_THREADS -eq 1 ]; then
   MATCMD="matlab -nodisplay -nojvm -nosplash -singleCompThread -r"
else
   MATCMD="matlab -nodisplay -nojvm -nosplash -r"
   #MATCMD="matlab -nodisplay -nosplash -r"
   
fi

###########
# execute #
###########
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
   #mpiexec --map-by ppr:$PPN:node:pe=$OMP_NUM_THREADS $MATCMD "addpath(genpath('$RESCUSRC')); rescu -i $INPUTFILE"
   #srun $MATCMD "addpath(genpath('$RESCUSRC')); rescu -i $INPUTFILE"
   if [ $PROFILE == "on" ]; then   
      $MPICMD $MATCMD "addpath(genpath('$RESCUSRC')); rescu --profile -i $INPUTFILE; quit;"
   else
      $MPICMD $MATCMD "addpath(genpath('$RESCUSRC')); rescu -i $INPUTFILE; quit;"   
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