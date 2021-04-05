# Pipeline for WES re-analysis for REX project

The pipeline is created for the uniform re-alignment and re-analysis of WES/CES samples for the Russian Exome Project. The software is available as a Docker image to ensure maximum reproducibility of the results and easy transfer to different laboratories for easing the data intgeration process. The repository contains two most imporant files:

`Dockerfile` is the recipe for creating a Docker image with pipeline and resource files used by GATK/BROAD

`Snakefile` is the main pipeline script written in Snakemake (Snakameke v.6 or higher is required). The rulegraph of the pipeline is included below:

![Example DAG of jobs](./dag.pdf)

## Building and installation

The pre-built image and resource files which are needed to run the build are available at Yandex.Disk: . If you use the pre-built image, the pre-built image, run:

```
docker load -i rex_v1.img.tar.gz
```

This command will load the `rex` image to your local Docker repository. To run the pipeline in Docker, all FASTQ files must be gzip-compressed and stored in one directory (no symlinks allowed). You can use the following command to start the container and run the pipeline:

```
docker run -v /path/to/your/files:/input -v /path/to/preferred/output/dir:/output --cpu <number of threads> -it rex:latest snakemake -s /gatk/pipelines/Snakefile -j <number of threads>
```

Please note that the number of CPUs has to be specified twice - once as the maximum number of threads that can be used by the Docker daemon, and once to pass the number of threads to the Snakemake (this number will be used for scaling).

