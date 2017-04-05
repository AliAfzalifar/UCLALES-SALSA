#!/bin/bash

# Submit postprosessing to queue, Jaakko Ahola, FMI, 09/2016
# Major update 31.3.2017
#
# input variables:
# $1 = name of netcdf input file
# $2 = name of postprocessing script (OPTIONAL) default value: combine
# $3 = job flag of the job scheduling system (OPTIONAL) default value: PBS

# Exit on error
set -e

# import subroutines & variables 
if [ -d /home/users/aholaj/UCLALES-SALSA/script/ ]
then
    scripting=/home/users/aholaj/UCLALES-SALSA/script
else
    scripting=.
fi    
source ${scripting}/subroutines_variables.bash


scriptfolder="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo "scriptfolder" $scriptfolder

# supercomputer related variable settings
WT=01:00:00 # walltime
jobnamepostfix=pros

echo "scriptname" ${scriptname}
if [ -n $2 ]; then
  scriptname=$2
fi

echo "scriptname" ${scriptname}

if [[ -n $3 ]]; then
  jobflag=$3
fi
echo "job scheduling system" $jobflag

if [ -z $4 ]; then
  echo "jobname postfix: " $jobnamepostfix
else
  jobnamepostfix=$4
  echo "jobname postfix: " $jobnamepostfix
fi



################################
###			                 ###
### input directory	         ###
###			                 ###
################################
if [ -z $1 ]; then
  echo "You didn't give any name of netcdf input file"
  exit 1
fi

input=$1
dir=$(dirname ${input})

if [ $dir == '.' ]; then
  dir=$PWD
fi
echo $dir
base=$(basename ${input})
if  [ ${base: -3} == ".ts" ] || [ ${base: -3} == ".ps" ]
then
	postfix=${input:$((${#input}-3)):3}
else
	# "input argument is a regular .nc
	postfix=.nc
fi

echo 'postfix' $postfix
##########################
###			           ###
### Create run scripts ###
###		               ###
##########################
echo " "
## modify the job name based on length: ###
length=$(( ${#jobnamepostfix} < 7 ? ${#jobnamepostfix} : 7))
jobname=${postfix:$((${#postfix}-2)):2}_${jobnamepostfix:$((${#jobnamepostfix}-${length})):${length}}
echo 'Queuing system jobname' $jobname

rm -rf ${dir}/post_* ${dir}/*pros.sh ${dir}/${scriptname}

echo kopioidaan skripti
cp ${scriptfolder}/${scriptname} ${dir}/
echo kopiointi suoritettu
### first script
cat > ${dir}/postpros${postfix}.sh <<EOF
#!/bin/bash

set -e

cd ${dir}

python ${scriptname} $input

EOF

### second script

if [ $jobflag == 'PBS' ] ; then

cat > ${dir}/runpostpros${postfix}.sh <<FINALPBS
#!/bin/sh
#PBS -N ${jobname}
#PBS -l mppwidth=1
#PBS -l mppnppn=1
#PBS -l mppdepth=${nodeNPU}
#PBS -l walltime=${WT}
#PBS -j oe
#PBS -M ${email}
#PBS -m ae

source /etc/profile
module load Python

cd ${dir}

aprun -n1 -N1 -d${nodeNPU} ./postpros${postfix}.sh | tee ${PBS_JOBNAME:-post_interactive${postfix}}.${PBS_JOBID:-help}

exit
FINALPBS

cd ${dir}
# Make initial submit
chmod +x runpostpros${postfix}.sh ${scriptname} postpros${postfix}.sh
echo 'Submit to job scheduler'
qsub runpostpros${postfix}.sh

elif [ $jobflag == 'SBATCH' ] ; then

cat > ${dir}/runpostpros${postfix}.sh <<FINALSBATCH
#!/bin/sh
#SBATCH -J ${jobname}
#SBATCH -n 1
#SBATCH -t ${WT}
#SBATCH --output=postpro_${input}-%j.out
#SBATCH --error=postpro_${input}-%j.err
#SBATCH --mail-type=ALL
#SBATCH --mail-user=${email}
#SBATCH -p ${QUEUE}

source /etc/profile
cd ${dir}

srun -n1 -N1 -d${nodeNPU} ./postpros${postfix}.sh

exit
FINALSBATCH

cd ${dir}
# Make initial submit
chmod +x runpostpros${postfix}.sh ${scriptname} postpros${postfix}.sh
echo 'Submit to job scheduler'
sbatch runpostpros${postfix}.sh

fi

exit
