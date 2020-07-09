include {run_codeml} from './processes'

workflow codeml_pipeline {
    take: seqs_tree_mark
    take: workflow

    main:

    // Combine sequences and trees - all pairs
    // seqs
    //     .combine(params.trees)
    //     .map {val ->
    //         tuple(val[0], val[1][0], val[2])
    //     }
    //     .set {seqs_tree}

    // // Create channel from list of marks
    // Channel
    //     .fromList(params.mark)
    //     .set {mark}

    // // Combine with seqs_tree
    // seqs_tree
    //     .combine(mark)
    //     .set{ seqs_tree_mark }

    run_codeml(seqs_tree_mark,
               params.outdir,
               params.models,
               params.tests,
               params.leaves,
               params.internals,
               params.codeml_param,
               workflow)
}