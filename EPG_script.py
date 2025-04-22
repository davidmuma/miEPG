import os
import gzip
import shutil
import urllib.request
import xml.etree.ElementTree as ET
from datetime import datetime
import time
import sys

# Forzar zona horaria a España (funciona en Linux/GitHub Actions)
if sys.platform != 'win32':
    os.environ['TZ'] = 'Europe/Madrid'
    time.tzset()  # Solo en Unix
else:
    print("tzset no disponible en Windows. Usa pytz/zoneinfo.")


INPUT_FILE = 'urls.txt'
FINAL_XML = 'EPG.xml'
LOG_FILE = 'EPG.log'

def log(message):
    timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    with open(LOG_FILE, 'a', encoding='utf-8') as log_file:
        log_file.write(f"[{timestamp}] {message}\n")

def download_file(url, dest_filename):
    print(f"Descargando: {url}")
    with urllib.request.urlopen(url) as response:
        with open(dest_filename, 'wb') as out_file:
            shutil.copyfileobj(response, out_file)

def decompress_gz(src, dest):
    print(f"Descomprimiendo archivo: {src}")
    with gzip.open(src, 'rb') as f_in:
        with open(dest, 'wb') as f_out:
            shutil.copyfileobj(f_in, f_out)

def extract_elements(xml_file):
    channels = []
    programs = []

    # Detectar si es horario de verano (DST)
    is_dst = time.localtime().tm_isdst > 0
    offset = '-0200' if is_dst else '+0000'
    print(f"Usando offset horario: {offset}")

    tree = ET.parse(xml_file)
    root = tree.getroot()
    for elem in root:
        if elem.tag == 'channel':
            channels.append(ET.tostring(elem, encoding='unicode'))
        elif elem.tag == 'programme':
            for attr in ['start', 'stop']:
                if attr in elem.attrib:
                    ts = elem.attrib[attr]
                    elem.attrib[attr] = ts[:14] + f' {offset}'
            programs.append(ET.tostring(elem, encoding='unicode'))
    return channels, programs

def main():
    all_channels = []
    all_programs = []

    if not os.path.exists(INPUT_FILE):
        log(f"[ERROR] No se encontró el archivo {INPUT_FILE}")
        print(f"❌ No se encontró el archivo {INPUT_FILE}")
        return

    with open(INPUT_FILE, 'r', encoding='utf-8') as file:
        urls = [line.strip() for line in file if line.strip()]

    for i, url in enumerate(urls):
        base_filename = f'temp_{i}.xml'
        try:
            if url.endswith('.gz'):
                gz_filename = base_filename + '.gz'
                download_file(url, gz_filename)
                decompress_gz(gz_filename, base_filename)
                os.remove(gz_filename)
            else:
                download_file(url, base_filename)

            ch, pr = extract_elements(base_filename)
            all_channels.extend(ch)
            all_programs.extend(pr)

            print(f"✅ EPG procesado correctamente: {url} (Canales: {len(ch)}, Programas: {len(pr)})")

        except Exception as e:
            log(f"[ERROR] Error procesando {url}: {e}")
            print(f"❌ Error procesando {url}: {e}")
        finally:
            if os.path.exists(base_filename):
                os.remove(base_filename)

    # Guardar archivo EPG final
    with open(FINAL_XML, 'w', encoding='utf-8') as f:
        f.write('<?xml version="1.0" encoding="UTF-8"?>\n')
        f.write(f'<tv generator-info-name="EPG {datetime.now().strftime("%d/%m/%Y %H:%M")}">\n')
        f.writelines(all_channels)
        f.writelines(all_programs)
        f.write('</tv>\n')

    print(f"\n✅ EPG generado en {FINAL_XML}")
    print(f"📺 Canales: {len(all_channels)}")
    print(f"🗓️ Programas: {len(all_programs)}")
    print(f"📝 Revisa el log: {LOG_FILE}")

if __name__ == "__main__":
    main()
