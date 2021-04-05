FROM broadinstitute/gatk:latest

COPY Snakefile /gatk/pipelines/
COPY bwa-mem2-2.2.1_x64-linux /gatk/bwa-mem2-2.2.1_x64-linux
RUN cp /gatk/bwa-mem2-2.2.1_x64-linux/bwa-mem2* /bin/  
COPY resources/ /gatk/resources
RUN conda install -n base -c conda-forge mamba
RUN mamba install -c conda-forge -c bioconda snakemake
RUN conda init
RUN su
RUN apt-get install -y samtools
