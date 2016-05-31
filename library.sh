#!/bin/bash
dir_izq_aux="img_izq_aux"
dir_drch_aux="img_drch_aux"
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
   if [ -d $dir_drch_aux  ]; then
      #Si existe lo borramos
      rm -r $dir_drch_aux
   fi
   if [ -d $dir_izq_aux  ]; then
      #Si existe lo borramos
      rm -r $dir_izq_aux
   fi

   #Creamos solo las carpetas contenedoras de las imagenes:
   mkdir $dir_drch
   mkdir $dir_izq
}

##################################################
# Función para convertir todas las fotos a pdf   #
# Argumentos:                                    #
#    -Carpeta contenedora de todas las imagenes  #
#     maquetadas.                                #
# Salida:                                        #
#    - Todas las imagenes en un pdf en una nueva #
#      carpeta (dir_pdf).                        #   
##################################################
pdf_convert()
{
   images=`ls $dir_final`
   echo "Imágenes a pasar a PDF:"
   echo $images
   echo "Pasando a PDF..."
   convert $images result.pdf
}
########PROVISIONAL#####
auto_mv()
{
  image=`ls $dir_izq_aux`
  maqueta $image
  mv $image $dir_izq/$image
  
  image=`ls $dir_drch_aux`
  maqueta $image
  mv $image $dir_drch/$image
  
}
<<COMMENT
maqueta()
{

}
COMMENT

##################################################
# Función para reducir las dimensiones de        #
# la imagen pasada por argumento                 #
# Argumentos:                                    #
#    -Imagen a reducir                           #
# Salida:                                        #                          
##################################################
reduce_imagen()
{
   aux=$(echo "$(echo $1 | cut -d "." -f 1).png")
   convert $1 $aux
   convert $aux -resize 20%x20% +repage $aux

}

hazlo_todo()
{
 reduce_imagen $1
 aux=$(echo "$(echo $1 | cut -d "." -f 1).png")
 busca_margen $aux
}
busca_margen()
{
  #convert $1 -threshold 50% -canny 0x10+10%+70% \( +clone -background none -fill red \) -composite thres1.png
    convert $1 -threshold 50% -canny 0x10+10%+70% \( +clone -background none -fill red -stroke red -strokewidth 1 -hough-lines 50x50+100 -write lines_bueno.mvg \) -composite aux.png
    #Buscamos las lineas verticales y horizontales:
    busca_lineas 0 lines_bueno.mvg
    busca_lineas 1 lines_bueno.mvg
    #Una vez tenemos el fichero auxiliar con las lineas:
    lineas=$(cat fichero_lineas.txt | grep "line")
    convert aux.png -stroke red -strokewidth 10 -draw "$lineas" aux2.png
    convert $1 -stroke red -strokewidth 10 -draw "$lineas" border.png 

    ##Hacemos una copia de la imagen real en png y pintamos el centro de blanco.
    convert border.png -fill white -bordercolor red -draw 'color 200,200 filltoborder' border_white.png
    #Comparamos la imagen real (sin blanco) con la que tiene el centro de blanco.
    compare -compose src border_white.png border.png comparison.png
    #Autotrim 
    convert -trim comparison.png -fuzz 10% -bordercolor red trim.png
    #Extraemos las coordenadas de la mascara:
    coor1=$(identify trim.png | awk '{print $3}')
    coor2=$(identify trim.png | awk '{print $4}' | awk -F'+' '{print $2}')
    coor3=$(identify trim.png | awk '{print $4}' | awk -F'+' '{print $3}')
    coor=$coor1"+"$coor2"+"$coor3
    #Extraemos la imagen definitiva de la que no tiene bordes pintados:
    convert -extract $coor $1 final.png
}
borra_aux() 
{
 rm -rf fichero_lineas.txt *.mvg
}
#Como parametro recibe 0 (horizontales)/ 1 (verticales) y el fichero .mvg
busca_lineas()
{
  #Variable que utilizaremos para indicar el max.valor de pendiente que aceptaremos
  tol=0.3
  if [ $1 == 0 ]; then
     echo "Buscando lineas horizontales..."
     horizontales=$(cat lines_bueno.mvg | grep "line 0" | cut -d "#" -f 1)
     echo $horizontales >> fichero_lineas.txt
  elif [ $1 == 1 ]; then
     echo "Buscando lineas verticales..."
     verticales=$(cat lines_bueno.mvg | grep ",0")
     #Leemos el fichero pasado como parametro linea a linea
     filename=$2
     while read -r line
     do
        #Nos quedamos con la lineas potencialmente horizontales:
        name="$line"
        echo $(echo $name| grep ",0")
        inicio=$(echo $name | grep ",0" | cut -d " " -f 2 | cut -d "." -f 1 | cut -d "," -f 1)
        fin=$(echo $name | grep ",0" | cut -d " " -f 3 | cut -d "." -f 1 | cut -d "," -f 1)
        echo "¿ $inicio == $fin?"
        if [ ! -z  $inicio  ] && [ $inicio == $fin ]; then
	   echo "ENTRA"
           echo $name >> fichero_lineas.txt
        fi
	#Comparamos las pendientes para saber si es candidata:       
        done < "$filename"
  fi
}
crea_mascara()
{
  echo "Creando mascara..."
  convert $1 -colorspace gray \( +clone -blur 0x2 \) +swap -compose divide -composite -linear-stretch 5%x0% -threshold 5% -trim mask.png

 # echo "Creando mascara negra..."
#convert $1 -colorspace gray \( +clone -blur 0x2 \) +swap -compose divide -composite -linear-stretch 5%x0% -threshold 5% \( -clone -fill '#000000' -colorize 100 \) -delete 0 black-mask.png

}

##Recibe como parámetro el directorio donde escuchara si se recibe algun 
##fichero y el directorio destino
auto_detect()
{
  num_fich=$(ls $1| wc -l)
  fich=$(ls $1)
  #echo $num_fich
  if [ $num_fich == 1 ]; then
	#En el caso de que entre(suponiendo $2 mismo directorio de work):
        mv $1/$fich $2
        cd $2
        hazlo_todo $fich
   else 
        echo "No debe entrar"
   fi
}
