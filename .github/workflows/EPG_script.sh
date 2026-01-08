#!/bin/bash
# ============================================================================== 
# Script: miEPG.sh 
# Versión: 3.5
# Función: Combina múltiples XMLs, renombra canales, cambia logos y ajusta hora 
# ============================================================================== 

sed -i '/^ *$/d' epgs.txt
sed -i '/^ *$/d' canales.txt

rm -f EPG_temp* canales_epg*.txt

epg_count=0

echo "--- DESCARGANDO EPGS ---"

while IFS=, read -r epg; do
	((epg_count++))
    extension="${epg##*.}"
    if [ "$extension" = "gz" ]; then
        echo "Descargando y descomprimiendo: $epg"
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
        echo "Descargando: $epg"
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

echo "--- PROCESANDO CANALES ---"

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

# Leer etiquetas de variables.txt
etiquetas_sed=""
if [ -f variables.txt ]; then
    # Extrae lo que hay después de display-name=, quita espacios y separa por comas
    sufijos=$(grep "display-name=" variables.txt | cut -d'=' -f2 | sed 's/, /,/g')
    IFS=',' read -r -a array_etiquetas <<< "$sufijos"
    
    # Creamos una lista de comandos para sed (se insertarán en la línea 3 en adelante)
    linea_ins=3
    for etiq in "${array_etiquetas[@]}"; do
        etiq_clean=$(echo "$etiq" | xargs) # Limpia espacios
        if [ -n "$etiq_clean" ]; then
            etiquetas_sed="${etiquetas_sed}${linea_ins}i\  <display-name>${new} ${etiq_clean}</display-name>\n"
            ((linea_ins++))
        fi
    done
fi

for linea in "${canales[@]}"; do
    IFS=',' read -r old new logo offset <<< "$linea"
    contar_channel="$(grep -c "channel=\"$old\"" EPG_temp.xml)"
	if [ "${contar_channel:-0}" -gt 0 ]; then
	
        # 1. Extraer el logo original por si no hay uno nuevo en canales.txt
        logo_original=$(sed -n "/<channel id=\"${old}\">/,/<\/channel>/p" EPG_temp.xml | grep "<icon src" | head -1 | sed 's/^[[:space:]]*//')
        
        # 2. Definir qué logo usar (el nuevo o el extraído)
        logo_final=""
        if [ -n "$logo" ]; then
            logo_final="    <icon src=\"${logo}\" />"
        else
            logo_final="    $logo_original"
        fi

        # 3. Construir el nuevo archivo de canal desde cero (EPG_temp01.xml)
        echo "  <channel id=\"${new}\">" > EPG_temp01.xml
        
        # 4. Insertar los nombres basados en variables.txt
        if [ -f variables.txt ]; then
            sufijos=$(grep "display-name=" variables.txt | cut -d'=' -f2 | sed 's/, /,/g')
            IFS=',' read -r -a array_etiquetas <<< "$sufijos"
            
            for etiq in "${array_etiquetas[@]}"; do
                etiq_clean=$(echo "$etiq" | xargs)
                if [ -n "$etiq_clean" ]; then
                    echo "    <display-name>${new} ${etiq_clean}</display-name>" >> EPG_temp01.xml
                fi
            done
        else
            # Si no hay variables.txt, ponemos al menos el nombre base
            echo "    <display-name>${new}</display-name>" >> EPG_temp01.xml
        fi

        # 5. Insertar el logo al final
        [ -n "$logo_final" ] && echo "$logo_final" >> EPG_temp01.xml
        echo '  </channel>' >> EPG_temp01.xml

        # Logs informativos
        if [ -n "$logo" ]; then
            echo "Nombre EPG: $old · Nuevo nombre: $new · Cambiando logo ··· $contar_channel coincidencias"
        else
            echo "Nombre EPG: $old · Nuevo nombre: $new · Manteniendo logo ··· $contar_channel coincidencias"
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

# 1. Recuperar programas guardados anteriormente (Base de datos acumulada)
if [ -f "epg_acumulado.xml" ]; then
    echo "Fusing: Mezclando con programas de días anteriores..."
    # Extraemos solo los bloques <programme> del historial para no romper el XML
    sed -n '/<programme/,/<\/programme>/p' "epg_acumulado.xml" >> EPG_temp2.xml
fi

# 2. Calcular fecha de corte según variables.txt
dias_limite=$(grep "dias-pasados=" variables.txt | cut -d'=' -f2 | xargs)
dias_limite=${dias_limite:-0}
# Obtenemos la fecha de hace N días en formato XMLTV (YYYYMMDD000000)
fecha_corte=$(date -d "$dias_limite days ago" +"%Y%m%d000000")

echo "Limpieza: Manteniendo programas desde $fecha_corte (Límite: $dias_limite días)"

# 3. Filtrar programas viejos y eliminar duplicados exactos
# Usamos Perl para procesar el archivo EPG_temp2.xml de forma eficiente
perl -i -ne '
    BEGIN { $corte = "'$fecha_corte'"; %visto=(); $borrados=0; }
    if (/<programme start="(\d{14})[^"]+" stop="[^"]+" channel="([^"]+)">/) {
        $inicio = $1; $canal = $2;
        $llave = "$inicio-$canal"; # Identificador único para evitar duplicados
        if ($inicio >= $corte && !$visto{$llave}++) {
            $imprimir = 1;
        } else {
            $imprimir = 0;
            $borrados++;
        }
    }
    print if $imprimir;
    if (/<\/programme>/) { $imprimir = 0; }
    END { print STDERR "  -> Programas antiguos o duplicados eliminados: $borrados\n"; }
' EPG_temp2.xml

# --- ENSAMBLADO FINAL DEL ARCHIVO miEPG.xml ---

date_stamp=$(date +"%d/%m/%Y %R")
{
    echo '<?xml version="1.0" encoding="UTF-8"?>'
    echo "<tv generator-info-name=\"miEPG v3.5\" generator-info-url=\"https://github.com/davidmuma/miEPG\">"
    
    # Insertar los canales (con sus variantes y logos que procesamos antes)
    [ -f EPG_temp1.xml ] && cat EPG_temp1.xml
    
    # Insertar los programas (nuevos + antiguos filtrados)
    [ -f EPG_temp2.xml ] && cat EPG_temp2.xml
    
    echo '</tv>'
} > miEPG.xml

# Actualizar la base de datos acumulada para la ejecución de mañana
cp miEPG.xml epg_acumulado.xml

# Limpieza de archivos temporales de esta sesión
rm -f EPG_temp* echo "Finalizado: miEPG.xml generado correctamente."
