#!/bin/bash

curl -L -o guiaiptv.xml "https://raw.githubusercontent.com/davidmuma/EPG_dobleM/master/guiaiptv.xml"

sed -i ':a; N; $!ba; s/<title lang=\"es\">\n/<title lang=\"es\">/g' guiaiptv.xml

sed -i '/^ *$/d' nomxml.txt
sed -i '/-INICIO,FICHERO-/d' nomxml.txt
sed -i '/-FIN,FICHERO-/d' nomxml.txt
sed -i '1i -INICIO,FICHERO-' nomxml.txt
sed -i '$a -FIN,FICHERO-' nomxml.txt

date_stamp=$(date +"%d/%m/%Y %R")
echo '<?xml version="1.0" encoding="UTF-8"?>' > EPG_personal.xml
echo "<tv generator-info-name=\"dobleM $date_stamp\" generator-info-url=\"t.me/EPG_dobleM\">" >> EPG_personal.xml

	while IFS=, read -r old new logo
	do
		echo Procesando channel y logos: $old ··· $new ··· $logo
		sed -n '/<channel id=\"'$old'"/,/<\/channel>/p' EPG_personal.xml >> EPG_personal.xml
		sed -i "s/$old/$new/" EPG_personal.xml
		sed -i "s#$new<\/display-name>#$new<\/display-name>\n\t<icon src=\"$logo\" \/>#" EPG_personal.xml
	done < nomxml.txt
	
	while IFS=, read -r old new logo
	do
		echo Procesando programme: $old ··· $new
		sed -n '/<programme.*"'$old'">/,/<\/programme>/p' EPG_personal.xml >> EPG_personal.xml
		sed -i "s/channel=\"$old\"/channel=\"$new\"/" EPG_personal.xml
	done < nomxml.txt

echo '</tv>' >> EPG_personal.xml

git add .
git commit -m "EPG_personal.xml"
git push