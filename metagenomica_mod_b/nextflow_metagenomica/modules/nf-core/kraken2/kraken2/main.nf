/*
 * KRAKEN2_KRAKEN2 — Clasificación taxonómica (metagenómica shotgun)
 * Módulo instalado con: nf-core modules install kraken2/kraken2
 *
 * Base de datos usada: Standard-Full (2024-09-04), sin límite de hash.
 * Umbral de confianza: 0.1 (equivalente al empleado en Galaxy).
 *
 * Genera dos outputs:
 *   - report : informe jerárquico en formato Kraken2 (input de Bracken)
 *   - output : asignación read-a-read (opcional, para inspección)
 *
 * Tasa de clasificación obtenida con este dataset: ~57.5%
 * (rango típico en microbioma intestinal: 40-80%)
 */
process KRAKEN2_KRAKEN2 {
    tag "$meta.id"
    label 'process_high_memory'

    conda 'bioconda::kraken2=2.1.3'
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/0f/0f827dcea51be6b5c32255167caa2dfb65607caecdc8b067abd6b71c267e2e82/data' :
        'community.wave.seqera.io/library/kraken2_coreutils_pigz:920ecc6b96e2ba71' }"

    publishDir "${params.outdir}/kraken2", mode: 'copy'

    input:
    tuple val(meta), path(reads)
    path  db                    // directorio de la base de datos Kraken2

    output:
    tuple val(meta), path("${meta.id}.kraken2.report.txt"), emit: report
    path  "${meta.id}.kraken2.output.txt",                  emit: classified_reads_assignment
    path  "versions.yml",                                   emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args   = task.ext.args ?: "--confidence ${params.kraken2_confidence} --use-names"
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    kraken2 \\
        --db ${db} \\
        --paired \\
        --gzip-compressed \\
        --report ${prefix}.kraken2.report.txt \\
        --output ${prefix}.kraken2.output.txt \\
        --threads ${task.cpus} \\
        ${args} \\
        ${reads[0]} ${reads[1]}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        kraken2: \$(kraken2 --version | head -1 | sed 's/Kraken version //')
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.kraken2.report.txt
    touch ${prefix}.kraken2.output.txt
    touch versions.yml
    """
}
