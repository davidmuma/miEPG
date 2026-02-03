# miEPG v3.7

## Descripción

Este repositorio utiliza **GitHub Actions** para generar un archivo XML a partir de múltiples EPGs. Puedes personalizar el **nombre**, el **logo** y el **horario** de cada canal.

El script se ejecuta automáticamente todos los días a las **13:30**. Si deseas, puedes modificar este horario en el archivo .github/workflows/miEPG.yml

---

## Instrucciones

1. **Modificar el archivo `epgs.txt`**:
   - Añade las URLs de las EPGs de origen.
   - Nota: Si se encuentran canales con el mismo nombre en diferentes EPGs, solo se añadirá la primera coincidencia (la primera EPG tiene prioridad).

2. **Modificar el archivo `canales.txt`**:
   - Especifica los canales que desees y sus nombres. (al ejecutar el script se generan listados de canales en .txt de las distintas egps para facilitar el copia/pega)
   - Los nombres de los canales deben ir separados por comas (sin espacios). 
   - **Formato**:
     ```
     NombreEPG,NombreLISTA,url_logo,valor_hora
     ```
   - **Ejemplo**:
     ```
     NombreEPG,NombreLista,hffp://raw.githubusercontent.com/Images/logo.png,+2
     ```
   - **Campos**:
     - `NombreEPG`: Nombre del canal de la EPG de origen.
     - `NombreLISTA`: Nuevo nombre que quieres dar al canal.
     - `url_logo`: Deja en blanco si deseas mantener el logo original.
     - `valor_hora`: Deja en blanco si no necesitas modificar la hora.

3. **Modificar el archivo `variables.txt`**:
   - `display-name`: Añade sufijos al nombre de cada canal.
   - `dias-pasados`: Para tener información de días pasados (Catch-Up).
   - `dias-futuros`: Limita los días de la EPG.

---

**Cuando se ejecute el script obtendrás una url con la EGP creada con tus canales y sus nombres**
   ```
   https://raw.githubusercontent.com/[Username]/miEPG/master/miEPG.xml
   ```
**Recuerda reemplazar `[Username]` por tu nombre de usuario en GitHub.**

---

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
  - Prueba de edicion github


