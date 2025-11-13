#!/bin/bash
# ============================================================================== 
# Script: miEPG.sh 
# Versión: 3.1
# Función: Combina múltiples XMLs, renombra canales, cambia logos y ajusta hora 
# ============================================================================== 

sed -i '/^ *$/d' epgs.txt
sed -i '/^ *$/d' canales.txt

rm -f EPG_temp* canales_epg*.txt

epg_count=0

while IFS=, read -r epg; do
	((epg_count++))
    extension="${epg##*.}"
    if [ "$extension" = "gz" ]; then
        echo "Descargando y descomprimiendo EPG: $epg"
        wget -O EPG_temp00.xml.gz -q "$epg"
        if [ ! -s EPG_temp00.xml.gz ]; then
            echo "  Error: El archivo descargado está vacío o no se descargó correctamente: $epg"
            continue
        fi
        if ! gzip -t EPG_temp00.xml.gz 2>/dev/null; then
            echo "  Error: El archivo no es un gzip válido: $epg"
            continue
        fi
        gzip -d -f EPG_temp00.xml.gz
    else
        echo "Descargando EPG: $epg"
        wget -O EPG_temp00.xml -q "$epg"
        if [ ! -s EPG_temp00.xml ]; then
            echo "  Error: El archivo descargado está vacío o no se descargó correctamente: $epg"
            continue
        fi
    fi
	if [ -f EPG_temp00.xml ]; then
        listado="canales_epg${epg_count}.txt"
        echo "Generando listado de canales: $listado"
        echo "# Fuente: $epg" > "$listado"
		awk '
		/<channel / {
		    match($0, /id="([^"]+)"/, a); id=a[1]; name=""; logo="";
		}
		/<display-name[^>]*>/ && name == "" {
		    match($0, /<display-name[^>]*>([^<]+)<\/display-name>/, a);
		    name=a[1];
		}
		/<icon src/ {
		    match($0, /src="([^"]+)"/, a); logo=a[1];
		}
		/<\/channel>/ {
		    print id "," name "," logo;
		}
		' EPG_temp00.xml >> "$listado"
		cat EPG_temp00.xml >> EPG_temp.xml
        sed -i 's/></>\n</g' EPG_temp.xml		
    fi	
done < epgs.txt

mapfile -t canales < canales.txt
for i in "${!canales[@]}"; do
    IFS=',' read -r old new logo offset <<< "${canales[$i]}"
    if [[ "$logo" =~ ^[+-]?[0-9]+$ ]] && [[ -z "$offset" ]]; then
        offset="$logo"
        logo=""
    fi
    new="${new:-}"
    logo="${logo:-}"
    offset="${offset:-}"
    canales[$i]="$old,$new,$logo,$offset"
done

for linea in "${canales[@]}"; do
    IFS=',' read -r old new logo offset <<< "$linea"
    contar_channel="$(grep -c "channel=\"$old\"" EPG_temp.xml)"
    if [ "${contar_channel:-0}" -gt 0 ]; then
        sed -n "/<channel id=\"${old}\">/,/<\/channel>/p" EPG_temp.xml > EPG_temp01.xml
        sed -i '/<icon src/!d' EPG_temp01.xml
        if [ "$logo" ]; then
            echo "Nombre EPG: $old · Nuevo nombre: $new · Cambiando logo ··· $contar_channel coincidencias"
            echo '  </channel>' >> EPG_temp01.xml
            sed -i "1i\  <channel id=\"${new}\">" EPG_temp01.xml
            sed -i "2i\    <display-name>${new}</display-name>" EPG_temp01.xml
            sed -i "s#<icon src=.*#<icon src=\"${logo}\" />#" EPG_temp01.xml
        else
            echo "Nombre EPG: $old · Nuevo nombre: $new · Manteniendo logo ··· $contar_channel coincidencias"
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
  
		if [[ "$offset" =~ ^[+-]?[0-9]+$ ]]; then
			echo "  Ajustando hora en el canal $new ($offset horas)"
			export OFFSET="$offset"
			export NEW_CHANNEL="$new"
            
			perl -MDate::Parse -MDate::Format -i'' -pe '
			BEGIN {
				$offset_sec = $ENV{OFFSET} * 3600;
				$new_channel_name = $ENV{NEW_CHANNEL};
			}
			if (/<programme start="([^"]+) (\+?\d+)" stop="([^"]+) (\+?\d+)" channel="[^"]+">/) {
				my ($start_time_str, $start_tz, $stop_time_str, $stop_tz) = ($1, $2, $3, $4);

				my $start_fmt = substr($start_time_str, 0, 4) . "-" .
								substr($start_time_str, 4, 2) . "-" .
								substr($start_time_str, 6, 2) . " " .
								substr($start_time_str, 8, 2) . ":" .
								substr($start_time_str, 10, 2) . ":" .
								substr($start_time_str, 12, 2);

				my $stop_fmt = substr($stop_time_str, 0, 4) . "-" .
							   substr($stop_time_str, 4, 2) . "-" .
							   substr($stop_time_str, 6, 2) . " " .
							   substr($stop_time_str, 8, 2) . ":" .
							   substr($stop_time_str, 10, 2) . ":" .
							   substr($stop_time_str, 12, 2);

				my $start = str2time("$start_fmt $start_tz") + $offset_sec;
				my $stop = str2time("$stop_fmt $stop_tz") + $offset_sec;

				my $start_formatted = time2str("%Y%m%d%H%M%S $start_tz", $start);
				my $stop_formatted = time2str("%Y%m%d%H%M%S $stop_tz", $stop);

				s/<programme start="[^"]+" stop="[^"]+" channel="[^"]+">/<programme start="$start_formatted" stop="$stop_formatted" channel="$new_channel_name">/;
			}
			' EPG_temp02.xml
		fi
  
        cat EPG_temp02.xml >> EPG_temp2.xml
  
    else
        echo "Saltando canal: $old ··· $contar_channel coincidencias"
    fi
done

date_stamp=$(date +"%d/%m/%Y %R")
echo '<?xml version="1.0" encoding="UTF-8"?>' > miEPG.xml
echo "<tv generator-info-name=\"miEPG $date_stamp\" generator-info-url=\"https://github.com/davidmuma/miEPG\">" >> miEPG.xml
cat EPG_temp1.xml >> miEPG.xml
cat EPG_temp2.xml >> miEPG.xml
echo '</tv>' >> miEPG.xml

rm -f EPG_temp*
