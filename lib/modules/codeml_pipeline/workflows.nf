include {run_codeml} from './processes'

workflow codeml_pipeline {
    take: seqs
    take: workflow

    main:

    // Combine sequences and trees - all pairs
    seqs
        .combine(params.trees)
        .map {val ->
            tuple(val[0], val[1][0], val[2])
        }
        .set {seqs_tree}

    run_codeml(seqs_tree,
               params.outdir,
               params.models,
               params.tests,
               params.mark,
               params.leaves,
               params.internals,
               params.codeml_param,
               workflow)
}