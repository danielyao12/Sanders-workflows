#!/usr/bin/env nextflow

nextflow.preview.dsl=2
version = '1.0'

// Include helper functions here
include {empty_args_main_map; check_args_main; check_args_QC; check_args_stacks} from './lib/params_parser'
include {help_or_version} from './lib/utilities'

// Argument parsing
default_params = empty_args_main_map()
merged = default_params + params

// Help message if requested
help_or_version(merged, version)

// Check main pipeline arguments
checked_args = check_args_main(merged)

/*
Sub-workflow arguments: Instantiate and populate
*/

// QC arguments
qc_args = check_args_QC(checked_args['usr_args'])
checked_args['main_args'].putAll(qc_args)

// Stacks arguments
stacks_args = check_args_stacks(checked_args['usr_args'])
checked_args['main_args'].putAll(stacks_args)

// Final arguments to use in pipeline
final_args = checked_args['main_args']

// Print key and values
println """
###########################################
################ Arguments ################
"""
final_args.each {key, val ->
    println "$key: $val"
}
println"""
###########################################
"""

/*
Calling sub-workflows: Main pipeline
*/

workflow {

    /*
    Build channels of files - reads + map files
    */

    // Get fastq files as tuple
    Channel
        .fromFilePairs(final_args['reads'], size: final_args['lib_type'] == 'paired' ? 2 : 1)
        .ifEmpty { exit 1, "Cannot find any read files matching: ${final_args['reads']}"}
        .set { reads }

    // Get population map files
    if(final_args['sub_workflows'].contains('stacks_pipeline')){
        Channel
        .fromList(final_args['population_maps'])
        .ifEmpty { exit 1, "Cannot find population map files matching: ${final_args['population_maps']}"}
        .set { pop_maps }
    } else {
        Channel
            .empty()
            .set { pop_maps }
    }

    // Load workflows
    include {qc_pipeline} from './lib/modules/qc_pipeline/workflows' params(final_args)
    include {stacks_pipeline} from './lib/modules/stacks_pipeline/workflows' params(final_args)

    // Run QC pipeline
    qc_pipeline(reads, final_args['sub_workflows'])

    // Reassign reads if trim has been specified
    if(final_args['trim']){
        qc_pipeline.out.set { reads }
    }

    // Run STACKS pipeline
    stacks_pipeline(reads,
                    pop_maps,
                    final_args['sub_workflows'])

}