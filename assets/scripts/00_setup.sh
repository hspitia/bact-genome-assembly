#! /usr/bin/env bash

mkdir -p ensamblaje/{datos,resultados,scripts}
mkdir -p ensamblaje/resultados/{00_datos_limpios,01_ensamblaje,02_ensamblaje_qc,03_anotacion}
tree -L 2 ensamblaje

wget https://github.com/conda-forge/miniforge/releases/latest/download/Mambaforge-Linux-x86_64.sh

# Adicionar permiso de ejecución
chmod +x Mambaforge-Linux-x86_64.sh
# Ejecutar el instalador
./Mambaforge-Linux-x86_64.sh -b


eval "$(/home/hector/mambaforge/bin/mamba shell.bash hook)"

/home/hector/mambaforge/bin/mamba init bash

mamba create -n ensam

mamba activate ensam

mamba install -c bioconda csvtk fastp fastqc java-jdk multiqc pigz prokka \
  quast spades sra-tools wget -y
  
# Entrar al directorio para datos en el directorio del proyecto
cd ensamblaje/datos

# Descargar las muestras

for i in SRR22388518 SRR22388519 SRR18335437 SRR18335438; do fasterq-dump -S -p -e 8 $i; done

fasterq-dump -S SRR22388518

fasterq-dump -S SRR22388519

fasterq-dump -S SRR18335437

fasterq-dump -S SRR18335438

gzip *.fastq