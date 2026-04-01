/*
 * MULTIQC — Informe agregado de calidad de todas las muestras
 * Módulo instalado con: nf-core modules install multiqc
 *
 * Recoge los outputs de QC de todos los pasos anteriores y genera
 * un único informe HTML interactivo con gráficos comparativos entre
 * las 8 muestras (4 CD + 4 nonIBD):
 *   - Falco: calidad de bases, contenido GC, reads duplicadas (pre y post-trimming)
 *   - fastp: reads antes/después del trimming, adaptadores eliminados
 *   - Bowtie2: % de reads humanas descartadas por muestra
 */
process MULTIQC {
    label 'process_low'

    conda 'bioconda::multiqc=1.25.1'
    container "${workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container
        ? 'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/34/34e733a9ae16a27e80fe00f863ea1479c96416017f24a907996126283e7ecd4d/data'
        : 'community.wave.seqera.io/library/multiqc:1.33--ee7739d47738383b'}"

    publishDir "${params.outdir}/multiqc", mode: 'copy'

    input:
    path multiqc_files, stageAs: "?/*"   // todos los archivos QC de todos los pasos

    output:
    path "*multiqc_report.html", emit: report
    path "*_data",               emit: data
    path "versions.yml",         emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    """
    multiqc \\
        --force \\
        ${args} \\
        .

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        multiqc: \$(multiqc --version | sed 's/multiqc, version //')
    END_VERSIONS
    """

    stub:
    """
    touch multiqc_report.html
    mkdir multiqc_data
    touch versions.yml
    """
}
