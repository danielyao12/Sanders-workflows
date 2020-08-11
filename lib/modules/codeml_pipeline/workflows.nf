include {setup_ete; run_codeml} from './processes'

workflow codeml_pipeline {
    take: seqs_tree_mark
    take: workflow

    main:

    // Configure ete evol to work
    File path = new File("${FASTDIR}/pipelines/ete")
    if(!path.isDirectory()) {
        setup_ete(workflow)
        Channel.value('placeholder').set { setup }
    } else {
        Channel.value('placeholder').set { setup }
    }

    // Run ete-evol
    run_codeml(setup,
               seqs_tree_mark,
               params.outdir,
               params.models,
               params.tests,
               params.leaves,
               params.internals,
               params.codeml_param,
               workflow)
}