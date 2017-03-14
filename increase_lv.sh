#!/bin/bash
## SCRIPT: wrapper lvextend for CESI team

#########################################
## VARIABLES / FUNCTIONS DECLARATION
#########################################
BASENAME=$(basename $0)
VGARG=$1
LVARG=$2
SIZEARG=$3
SIZEARGm=$(echo $SIZEARG |egrep 'm|M'|cut -d 'M' -f1  |cut -d 'm' -f1)
SIZEARGg=$(echo $SIZEARG |egrep 'g|G'|cut -d 'G' -f1  |cut -d 'g' -f1)
VGFREEm=$(vgs -o vg_name,vg_free |grep $VGARG |grep -i m$ |awk '{print $2}' |cut -d "," -f1)
VGFREEg=$(vgs -o vg_name,vg_free |grep $VGARG |grep -i g$ |awk '{print $2}' |cut -d "," -f1)
WORKDIR="/home/depot/suptec/"
PLATEFORM=$(dmidecode -s system-product-name)
DATETIME=$(date -I)
HOST=$(hostname)
ERROR_OUT=$WORKDIR/error_$HOST-$DATETIME.log
BANNER="Be carefull, don't use this script in production environement !"
VGNAME=$(vgs --noheadings -o vg_name $1 |sed -e "s/^ *//g")
#VGRESULT=$(vgs --noheadings -o vg_free $LVGARG)
VGRESULT=$(vgs --units m -o vg_name,vg_free $VGARG --noheadings --nosuffix |cut -d "," -f1)
START_GREEN="\033[32m"
START_RED="\033[31m"
START_PINK="\033[35;1;4;5m"
ENDCOLOR="\033[0m"
NB_ARG="$(echo $#)"
##############
## FUNCTIONS #
##############
fn_chk()
{
if [ $? != 0 ]; then echo "Warning! somethings went wrong !" ; fi
}

## verification du nombre de parametres du script  ##
fn_chk_nb_param()
{
if [[ $NB_ARG -ne 3 ]]; then
 echo -e "$START_RED Usage: $0  <VG> <LV> <SIZE> $ENDCOLOR" &&
 echo -e "$START_GREEN Example : $0 systemVG  /dev/systemVG/backupLV 100M $ENDCOLOR"
 exit 1
fi
}

##check if VG is available on the system  ##
fn_vg_check()
{
if [[ $VGARG = $VGNAME ]]; then
 #echo "$VGARG : present"
 echo -e "$START_GREEN $VGARG : present $ENDCOLOR"
  else
 echo -e "$START_RED $VGARG is not VG Available, please check again $ENDCOLOR"
 echo -e "$START_GREEN VG Availables on this host are :\n$(vgs --noheadings -o vg_name) $ENDCOLOR"
 exit 1
fi
}

fn_check_lv_exsting()
{
#echo "check if LV belongs to VG"
lvs $LVARG |grep $VGARG >/dev/null
#$TESTLV #2>&1 >/dev/null
if [ $? -ne 0 ]; then
 echo  -e "\033[31m $LVARG doesnt't belong to $VGARG $ENDCOLOR" &&
  #echo -e " $START_GREEN LV availables on this host are :\n$(lvs --noheadings -o lv_name) $ENDCOLOR"
  echo -e " $START_GREEN LV availables on this host are :\n$(lvscan |cut -d "'" -f2) $ENDCOLOR"
   exit 1
 else
  echo -e " $START_GREEN $LVARG belongs to $VGARG $ENDCOLOR"
fi
}

fn_check_vgsize()
{
echo -e "size on available $VGARG :\n$VGRESULT"
if [ -z  $SIZEARGg ]; then
FINALVALUE=$SIZEARGm && echo $FINALVALUE >/tmp/FINALVALUE.$$
 elif [ -z  $SIZEARGm ]; then
FINALVALUE=$(expr $SIZEARGg \* 1000) && echo $FINALVALUE >/tmp/FINALVALUE.$$
fi
}

fn_compare()
{
RESULTSIZE=$(cat /tmp/FINALVALUE.$$)
RESULTVGSIZE=$(echo $VGRESULT |awk '{print $2}')
SPACEAVAILABLE=$(expr $RESULTVGSIZE - $RESULTSIZE)
echo SPACEAVAILABLE $SPACEAVAILABLE

if [ $SPACEAVAILABLE -lt 0 ];
then echo "Space Available is not enought"; exit 1
fi
#VGRESULT=$(echo $VGRESULT|awk '{print $2}')
#echo $VGRESULT
#echo $FINALVALUE
#EXTEND_STATUS=$(expr $VGRESULT - $FINALVALUE)
#echo $EXTEND_STATUS

#if [[ $EXTEND_STATUS -gt 1 ]] ; then
 #       echo "Extend possible on LV : $EXTEND_STATUS"
#fi

#if [[ "$VGRESULT" -lt "$SIZEARG" ]]; then
# echo "you can make an extend"
#  else echo "please ask available storage to MITI Team"
#fi
}

## Check redhat release RHEL 5/6/7##
# RHEL5/6 : EXT(3,4) => lvextend + resize2fs
# RHEL7 : XFS => lvextend + xfs_growfs
fn_chk_release()
{
##check OS release
RH_RELEASE=$(cat /etc/redhat-release |awk '{FS=" "; print $7}'|cut -d "." -f1)

 if [[ $RH_RELEASE  == 5 ]]  ; then
      rc=EXT
   elif
    [[ $RH_RELEASE  == 6 ]]  ; then
      rc=EXT
     elif
    [[ $RH_RELEASE  == 7 ]]  ; then
      rc=XFS
     else
    echo "OS unsupported"
 fi
## choose fs type according to OS release
if [[ $rc=XFS  ]]; then
    echo "XFSGROW is the method : lvextend -L +$SIZEARG $LVARG && xfs_growfs $LVARG"
 elif
  [[ $rc=EXT ]]; then
    echo "use EXT: lvextend -L +$SIZEARG $LVARG && resize2fs  $LVARG"
 else
    echo "extension de FS: non applicable"
fi
}

################
# MAIN PROGRAM
################

 #########################################
 ## PREPARE ENVIRONEMENT
 #########################################

#if [ ! -d $WORKDIR ]; then  mkdir -p $WORKDIR && chmod -R 755 $WORKDIR ; fi
#if [ -f  ]; then > $BASENAME_OUTPUT; fi
#exec 2>> $ERROR_OUT
#fn_chk

 #########################################
 ## MAIN PROGRAM
 #########################################
echo -e "$START_PINK $BANNER $ENDCOLOR"
#sleep 3
fn_chk_nb_param

echo "fn_vg_check"
fn_vg_check

echo "fn_check_lv_exsting"
fn_check_lv_exsting

echo "fn_check_vgsize"
fn_check_vgsize

echo "fn_compare"
fn_compare
fn_chk_release

