process run_codeml {
    tag { id }

    publishDir "${outdir}/codeml_ete-evol", mode: 'copy'

    input:
        tuple id, file(seqs), tree
        val outdir
        val models
        val tests
        val mark
        val leaves
        val internals
        val opt
        val wf

    output:
        file "${id}.txt"

    when:
        wf.contains('codeml_pipeline')

    script:
        // Optional arguments
        def models = models ?: '--models M2 M1 M3 M0 M8 M7 M8a bsA bsA1 bsC bsD b_free b_neut'
        def tests = tests ? '--tests ' + tests : ''
        def mark = mark ? '--mark ' + mark : ''
        def leaves = leaves ? '--leaves' : ''
        def internals = internals ? '--internals' : '' 
        def opt_args = opt ?: ''

        """
        echo "ete3 evol --cpu ${task.cpus} -t ${tree} --alg ${seqs} -o . ${models} ${tests} ${mark} ${leaves} ${internals} ${opt_args}" > ${id}.txt
        """        
}