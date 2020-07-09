include {run_codeml} from './processes'

workflow codeml_pipeline {
    take: seqs_tree_mark
    take: workflow

    main:

    run_codeml(seqs_tree_mark,
               params.outdir,
               params.models,
               params.tests,
               params.leaves,
               params.internals,
               params.codeml_param,
               workflow)
}