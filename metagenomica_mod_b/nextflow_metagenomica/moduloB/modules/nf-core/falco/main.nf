/*
 * FALCO — Control de calidad de lecturas FASTQ
 * Módulo instalado con: nf-core modules install falco
 *
 * Falco es una reimplementación de FastQC optimizada en C++, más rápida
 * y con menor consumo de memoria, produciendo los mismos informes HTML/ZIP
 * compatibles con MultiQC.
 *
 * Se usa en dos puntos del pipeline (importado dos veces con alias DSL2):
 *   FALCO_RAW     → QC de las lecturas crudas (antes de fastp)
 *   FALCO_TRIMMED → QC de las lecturas limpias (después de fastp)
 */
process FALCO {
    tag "$meta.id"
    label 'process_medium'

    conda 'bioconda::falco=1.2.5'
    container "${workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container
        ? 'https://depot.galaxyproject.org/singularity/falco:1.2.5--h077b44d_0'
        : 'biocontainers/falco:1.2.5--h077b44d_0'}"

    publishDir "${params.outdir}/${task.ext.publish_dir ?: 'falco'}", mode: 'copy'

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("*.html"), emit: html
    tuple val(meta), path("*.txt"),  emit: txt    // equivalente al .zip de FastQC para MultiQC
    path  "versions.yml",            emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args   = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    falco \\
        --threads ${task.cpus} \\
        ${args} \\
        ${reads}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        falco: \$(falco --version 2>&1 | sed 's/falco //')
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}_R1_fastqc.html ${prefix}_R2_fastqc.html
    touch ${prefix}_R1_fastqc.txt  ${prefix}_R2_fastqc.txt
    touch versions.yml
    """
}
