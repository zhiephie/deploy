#!/bin/sh

tanggal=`date +%Y%m%d`
PATHFILE=$2
TEMPDIR=../tmp
LISTFILE=$TEMPDIR/lst
LISTDEST=$TEMPDIR/dlst



deploy(){

	if [ ! -d $TEMPDIR ];then
		mkdir $TEMPDIR
	fi
	
	ls -d -1 *.*|grep -v deploy.sh|awk -v prefix1="$PWD/" -v prefix2="$PATHFILE/" '{print "cp " prefix1$0 " " prefix2 $0}' > $LISTFILE
	ls -d -1 */*|grep -v deploy.sh|awk -v prefix1="$PWD/" -v prefix2="$PATHFILE/" '{print "cp " prefix1$0 " " prefix2 $0}' >> $LISTFILE

	ls -l *.* |awk -v prefix="$PATHFILE/" '{print prefix$9}' > $LISTDEST
	ls -d -1 */*.* |awk -v prefix="$PATHFILE/" '{print prefix$0}' >> $LISTDEST

	#do backup
		while IFS='' read -r line || [[ -n "$line" ]]; do
			if [ -f $line ];then
				echo ">>BACKUP: $line -> ${line}_$tanggal"
				cp $line ${line}_$tanggal
			fi
		done < $LISTDEST


	#do deploy
		while IFS='' read -r line || [[ -n "$line" ]]; do
			echo ">>DEPLOY: $line"
		done < $LISTFILE
		sh $LISTFILE
}


rollback(){
	if [ ! -d $TEMPDIR ];then
		mkdir $TEMPDIR
	fi
	
	ls -d -1 *.*|grep -v deploy.sh|awk -v prefix="$PATHFILE/" -v tgl="$tanggal" '{print "cp " prefix$0"_" tgl " " prefix$0}' > $LISTFILE
	ls -d -1 */*|grep -v deploy.sh|awk -v prefix="$PATHFILE/" -v tgl="$tanggal" '{print "cp " prefix$0"_" tgl " " prefix$0}' >> $LISTFILE
	
	#do rollback
		while IFS='' read -r line || [[ -n "$line" ]]; do
			echo ">>ROLLBACK: $line"
		done < $LISTFILE
		sh $LISTFILE
}

case "$1" in
   *deploy)
		if [ -z $2 ];then
			echo $"$0: [OPTION] [PATH TO DEPLOY]"
			echo "OPTION:"
			echo "  deploy"
			echo "  rollback"
			echo "EXAMPLE:"
			echo "$0 deploy /usr/local/apache/htdocs"
			exit 1
		fi
        echo "DEPLOYING FILES on $PWD to $2"
		deploy
        ;;
   *rollback)
        echo "ROLLBACK FILES on $2"
		rollback
        ;;
   *)
        echo $"$0: [OPTION] [PATH TO DEPLOY]"
        echo "OPTION:"
		echo "  deploy"
		echo "  rollback"
		echo "EXAMPLE:"
		echo "$0 deploy /usr/local/apache/htdocs"
		exit 1
        ;;
esac

#some cleaning
rm -f $LISTFILE
rm -f $LISTDEST
rm -rf $TEMPDIR
	
#repair permission
chown -R apache.apache $PATHFILE
chmod -R 775 $PATHFILE
