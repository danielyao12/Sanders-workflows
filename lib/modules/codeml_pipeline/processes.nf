process setup_ete {
    tag { 'Installing ETE-EVOL' }

    input:
        val wf
    
    when:
        wf.contains('codeml_pipeline')
    
    script:
        """
        mkdir -p \${FASTDIR}/pipelines
        cd \${FASTDIR}/pipelines
        git clone https://github.com/etetoolkit/ete.git
        cd ete
        python setup.py install
        """
}

process run_codeml {
    tag { id }

    publishDir "${outdir}/codeml_ete-evol", mode: 'copy'

    label 'codeml'

    input:
        val setup
        tuple id, file(seqs), tree, mark
        val outdir
        val models
        val tests
        val leaves
        val internals
        val opt
        val wf

    output:
        file "*"
        file "results_codeml.txt"

    when:
        wf.contains('codeml_pipeline')

    script:
        
        // Defining arguments
        def models = '--models ' + models
        def tests = tests ? '--tests ' + tests : ''
        def mark = mark ? '--mark ' + mark : ''
        def leaves = leaves ? '--leaves' : ''
        def internals = internals ? '--internals' : '' 
        def opt_args = opt ?: ''

        """
        ete3 evol \
        --cpu ${task.cpus} \
        -t ${tree} \
        --alg ${seqs} \
        -o \${PWD} \
        ${models} ${tests} ${mark} ${leaves} ${internals} ${opt_args}

        cp .command.out results_codeml.txt
        """        
}