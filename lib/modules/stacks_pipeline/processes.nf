process run_ustacks {
    tag { id }

    label 'stacks'

    publishDir "${outdir}/stacks/01_ustacks", mode: 'copy'

    input:
        tuple id, file(reads)
        val wf
        val outdir
        val opt

    output:
        val "${outdir}/stacks/01_ustacks", emit: pth
        file "*.tsv*"

    when:
        wf.contains('stacks_pipeline')

    script:
        // Optional arguments
        def opt_args = opt ?: ''

        """
        ustacks -p ${task.cpus} -f ${reads} --name ${id} -i \${RANDOM} -o \${PWD} ${opt_args}
        """
}

process run_cstacks {
    tag { popMap.baseName }

    label 'stacks'

    publishDir "${outdir}/stacks/comparison_${popMap.baseName}", mode: 'copy'

    input:
        val wf
        tuple popMap, sample_string, file_string
        val opt
        val outdir
    
    output:
        tuple popMap, val("${outdir}/stacks/comparison_${popMap.baseName}"), emit: pop_path
        file("*catalog*")
        file("*tsv*")

    when:
        wf.contains('stacks_pipeline')

    script:
        // Optional arguments
        def opt_args = opt ?: ''

        """
        mkdir -p ${outdir}/stacks/comparison_${popMap.baseName}
        cp ${file_string} ${outdir}/stacks/comparison_${popMap.baseName}
        cstacks -p ${task.cpus} -o \${PWD} ${opt_args} ${sample_string}
        """

}

process run_sstacks {
    tag { popMap.baseName }

    label 'stacks'

    input:
        val wf
        tuple popMap, path
        val opt

    output:
        tuple popMap, path, emit: pop_path

    when:
        wf.contains('stacks_pipeline')

    script:
        // Optional arguments
        def opt_args = opt ?: ''

    """
    sstacks -P ${path} -M ${popMap} -p ${task.cpus} ${opt_args}
    """
}

process run_tsv2bam {
    tag { popMap.baseName }

    label 'stacks'

    input:
        val wf
        tuple popMap, path
        val opt

    output:
        tuple popMap, path, emit: pop_path

    when:
        wf.contains('stacks_pipeline')

    script:
    // Optional arguments
        def opt_args = opt ?: ''

    """
    tsv2bam -P ${path} -M ${popMap} -t ${task.cpus} ${opt_args}
    """
}

process run_gstacks {
    tag { popMap.baseName }

    label 'stacks'

    input:
        val wf
        tuple popMap, path
        val opt

    output:
        tuple popMap, path, emit: pop_path

    when:
        wf.contains('stacks_pipeline')

    script:
    // Optional arguments
        def opt_args = opt ?: ''

    """
    gstacks -P ${path} -M ${popMap} -t ${task.cpus} ${opt_args}
    """
}

process run_populations {
    tag { popMap.baseName }

    label 'stacks'

    publishDir "${path}/populations_out", mode: 'copy'

    input:
        val wf
        tuple popMap, path
        val opt

    output:
        tuple popMap, path, emit: pop_path
        file("*.{tsv,fa,gz}")

    when:
        wf.contains('stacks_pipeline')

    script:
    // Optional arguments
        def opt_args = opt ?: ''

    """
    populations -P ${path} -M ${popMap} -t ${task.cpus} -O \${PWD} ${opt_args}
    """
}