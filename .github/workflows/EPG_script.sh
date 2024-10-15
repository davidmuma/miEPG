#!/bin/bash

sed -i '/^ *$/d' epgs.txt
sed -i '/^ *$/d' canales.txt

rm -f EPG_temp*

 	while IFS=, read -r epg
	do
 		extension="${epg##*.}"
		if [ $extension = "gz" ]; then
			echo Descargando y descomprimiendo epg
			wget -O EPG_temp00.xml.gz -q ${epg}
      			gzip -d -f EPG_temp00.xml.gz
	  	else
			echo Descargando epg
			wget -O EPG_temp00.xml -q ${epg}
		fi
  	cat EPG_temp00.xml >> EPG_temp.xml
	done < epgs.txt

 	while IFS=, read -r old new logo
	do
		contar_channel="$(grep -c "channel=\"$old\"" EPG_temp.xml)"
		if [ $contar_channel -gt 1 ]; then
			sed -n "/<channel id=\"${old}\">/,/<\/channel>/p" EPG_temp.xml > EPG_temp01.xml
			sed -i '/<icon src/!d' EPG_temp01.xml
   			if [ "$logo" ]; then
	 			echo Nombre EPG: $old · Nuevo nombre: $new · Cambiando logo ··· $contar_channel coincidencias
     				echo '  </channel>' >> EPG_temp01.xml
	 			sed -i "1i\  <channel id=\"${new}\">" EPG_temp01.xml
				sed -i "2i\    <display-name>${new}</display-name>" EPG_temp01.xml
    				sed -i "s#<icon src=.*#<icon src=\"${logo}\" \/>#" EPG_temp01.xml
				sed -i "3i\    <icon src=\"${logo}\" \/>" EPG_temp01.xml  				
      			else
				echo Nombre EPG: $old · Nuevo nombre: $new · Manteniendo logo ··· $contar_channel coincidencias
    				echo '  </channel>' >> EPG_temp01.xml
      				sed -i "1i\  <channel id=\"${new}\">" EPG_temp01.xml
				sed -i "2i\    <display-name>${new}</display-name>" EPG_temp01.xml
   			fi
      			cat EPG_temp01.xml >> EPG_temp1.xml
			sed -i '$!N;/^\(.*\)\n\1$/!P;D' EPG_temp1.xml

			sed -n "/<programme.*\"${old}\"/,/<\/programme>/p" EPG_temp.xml > EPG_temp02.xml
			sed -i '/<programme/s/\">.*/\"/g' EPG_temp02.xml
			sed -i "s# channel=\"${old}\"##g" EPG_temp02.xml	
			sed -i "/<programme/a EPG_temp channel=\"${new}\">" EPG_temp02.xml
			sed -i ':a;N;$!ba;s/\nEPG_temp//g' EPG_temp02.xml
			cat EPG_temp02.xml >> EPG_temp2.xml
		else
			echo Saltando canal: $old ··· $contar_channel coincidencias
		fi
	done < canales.txt

date_stamp=$(date +"%d/%m/%Y %R")
echo '<?xml version="1.0" encoding="UTF-8"?>' > miEPG.xml
echo "<tv generator-info-name=\"miEPG $date_stamp\" generator-info-url=\"https://github.com/davidmuma/miEPG\">" >> miEPG.xml
cat EPG_temp1.xml >> miEPG.xml
cat EPG_temp2.xml >> miEPG.xml
echo '</tv>' >> miEPG.xml

rm -f EPG_temp*
