/*
 * BRACKEN_BRACKEN — Re-estimación de abundancias taxonómicas
 * Módulo instalado con: nf-core modules install bracken/bracken
 *
 * Bracken (Bayesian Reestimation of Abundance with KrakEN) corrige las
 * asignaciones de Kraken2 redistribuyendo reads de niveles superiores
 * hasta el nivel de especie (-l S), usando estadística bayesiana basada
 * en el perfil del genoma de referencia incluido en la BD de Kraken2.
 *
 * Los Bracken Reports generados son equivalentes a los descargados desde
 * Galaxy y usados como input en el análisis R/phyloseq downstream.
 *
 * Parámetros:
 *   -r 100   longitud de lectura (Illumina HiSeq 2000, 101 bp → distribuciones Bracken 100 bp)
 *   -l S     nivel taxonómico de salida: especie (Species)
 *   -t 10    umbral mínimo de reads para redistribución bayesiana
 */
process BRACKEN_BRACKEN {
    tag "$meta.id"
    label 'process_low'

    conda 'bioconda::bracken=2.9'
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/f3/f30aa99d8d4f6ff1104f56dbacac95c1dc0905578fb250c80f145b6e80703bd1/data' :
        'community.wave.seqera.io/library/bracken:3.1--22a4e66ce04c5e01' }"

    publishDir "${params.outdir}/bracken", mode: 'copy'

    input:
    tuple val(meta), path(kraken2_report)
    path  db                                // mismo directorio que la BD Kraken2

    output:
    tuple val(meta), path("${meta.id}.bracken.report.txt"), emit: report
    path  "${meta.id}.bracken_species.txt",                 emit: tsv
    path  "versions.yml",                                   emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args   = task.ext.args ?: "-l S -r ${params.bracken_read_length} -t ${params.bracken_threshold}"
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    bracken \\
        -d ${db} \\
        -i ${kraken2_report} \\
        -o ${prefix}.bracken_species.txt \\
        -w ${prefix}.bracken.report.txt \\
        ${args}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bracken: \$(bracken --version 2>&1 | sed 's/Bracken v//')
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.bracken.report.txt
    touch ${prefix}.bracken_species.txt
    touch versions.yml
    """
}
