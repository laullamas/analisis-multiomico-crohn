/*
 * FASTP — Control de calidad y trimming de adaptadores
 * Módulo instalado con: nf-core modules install fastp
 *
 * Parámetros equivalentes a los empleados en Galaxy (fastp 0.23.4):
 *   --adapter_sequence / --adapter_sequence_r2   adaptador Nextera XT explícito
 *   --detect_adapter_for_pe                       auto-detección como doble seguridad
 *   --qualified_quality_phred 15                  umbral Q15 (valor por defecto de fastp)
 *   --unqualified_percent_limit 40                máx. 40% bases por debajo de Q15
 *   --n_base_limit 5                              máx. 5 bases N por lectura
 *   --length_required 50                          descartar reads < 50 bp tras trimming
 *   --low_complexity_filter --complexity_threshold 30  descartar reads con < 30% complejidad
 *   --correction                                  corrección de mismatches por solapamiento PE
 * Nota: --trim_poly_g NO se activa (datos de HiSeq 2000, no NextSeq/NovaSeq)
 * Nota: análisis de duplicados desactivado por defecto en fastp (correcto para metagenómica)
 */
process FASTP {
    tag "$meta.id"
    label 'process_medium'

    conda 'bioconda::fastp=0.23.4'
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/55/556474e164daf5a5e218cd5d497681dcba0645047cf24698f88e3e078eacbd09/data' :
        'community.wave.seqera.io/library/fastp:1.1.0--08aa7c5662a30d57' }"

    publishDir "${params.outdir}/fastp", mode: 'copy',
        saveAs: { filename -> filename.endsWith('.fastq.gz') ? null : filename }

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("${meta.id}_trimmed_{1,2}.fastq.gz"), emit: reads
    tuple val(meta), path("${meta.id}.fastp.json"),              emit: json
    tuple val(meta), path("${meta.id}.fastp.html"),              emit: html
    path  "versions.yml",                                        emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args   = task.ext.args ?: [
        "--adapter_sequence CTGTCTCTTATACACATCT",
        "--adapter_sequence_r2 CTGTCTCTTATACACATCT",
        "--detect_adapter_for_pe",
        "--qualified_quality_phred 15",
        "--unqualified_percent_limit 40",
        "--n_base_limit 5",
        "--length_required 50",
        "--low_complexity_filter",
        "--complexity_threshold 30",
        "--correction"
    ].join(' ')
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    fastp \\
        --in1 ${reads[0]} \\
        --in2 ${reads[1]} \\
        --out1 ${prefix}_trimmed_1.fastq.gz \\
        --out2 ${prefix}_trimmed_2.fastq.gz \\
        --json ${prefix}.fastp.json \\
        --html ${prefix}.fastp.html \\
        --thread ${task.cpus} \\
        ${args}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        fastp: \$(fastp --version 2>&1 | sed 's/fastp //')
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}_trimmed_1.fastq.gz ${prefix}_trimmed_2.fastq.gz
    touch ${prefix}.fastp.json
    touch ${prefix}.fastp.html
    touch versions.yml
    """
}
