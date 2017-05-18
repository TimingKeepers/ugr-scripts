

## Generar FSBL <a name="fsbl"></a>

En Vivado:

 * File -> Export -> Export hardware
 	* Include bitstream
 	* Local to project -> OK
 * Launch SDK
 * New -> Application Project
 	* Give name to project (por ej. 'fsbl')
 	* Next
 * Zynq FSBL, Finish

Dentro del proyecto que contiene el fsbl _bueno_, copiar la carpeta ./wr-zen-hdl/syn/wrc2p-a7-zen-\*\*\*/wrc2p-a7-zen-\*\*\*.sdk/fsbl/src (ten en cuenta que fsbl fue el nombre dado en un paso anterior).

Forzar la actualización de los archivos del proyecto (esto es, F5).

Comprobar que no hay ningún problema a la hora de compilar (Build -> Build all)

Si todo va bien, al terminar el Build ya se ha generado el fsbl.elf

## Generar BOOT.bin

Para generar el BOOT.bin hace falta tener previamente tres ficheros:

 * El fsbl.elf que acabamos de generar
 * Un bitstream, generalmente un _golden_ con las funcionalidades básicas
 * El fichero u-boot.elf

> _Nota: se señala que el u-boot empleado es para la Zen v2. Desconozco si algún problema puede derivar de esto_.

Desde el SDK, en el menú Xilinx Tools -> Create BOOT Image:

 * Añadir esos tres ficheros en el orden que se han mencionado
 * Se puede guardar esa configuración en un fichero .bif para generar el BOOT.bin
   de manera más rápida en el futuro.
   
## Configurar LMK03806

Configurar los registros del LMK partiendo de un fichero de configuración .mac generado desde CodeLoader (ver Google Drive del equipo)
es muy sencillo si tenemos un proyecto de FSBL funcional como punto de partida. Se necesita sólamente el fichero .mac y el script lmkconf alojado en [el repositorio ugr-scripts](https://github.com/TimingKeepers/ugr-scripts).

Escribiendo

`source lmkconf fichero.mac salida.txt`
    
se genera un fichero .txt que contiene el struct con los nuevos valores de los registros del LMK03806.

Ya de vuelta al proyecto del fsbl, sustituiremos el struct presente en el fichero [ruta al fsbl]/src/lmk03806.c y continuamos con los pasos indicados para [generar un nuevo FSBL](#fsbl).

## Configurar AD9516

La configuración del AD9516 no se realiza en el FSBL sino que se programa mediante la ejecución de un binario _configure\_ad9516_ durante el arranque del SO, generalmente justo después de programar la PL de la Zen.
Para cambiar los registros que se programan al chip se ha de generar un nuevo binario en el sistema de archivos.

Supongamos que ya tenemos estos elementos de partida:

 * Un fichero .stp con la nueva configuración de los registros (el software necesario para generarlo se puede encontrar en el Google Drive del equipo).
 * Un entorno de trabajo en el que ya hemos podido compilar todos los ficheros resultado del repositorio wr-zynq-os.
 
Y solo hay que seguir estos pasos:

 * Llevar el fichero .stp al directorio donde están las herramientas relacionadas /.../wr-zynq-os/userspace/tools
 * Ejecutar el script de python gen_ad9516_config.py pasándole como argumento el fichero .stp. Este script generará una nueva cabecera en ad9516_config.h .

Ya sólo queda recompilar el espacio de usuario. Esto se puede conseguir llamando al script wrz-build-all desde fuera del directorio del repositorio y llevando a cabo los pasos 3, 4 y 5:

`./wr-zynq-os/build/wrz_build-all --step=03 && ./wr-zynq-os/build/wrz_build-all --step=04 && `
`./wr-zynq-os/build/wrz_build-all --step=05`
    
Y la imagen del sistema de archivos con la nueva configuración para el AD9516 se encontrará en ./images/uramdisk.image.gz.
 
    


