#!/bin/bash
SCRIPT=$(readlink -f $0)
DIR_SCRIPT=`dirname $SCRIPT`

curl -L -o guiaiptv.xml "https://raw.githubusercontent.com/davidmuma/EPG_dobleM/master/guiaiptv.xml"

sed -i ':a; N; $!ba; s/<title lang=\"es\">\n/<title lang=\"es\">/g' $DIR_SCRIPT/guiaiptv.xml

sed -i '/^ *$/d' $DIR_SCRIPT/nomxml.txt
sed -i '/-INICIO,FICHERO-/d' $DIR_SCRIPT/nomxml.txt
sed -i '/-FIN,FICHERO-/d' $DIR_SCRIPT/nomxml.txt
sed -i '1i -INICIO,FICHERO-' $DIR_SCRIPT/nomxml.txt
sed -i '$a -FIN,FICHERO-' $DIR_SCRIPT/nomxml.txt

date_stamp=$(date +"%d/%m/%Y %R")
echo '<?xml version="1.0" encoding="UTF-8"?>' > $DIR_SCRIPT/EPG_personal.xml
echo "<tv generator-info-name=\"dobleM $date_stamp\" generator-info-url=\"t.me/EPG_dobleM\">" >> $DIR_SCRIPT/EPG_personal.xml

	while IFS=, read -r old new logo
	do
		echo Procesando channel y logos: $old ··· $new ··· $logo
		sed -n '/<channel id=\"'$old'"/,/<\/channel>/p' $DIR_SCRIPT/EPG_personal.xml >> $DIR_SCRIPT/EPG_personal.xml
		sed -i "s/$old/$new/" $DIR_SCRIPT/EPG_personal.xml
		sed -i "s#$new<\/display-name>#$new<\/display-name>\n\t<icon src=\"$logo\" \/>#" $DIR_SCRIPT/EPG_personal.xml
	done < $DIR_SCRIPT/nomxml.txt
	
	while IFS=, read -r old new logo
	do
		echo Procesando programme: $old ··· $new
		sed -n '/<programme.*"'$old'">/,/<\/programme>/p' $DIR_SCRIPT/EPG_personal.xml >> $DIR_SCRIPT/EPG_personal.xml
		sed -i "s/channel=\"$old\"/channel=\"$new\"/" $DIR_SCRIPT/EPG_personal.xml
	done < $DIR_SCRIPT/nomxml.txt

echo '</tv>' >> $DIR_SCRIPT/EPG_personal.xml

git add .
git commit -m "EPG_personal.xml"
git push
