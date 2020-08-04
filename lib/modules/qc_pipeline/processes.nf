// Fastp
process run_fastp {
    tag { id }

    publishDir "${outdir}/fastp/${id}", mode: 'copy'

    label 'fastp'

    input:
        tuple id, file(file_pair)
        val wf
        val outdir
        val lib_type
        val detect_adapter
        val unpaired_file
        val failed_file
        val adapter_fasta
        val trim
        val opt

    output:
        tuple id, file("trim/${id}*.gz"), emit: trimmed_reads
        file 'failed_reads.fastq.gz'
        file "${id}.{html,json}"
        file 'unpaired_reads.fastq.gz' optional true

    when:
        trim == true && wf.contains('qc_pipeline')

    script:
    def opt_args = opt ?: ''

    if(lib_type == 'paired')
        if(detect_adapter == true)
            """
            mkdir -p trim

            fastp \
            --in1 ${file_pair[0]} \
            --in2 ${file_pair[1]} \
            --out1 trim/${file_pair[0].baseName}.gz \
            --out2 trim/${file_pair[1].baseName}.gz \
            --unpaired1 ${unpaired_file} \
            --failed_out ${failed_file} \
            --html ${id}.html \
            --json ${id}.json \
            --thread ${task.cpus} \
            ${opt_args}
            """
        else
            """
            mkdir -p trim

            fastp \
            --in1 ${file_pair[0]} \
            --in2 ${file_pair[1]} \
            --out1 trim/${file_pair[0].baseName}.gz \
            --out2 trim/${file_pair[1].baseName}.gz \
            --unpaired1 ${unpaired_file} \
            --failed_out ${failed_file} \
            --adapter_fasta ${adapter_fasta} \
            --html ${id}.html \
            --json ${id}.json \
            --thread ${task.cpus} \
            ${opt_args}
            """
    else if(lib_type == 'single')
        if(detect_adapter == true)
            """
            mkdir -p trim

            fastp \
            --in1 ${file_pair[0]} \
            --out1 trim/${file_pair[0].baseName}.gz \
            --failed_out ${failed_file} \
            --html ${id}.html \
            --json ${id}.json \
            --thread ${task.cpus} \
            ${opt_args}
            """
        else
            """
            mkdir -p trim

            fastp \
            --in1 ${file_pair[0]} \
            --out1 trim/${file_pair[0].baseName} \
            --unpaired1 trim/${unpaired_file} \
            --failed_out ${failed_file} \
            --adapter_fasta ${adapter_fasta} \
            --html ${id}.html \
            --json ${id}.json \
            --thread ${task.cpus} \
            ${opt_args}
            """
    else
        error "Invalid argument provided to ${detect_adapter}"
}

// Fastp
process run_fastqc_raw {
    tag { id }

    label 'fixCore'

    publishDir "${outdir}/fastqc/${id}/raw", mode: 'copy'

    input:
        tuple id, file(reads)
        val wf
        val outdir

    output:
        tuple id, file("*.{zip,html}")

    when:
        wf.contains('qc_pipeline')

    script:
        """
        fastqc  -t ${task.cpus} -k 9  -q ${reads}
        """
}

process run_fastqc_trim {
    tag { id }

    label 'fixCore'

    publishDir "${outdir}/fastqc/${id}/trim", mode: 'copy'

    input:
        tuple id, file(reads)
        val wf
        val outdir

    output:
        tuple id, file("*.{zip,html}")

    when:
        wf.contains('qc_pipeline')

    script:
        """
        fastqc  -t ${task.cpus} -k 9  -q ${reads}
        """
}