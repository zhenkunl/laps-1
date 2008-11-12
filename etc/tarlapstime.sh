#!/bin/sh

# For an hourly cycle a good time to run this would be 110 minutes later
# with a MINAGE of 48 minutes and a MAXAGE of 112 minutes

# First command line argument is the LAPS_DATA_ROOT

# Second command line argument is the laps time in yydddhhmm format

# Third argument is for expanded output [expand,noexpand]

# Fourth argument is for static files [static,nostatic]

# Fifth argument is minimum age (minutes) to keep LGA/LGB files

# Sixth argument is maximum age (minutes) to keep LGA/LGB files

LAPS_DATA_ROOT=$1
time=$2
EXPAND=$3
STATIC=$4
MINAGE=$5
MAXAGE=$6

echo "LAPS_DATA_ROOT = $LAPS_DATA_ROOT"
echo "time = $time"
echo "EXPAND = $EXPAND"
echo "STATIC = $STATIC"
echo "MINAGE = $MINAGE"
echo "MAXAGE = $MAXAGE"

LOGDIR=$LAPS_DATA_ROOT/log

#Create list of lapsprd output files to be potentially tarred up for Web access
echo " "
echo "Create list of lapsprd output files to be potentially tarred up for Web access"

hour=`echo $time  | cut -c6-7`
YYDDDHH=`echo $time  | cut -c1-7`

echo "Tarring up LAPS in $LAPS_DATA_ROOT for $time"

cd $LAPS_DATA_ROOT

rm -f lapstar.txt
touch lapstar.txt

#LAPS Data Files
ls -1 time/*.dat                                          > lapstar.txt

# Lapsprd files (except LGA, LGB, FUA, FSF)
find ./lapsprd -type f -name "$YYDDDHH??.*"     -print   >> lapstar.txt

# LGA/LGB files (use MINAGE/MAXAGE)
find ./lapsprd/lg?     -name "*.lg?" ! -cmin +$MAXAGE -cmin +$MINAGE -print >> lapstar.txt

# Log & Wgi files
find ./log     -type f -name "*.???.$YYDDDHH??" -print   >> lapstar.txt

# Static files
if test "$STATIC" = static; then
    echo "including static files"
    ls -1 static/static.nest7grid                        >> lapstar.txt
    ls -1 static/*.nl                                    >> lapstar.txt
    ls -1 static/www/*                                   >> lapstar.txt
else
    echo "not including static files"
fi

ls -l $LAPS_DATA_ROOT/lapstar.txt

if test "$EXPAND" = noexpand; then
    echo "current directory is `pwd`"
    echo "making tar file $LAPS_DATA_ROOT/lapstar_$YYDDDHH.tar"
    echo "tar cvf $LAPS_DATA_ROOT/laps_$time.tar -T $LAPS_DATA_ROOT/lapstar.txt"
          tar cvf $LAPS_DATA_ROOT/laps_$time.tar -T $LAPS_DATA_ROOT/lapstar.txt
    ls -l $LAPS_DATA_ROOT/laps_$time.tar

else
    echo "cp to $LAPS_DATA_ROOT/lapstar_$YYDDDHH expanded directory"
    rm -rf $LAPS_DATA_ROOT/lapstar_*
    mkdir -p $LAPS_DATA_ROOT/lapstar_$YYDDDHH
    tar -T lapstar.txt -cf - | (cd $LAPS_DATA_ROOT/lapstar_$YYDDDHH;  tar xfBp -)
    pwd

fi




