#!/bin/bash

curl -L -o EPG_temp.xml "https://raw.githubusercontent.com/davidmuma/EPG_dobleM/master/guiaiptv.xml"

sed -i '/^ *$/d' canales.txt

	while IFS=, read -r old new logo
	do
		contar_channel="$(grep -c "channel=\"$old\"" EPG_temp.xml)"
		if [ $contar_channel -gt 1 ]; then
			echo Procesando canal: $old ··· $contar_channel coincidencias
			
			sed -n "/<channel id=\"${old}\">/,/<\/channel>/p" EPG_temp.xml >> EPG_temp1.xml
			sed -i '/display-name/d' EPG_temp1.xml
			sed -i '/icon src/d' EPG_temp1.xml
			sed -i "s/${old}/${new}/" EPG_temp1.xml
			sed -i "s#<\/channel>#\t<icon src=\"${logo}\" />\n  <\/channel>#" EPG_temp1.xml
			
			sed -n "/<programme.*${old}\">/,/<\/programme>/p" EPG_temp.xml >> EPG_temp2.xml
			sed -i "s# channel=\"${old}\"# channel=\"${new}\"#" EPG_temp2.xml
			
		else
			echo Saltando canal: $old ··· $contar_channel coincidencias
		fi	
	done < canales.txt

date_stamp=$(date +"%d/%m/%Y %R")
echo '<?xml version="1.0" encoding="UTF-8"?>' > miEPG.xml
echo "<tv generator-info-name=\"miEPG $date_stamp\" generator-info-url=\"t.me/miEPG\">" >> miEPG.xml
cat EPG_temp1.xml >> miEPG.xml
cat EPG_temp2.xml >> miEPG.xml
echo '</tv>' >> miEPG.xml

rm -f EPG_temp.xml
rm -f EPG_temp1.xml
rm -f EPG_temp2.xml
