#!/bin/bash

#curl -L -o EPG_temp.xml "https://raw.githubusercontent.com/davidmuma/EPG_dobleM/master/guiaiptv.xml"

sed -i ':a; N; $!ba; s/<title lang=\"es\">\n/<title lang=\"es\">/g' EPG_temp.xml

sed -i '/^ *$/d' canales.txt
sed -i '/-INICIO,FICHERO-/d' canales.txt
sed -i '/-FIN,FICHERO-/d' canales.txt
sed -i '1i -INICIO,FICHERO-' canales.txt
sed -i '$a -FIN,FICHERO-' canales.txt

date_stamp=$(date +"%d/%m/%Y %R")
echo '<?xml version="1.0" encoding="UTF-8"?>' > EPG_personal.xml
echo "<tv generator-info-name=\"dobleM $date_stamp\" generator-info-url=\"t.me/EPG_dobleM\">" >> EPG_personal.xml

	while IFS=, read -r old new logo
	do
		echo Procesando channel y logos: $old ··· $new ··· $logo
		sed -n "/<channel id=\"$old\">/,/<\/channel>/p" EPG_temp.xml >> EPG_personal.xml
  		sed -i '/display-name/d' EPG_personal.xml
  		sed -i '/icon src/d' EPG_personal.xml
    		sed -i "s/$old/$new/" EPG_personal.xml
		sed -i "s|</channel>|\t<icon src=\" $log \" />\n\t</channel>|" EPG_personal.xml
	done < canales.txt
	
	while IFS=, read -r old new logo
	do
		echo Procesando programme: $old ··· $new
		sed -n "/<programme.*$old/,/<\/programme>/p" EPG_temp.xml >> EPG_personal.xml
		sed -i "s|channel=\"$old\"|channel=\"$new\"/" EPG_personal.xml
	done < canales.txt

echo '</tv>' >> EPG_personal.xml
