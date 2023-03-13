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

# fasterq-dump -S SRR22388518
# fasterq-dump -S SRR22388519
# fasterq-dump -S SRR18335437
# fasterq-dump -S SRR18335438

gzip *.fastq

# QC
fastqc -o dtos/qc/fastqc datos/*.fastq.gz

multiqc --filename multiqc_report.html --outdir qc qc/fastqc

for i in SRR18335437 SRR18335438 SRR22388518 SRR22388519; do
    fastp \
    --verbose \
    --thread 4 \
    --detect_adapter_for_pe \
    --cut_tail \
    --cut_mean_quality 20 \
    --average_qual 20 \
    --report_title "Reporte fastp: $i" \
    --in1 datos/${i}_1.fastq.gz \
    --in2 datos/${i}_2.fastq.gz \
    --out1 resultados/00_datos_limpios/${i}_1.clean.fastq.gz \
    --out2 resultados/00_datos_limpios/${i}_2.clean.fastq.gz \
    --unpaired1 resultados/00_datos_limpios/${i}_1.unpaired.fastq.gz \
    --unpaired2 resultados/00_datos_limpios/${i}_2.unpaired.fastq.gz \
    --html resultados/00_datos_limpios/qc/fastp/${i}.report.fastp.html \
    --json resultados/00_datos_limpios/qc/fastp/${i}.report.fastp.json
done

# Generar reportes con FastQC
fastqc -o resultados/00_datos_limpios/qc/fastqc resultados/00_datos_limpios/*.clean.fastq.gz

# Generar reporte unificado con MultiQC
multiqc \
  --export \
  --filename multiqc_report.html \
  --outdir resultados/00_datos_limpios/qc \
  resultados/00_datos_limpios/qc/fastp \
  resultados/00_datos_limpios/qc/fastqc

# Ensamblaje

for i in SRR18335437 SRR18335438 SRR22388518 SRR22388519; do
  spades.py \
    --isolate \
    -1 resultados/00_datos_limpios/${i}_1.clean.fastq.gz \
    -2 resultados/00_datos_limpios/${i}_2.clean.fastq.gz \
    -o resultados/01_ensamblaje/${i} \
    -t 4

  ln -sr resultados/01_ensamblaje/${i}/scaffolds.fasta resultados/01_ensamblaje/${i}.fasta
done

# QC
for i in SRR18335437 SRR18335438 SRR22388518 SRR22388519; do
  quast -o resultados/02_ensamblaje_qc/${i} \
    -r datos/GCF_017821535.1.fasta \
    -t 4 \
    resultados/01_ensamblaje/${i}.fasta
done