import os

# conda activate snakemake
# snakemake -n -r # -- test
# snakemake --cores 4 --use-conda # -- run
# snakemake --cores 4 --use-conda --use-singularity # -- run workflow with docker



SAMPLES = []
for file in os.listdir('/input'):
    if file.endswith(".fastq.gz"):
        shortened = os.path.splitext(file)[0]
        shortened_2 = os.path.splitext(shortened)[0]
        print(shortened_2)
        if os.path.splitext(shortened_2)[0] not in SAMPLES:
            SAMPLES.append(os.path.splitext(shortened_2)[0])

print(SAMPLES)


rule all:
    input:
        gvcf=expand("/output/{sample}.g.vcf", sample=SAMPLES)


rule bwa_mem2:
    input:
        reads_f = f"/input/{{sample}}.R1.fastq.gz",
        reads_r = f"/input/{{sample}}.R2.fastq.gz",
        index='/gatk/resources/resources_broad_hg38_v0_Homo_sapiens_assembly38.fasta'
    output:
        "/output/{sample}.bam"
    threads: 8
    shell:
        "bwa-mem2 mem -t {threads} -R '@RG\\tID:{wildcards.sample}\\tSM:{wildcards.sample}\\tLIB:1\\tPL:ILLUMINA' {input.index} {input.reads_f} {input.reads_r} | samtools view -bS - > {output}"


rule sort_bam:
    input: "/output/{sample}.bam"
    output: "/output/{sample}.sorted.bam"
    threads: 8
    shell: 'samtools sort -@ {threads} -o {output} {input} ; rm {input}'


rule mark_dups:
    input: "/output/{sample}.sorted.bam"
    output: "/output/{sample}.dedup.bam"
    params: ref='/gatk/resources/resources_broad_hg38_v0_Homo_sapiens_assembly38.fasta'
    shell: "gatk --java-options \"-Xmx4G\" MarkDuplicates -R {params.ref} -I {input} -O {output} -M /output/{wildcards.sample}.ND.metrics; rm {input}"


rule index_bam:
    input: "/output/{sample}.dedup.bam"
    output: "/output/{sample}.idx.status"
    shell: "samtools index {input} && touch {output}"


rule base_recalib:
    input:
        bam="/output/{sample}.dedup.bam",
        bai="/output/{sample}.idx.status"
    output: "/output/{sample}.recal.table"
    params: 
        ref='/gatk/resources/resources_broad_hg38_v0_Homo_sapiens_assembly38.fasta',
        dbsnp='/gatk/resources/resources_broad_hg38_v0_Homo_sapiens_assembly38.dbsnp138.vcf.gz',
        mills='/gatk/resources/Mills_and_1000G_gold_standard.indels.hg38.vcf.gz',
        known_indels='/gatk/resources/Homo_sapiens_assembly38.known_indels.vcf.gz',
        intervals='/gatk/resources/Homo_sapiens_assembly38_mergedCDSUTR.bed'
    shell: "gatk --java-options \"-Xmx4G\" BaseRecalibrator -R {params.ref} -I {input.bam} --known-sites {params.dbsnp} --known-sites {params.mills} --known-sites {params.known_indels} -L {params.intervals} -O {output}"


rule apply_recalib:
    input:
        table="/output/{sample}.recal.table",
        bams="/output/{sample}.dedup.bam"
    output: "/output/{sample}.recal.bam"
    params:
        ref='/gatk/resources/resources_broad_hg38_v0_Homo_sapiens_assembly38.fasta',
        intervals='/gatk/resources/Homo_sapiens_assembly38_mergedCDSUTR.bed'
    shell: "gatk --java-options \"-Xmx4G\" ApplyBQSR -R {params.ref} -L {params.intervals} -bqsr {input.table} -I {input.bams} -O {output}; rm {input.bams}"


rule haplotype_calling:
    input: "/output/{sample}.recal.bam"
    output: "/output/{sample}.g.vcf"
    params:
        ref='/gatk/resources/resources_broad_hg38_v0_Homo_sapiens_assembly38.fasta',
        intervals='/gatk/resources/Homo_sapiens_assembly38_mergedCDSUTR.bed'
    shell: "gatk --java-options \"-Xmx4G\" HaplotypeCaller -R {params.ref} -L {params.intervals} -I {input} -O {output} -ERC GVCF"

