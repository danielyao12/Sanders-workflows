include {run_index; run_bwa; run_consensus} from './processes'

workflow consensus_pipeline {
    take: seqs
    take: workflow

    main:

    // Get reference genome path
    seqs
        .map { val ->
            // Path to reference files
            String path = val[2].substring(0, val[2].lastIndexOf('/'))
            return tuple(val[2], path)
            }
        .unique()
        .set { ref }

    // Index reference + BWA index
    run_index(ref,
              workflow)

    // Join index output with sequence files - different join method based on input
    if(params.reference instanceof java.lang.String){
        
        seqs
            .combine(run_index.out.refs)
            .map {val ->
                return tuple(
                    val[0],
                    val[1],
                    val[2],
                    val[4]
                )
            }
            .set { seqs }

    } else if(params.reference instanceof java.util.ArrayList){
        
        seqs
            .join(run_index.out.refs, by: [2])
            .map {val ->
                return tuple(val[1], val[2], val[0], val[4])
            }
            .set { seqs }

    }

    // Align data to reference
    run_bwa(seqs,
            params.outdir,
            params.aligner_commands,
            workflow)

    // Generate consensus sequences
    run_consensus(seqs,
                  params.outdir,
                  run_bwa.out.bam,
                  params.mpileup_commands,
                  params.norm_commands,
                  params.filter_commands,
                  params.view_commands,
                  params.consensus_commands,
                  workflow)
}