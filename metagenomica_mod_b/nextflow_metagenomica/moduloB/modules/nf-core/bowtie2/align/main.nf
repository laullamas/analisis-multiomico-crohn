/*
 * BOWTIE2_ALIGN — Descontaminación del huésped (Human GRCh38)
 * Módulo instalado con: nf-core modules install bowtie2/align
 *
 * Estrategia: alineamiento al genoma humano GRCh38.
 * Se conservan únicamente las reads que NO alinean (--un-conc-gz):
 * representan el microbioma de origen no humano.
 * El SAM se descarta (-S /dev/null): solo interesan las reads no alineadas.
 *
 * Equivalente al paso 2 del pipeline ejecutado en Galaxy (usegalaxy.eu).
 */
process BOWTIE2_ALIGN {
    tag "$meta.id"
    label 'process_high'

    conda 'bioconda::bowtie2=2.5.4 bioconda::samtools=1.20'
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/b4/b41b403e81883126c3227fc45840015538e8e2212f13abc9ae84e4b98891d51c/data' :
        'community.wave.seqera.io/library/bowtie2_htslib_samtools_pigz:edeb13799090a2a6' }"

    publishDir "${params.outdir}/bowtie2", mode: 'copy',
        saveAs: { filename -> filename.endsWith('.log') ? filename : null }

    input:
    tuple val(meta), path(reads)
    path  index                 // directorio con archivos .bt2/.bt2l del índice GRCh38

    output:
    tuple val(meta), path("${meta.id}_decontam_{1,2}.fastq.gz"), emit: reads
    path  "${meta.id}_bowtie2.log",                               emit: log
    path  "versions.yml",                                         emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args   = task.ext.args ?: '--very-sensitive'
    def prefix = task.ext.prefix ?: "${meta.id}"
    // El nombre base del índice es el primer archivo .bt2 sin la extensión
    def index_base = index.listFiles().find { it.name.endsWith('.1.bt2') || it.name.endsWith('.1.bt2l') }
                         ?.name?.replaceAll(/\\.1\\.bt2l?$/, '') ?: params.bowtie2_index_name
    """
    bowtie2 \\
        -x ${index}/${index_base} \\
        -1 ${reads[0]} \\
        -2 ${reads[1]} \\
        --un-conc-gz ${prefix}_decontam_%.fastq.gz \\
        --no-unal \\
        -p ${task.cpus} \\
        -S /dev/null \\
        ${args} \\
        2> ${prefix}_bowtie2.log

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bowtie2: \$(bowtie2 --version | head -1 | sed 's/.*bowtie2-align-s version //')
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}_decontam_1.fastq.gz ${prefix}_decontam_2.fastq.gz
    touch ${prefix}_bowtie2.log
    touch versions.yml
    """
}
