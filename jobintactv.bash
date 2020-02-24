#!/bin/bash
# acc:account mem:128000M(128G)

# beluga
# 172	40  92G or  95000M	2 x Intel Gold 6148 Skylake @ 2.4 GHz	1 x SSD 480G	-
# 516	40	186G or 191000M	2 x Intel Gold 6148 Skylake @ 2.4 GHz	1 x SSD 480G	-
# 12	40	752G or 771000M	2 x Intel Gold 6148 Skylake @ 2.4 GHz	1 x SSD 480G	-
# 172	40	186G or 191000M	2 x Intel Gold 6148 Skylake @ 2.4 GHz	1 x NVMe SSD 1.6T	4 x NVidia V100SXM2 (16G memory)

# cedar
# 576	32	 125G or  128000M	2 x Intel E5-2683 v4 Broadwell @ 2.1Ghz	2 x 480G SSD	-
# 128	32	 250G or  257000M	2 x Intel E5-2683 v4 Broadwell @ 2.1Ghz	2 x 480G SSD	-
# 24	32	 502G or  515000M	2 x Intel E5-2683 v4 Broadwell @ 2.1Ghz	2 x 480G SSD	-
# 24	32	1510G or 1547000M	2 x Intel E5-2683 v4 Broadwell @ 2.1Ghz	2 x 480G SSD	-
# 4	32	3022G or 3095000M	4 x Intel E7-4809 v4 Broadwell @ 2.1Ghz	2 x 480G SSD	-
# 114	24	 125G or  128000M	2 x Intel E5-2650 v4 Broadwell @ 2.2GHz	1 x 800G SSD	4 x NVIDIA P100 Pascal (12G HBM2 memory)
# 32	24	 250G or  257000M	2 x Intel E5-2650 v4 Broadwell @ 2.2GHz	1 x 800G SSD	4 x NVIDIA P100 Pascal (16G HBM2 memory)
# 640	48	 187G or  192000M	2 x Intel Platinum 8160F Skylake @ 2.1Ghz	2 x 480G SSD	-

# graham
# 903	32	 125G or  128000M	2 x Intel E5-2683 v4 Broadwell @ 2.1GHz	960GB SATA SSD	-
# 24	32	 502G or  514500M	2 x Intel E5-2683 v4 Broadwell @ 2.1GHz	960GB SATA SSD	-
# 56	32	 250G or  256500M	2 x Intel E5-2683 v4 Broadwell @ 2.1GHz	960GB SATA SSD	-
# 3	64	3022G or 3095000M	4 x Intel E7-4850 v4 Broadwell @ 2.1GHz	960GB SATA SSD	-
# 160	32  124G or  127518M	2 x Intel E5-2683 v4 Broadwell @ 2.1GHz	1.6TB NVMe SSD	2 x NVIDIA P100 Pascal (12GB HBM2 memory)
# 7	28	 178G or  183105M	2 x Intel Xeon Gold 5120 Skylake @ 2.2GHz	4.0TB NVMe SSD	8 x NVIDIA V100 Volta (16GB HBM2 memory)


export INP="$@"
export HOST="$HOSTNAME"

if [[ $INP != *"acc:"*  ]]; then 
   ACC="account=rrg-hongguo-ad"
else
   ACC="${INP#*acc:}"
   ACC="${ACC%%[[:blank:]]*}"
fi

if [[ $INP != *"gpu:"*  ]]; then 
   GPU=""
else
   GPU="${INP#*gpu:}"
   GPU="${GPU%%[[:blank:]]*}"
fi

if [[ $INP != *"mem:"*  ]]; then 
   MEM="0"
else
   MEM="${INP#*mem:}"
   MEM="${MEM%%[[:blank:]]*}"
fi

if [[ $HOST == *"beluga"* ]]; then
   NTASK="40"
elif [[ $HOST == *"cedar"* ]]; then
   NTASK="32"
elif [[ $HOST == *"graham"* ]]; then
   NTASK="32" 
fi

echo ""
echo " ----------"
echo "| account: |$ACC" 
echo "|   ntask: |$NTASK"
echo "|  memory: |$MEM"
echo " ----------"
echo ""

if [[ -z $GPU ]]; then
   alloc="--time=03:00:00 --nodes=1 --ntasks=$NTASK --mem=$MEM --account=$ACC"
else
   alloc="--time=03:00:00 --nodes=1 --ntasks=$NTASK --mem=$MEM --account=$ACC --gres=gpu:$GPU"
fi

# echo $alloc
salloc $alloc

# if [ -z "$MEM" ]; then
   # MEM="0"
# else
   # MEM="${MEM}000M"
# fi

