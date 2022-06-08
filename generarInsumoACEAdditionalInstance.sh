#!/bin/bash
export BROKER=`mqsilist| grep Broker | sed 's/\s\+/,/g' | sed "s/'//g" |cut -d , -f3`
export IP=`hostname -I | awk '{ print $1 }'`
BrokerName=$BROKER
fecha2=`date +%Y%m%d%H%M%S`
archivolog=$fecha2'-'$IP'-mqsilist.log'
archivoInicial=$fecha2'-broker.txt'

mqsilist $BrokerName -r -d2 > $archivolog

while read line
do
  if [[ ("$line" == *"Message flow"*)  && ("$line" == *"running"*) ]]; then
       messageflow=${line:24}
       #flow=`echo ${messageflow} | cut -d"'" -f1`
       echo "MF, $messageflow, running'" >> $archivoInicial
  elif [[ ("$line" == *"Message flow"*)  && ("$line" != *"running"*) ]]; then
       messageflow=${line:24}
       #flow=`echo ${messageflow} | cut -d"'" -f1`
       echo "MF,$messageflow, stopped'" >> $archivoInicial
  fi
  if [[ "$line" == *"Additional thread instances"* ]]; then
      inst=${line:30};
      instAdd=`echo ${inst} | cut -d"'" -f1`
      echo "IA,$instAdd'" >> $archivoInicial
  fi
  #### no se evaluan los jar
  #if [[ ("$line" == *"BIP1290I"*) && ("$line" == *".jar"*) ]]; then
  #    jarFile=${line:16};
  #    #echo $jarFile
  #    jar=`echo ${jarFile} | cut -d"'" -f1`
  #    #echo jar >> archivoInicial
  #    echo "JA '$jar'" >> archivoInicial
  #fi
done < $archivolog

sed "s/' on execution group '/,/g" $archivoInicial  > temp.txt && mv temp.txt $archivoInicial
sed "s/' is running. (Application '/,/g" $archivoInicial  > temp.txt && mv temp.txt $archivoInicial
sed "s/' is stopped. (Application '/,/g" $archivoInicial  > temp.txt && mv temp.txt $archivoInicial
sed "s/', Library ''), running'//g" $archivoInicial  > temp.txt && mv temp.txt $archivoInicial
sed "s/', Library ''), stopped'//g" $archivoInicial  > temp.txt && mv temp.txt $archivoInicial
sed "s/,0/,1/g" $archivoInicial  > temp.txt && mv temp.txt $archivoInicial

archivoFinal=$fecha2'-'$IP'-actualAditionalInstance.csv'

while read line
do
        if [[ "$line" == *"MF"* ]]; then
                mf=${line:3};
                mfe=`echo ${mf} | cut -d"'" -f1`
                final="$ege,$mfe"
                #echo $final
        fi
        if [[ "$line" == *IA""* ]]; then
                ia=${line:3};
                iae=`echo ${ia} | cut -d"'" -f1`
                #echo $iae
                final="$ege,$mfe,$iae"
                echo $final >> $archivoFinal
        fi
done < $archivoInicial

sed "s/^/\/var\/mqsi\/components\/,"$BROKER"/g" $archivoFinal  > temp.txt && mv temp.txt $archivoFinal

