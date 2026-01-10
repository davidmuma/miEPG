# miEPG   v3.6

El repositorio hace uso de Github Actions para generar un xml a partir de otros, pudiendo modificar el nombre, el logo y el horario de cada canal

El script se ejecuta todos los días a las 13:30 (puedes modificar la hora en el cron)

***
- Modifica el fichero epgs.txt con las urls de la EPGs de origen

Si se encuentran canales con el mismo nombre en las distintas EPGs, solo se añadirá la primera coicidencia (la primera EPG tiene prioridad sobre la segunda, y así sucesivamente) 

- Modifica el fichero canales.txt con los canales que desees y sus nombres

Los nombres de los canales tienen que ir separados por comas (sin espacios), el primer campo es el nombre del canal de la EPG de origen, el segundo campo es el nuevo nombre que le quieres dar al canal (por ejemplo el de tu lista), el tercer campo es la url del logo (déjalo en blanco si quieres mantener el logo de la EPG de origen), y el cuarto campo es el valor para modificar la hora + o - (déjalo en blanco si no necesitas modificar la hora)  ·  Ejemplo: NombreEPG,NombreLISTA,hffp://raw.githubusercontent.com/Images/logo_dobleM.png,+2

- Modifica el fichero variables.txt

display-name: añade sufijos al nombre de cada canal

dias-pasados: para tener información de días pasados (Catch-Up)

dias-futuros: límita los días de la epg

***
Cuando se ejecute el script obtendrás una url con la EGP creada con tus canales y sus nombres

(Cambia el [Username] por el de tu cuenta de GitHub)
```
https://raw.githubusercontent.com/[Username]/miEPG/master/miEPG.xml
```

***

### Creando un fork desde GitHub

Un fork es una copia de un repositorio de GitHub independiente del repositorio original. Nosotros somos los dueños de ese fork, por lo que podemos hacer todos los cambios que queramos, aunque no tengamos permisos de escritura en el repositorio original.

Crear un fork desde GitHub es muy sencillo. Ve a la página principal del repositorio del que quieras hacer un fork y pulsa el botón fork.

Una vez completado el fork, nos aparecerá en nuestra cuenta el repositorio "forkeado".

![alt text](https://raw.githubusercontent.com/davidmuma/miEPG/refs/heads/main/.github/workflows/fork1.png)

### Habilitar GitHub Actions en tu fork

1. Habilita GitHub Actions en tu fork:

  - Una vez que hayas creado el fork, ve a la pestaña "Actions" en tu repositorio en GitHub.

  - Verás un mensaje que dice: "Workflows aren’t being run on this forked repository". Esto es normal, ya que GitHub deshabilita por defecto los workflows en los nuevos forks por motivos de seguridad.

  - Haz clic en el botón "I understand my workflows, go ahead and enable them" para habilitar los workflows en tu fork.

2. Verifica la configuración:

  - Realiza un cambio en algún archivo del proyecto (por ejemplo, edita un archivo .md) en una rama distinta de master y súbelo a tu fork.

  - Abre una pull request desde nueva rama hacia master en tu fork.

  - Ve a la pestaña "Actions" y verifica que los tests se están ejecutando correctamente en base a los workflows definidos en la carpeta .github/workflows/ del proyecto.


