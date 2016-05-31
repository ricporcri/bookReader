#!/bin/bash
#########################################################
#  Script principal, cubrirá todas las funcionalidades  #
#  de la aplicación software:                           #
#        - Crear el entorno                             #
#        - Autodetectar bordes                          #
#        - Recortar la imagen                           #
#        - Generar el PDF y mandarlo por mail           #
#########################################################
#Cargamos la libreria (mismo directorio de trabajo):
source library.sh

dir_izq="img_izq"
dir_drch="img_drch"
dir_final="imgs"
dir_pdf="pdf"

##################################################
# Función que prepara el entorno de trabajo      #
# Salida:                                        #
#    - Todos los directorios creados.            #   
##################################################
prepara_entorno()
{
   #Creamos el directorio destino si no existe:
   if [ -d $dir_izq  ]; then
      #Si existe lo borramos
      rm -r $dir_izq
   fi
   if [ -d $dir_drch  ]; then
      #Si existe lo borramos
      rm -r $dir_drch
   fi
   if [ -d $dir_final  ]; then
      #Si existe lo borramos
      rm -r $dir_final
   fi
   if [ -d $dir_pdf  ]; then
      #Si existe lo borramos
      rm -r $dir_pdf
   fi

   #Creamos solo las carpetas contenedoras de las imagenes:
   mkdir $dir_drch
   mkdir $dir_izq
   mkdir $dir_final
   mkdir $dir_pdf
}

#Variable que llevara la cuenta del n de páginas.
n_page=1 

#Antes de preparar el entorno, vemos si en el directorio PDF hay algun PDF creado:
   
if [ -d $dir_pdf  ]; then
   #Si existe miramos si tiene algun fichero:
  num_fich=$(ls $1| wc -l)
  pdf=$(ls $1)
  #Si lo tiene mandamos el PDF
  if [ $num_fich == 1 ]; then
     send_mail $pdf
  fi
fi
#Como tenemos dos carpetas de montaje, para evitar el consumo
# de procesamiento, implementamos una espera activa, mediante semaforos:
while true; do
   auto_detect  &
   auto_detect &
done
