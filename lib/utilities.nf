include {version_message; help_message_main; help_message_qc; help_message_stacks; help_message_codeml; help_message_consensus; help_message_transcript} from './messages.nf'

// Help/version
def help_or_version(Map args, String version){
    // Show help message
    if (args.help == true) {

        version_message(version)
        help_message_main()
        System.exit(0)

    } else if(args.help == 'qc_pipeline') {
        
        version_message(version)
        help_message_qc()
        System.exit(0)
        
    } else if(args.help == 'stacks_pipeline') {
        version_message(version)
        help_message_stacks()
        System.exit(0)

    } else if(args.help == 'codeml_pipeline') {
        version_message(version)
        help_message_codeml()
        System.exit(0)
        
    } else if(args.help == 'consensus_pipeline') {
        version_message(version)
        help_message_consensus()
        System.exit(0)
    } else if(args.help == 'transcript_pipeline') {
        version_message(version)
        help_message_transcript()
        System.exit(0)
    }

    // Show version number
    if (args.version){
        version_message(version)
        System.exit(0)
    }
}

// Check the passed arguments are 
def check_required_args_main(Map args, String args_name){
    if ( !args[args_name] ){

        if(args_name == 'threads') {
            return 2
        } else if(args_name == 'submission_queue') {
            return 'cpu'
        } else {
            println "ERROR: Missing argument '--" + args_name + "'"
            System.exit(1)
        }
    } else {
        return args[args_name]
    }
}

// Check the pipelines argument
def check_subWorkflow_selection(String workflows) {
    def subWork = [ 'qc_pipeline', 
                    'stacks_pipeline',
                    'codeml_pipeline',
                    'consensus_pipeline', 
                    'varCall_pipeline', 
                    'transcript_pipeline' ]
    
    // Split passed workflows - convert stringArray to java.util.ArrayList
    lst = workflows.tokenize(',')

    // Check passed workflows are valid
    try {
        assert subWork.containsAll(lst)
    } catch (AssertionError e){
        println("ERROR: Provided sub-workflow/s are not valid. \nError Message: " + e.getMessage())
        System.exit(1)
    }

    return lst
    
}

// Print arguments for each workflow
def print_subWorkflow_args(List workflow, Map args) {

    // Default arguments
    default_keys = ['outdir', 'lib_type', 'seqs', 'threads', 
                    'sub_workflows', 'submission_queue', 'email']

    // QC arguments
    qc_keys = ['trim', 'detect_adapter', 'adapter_file', 'fastp_optional',
               'unpaired_file', 'failed_file']
    
    // Stacks arguments
    stacks_keys = ['population_maps', 'ustacks_args', 'cstacks_args', 'sstacks_args', 
                   'tsv2bam_args', 'gstacks_args', 'populations_args']

    // CodeML arguments
    codeml_keys = ['trees', 'conda_env_path', 'models', 'tests',
                   'mark', 'leaves', 'internals', 'codeml_param']

    //Consensus arguments
    consensus_keys = ['reference', 'aligner_commands', 'mpileup_commands', 'norm_commands',
                      'filter_commands', 'view_commands', 'consensus_commands']

    transcript_keys = [ 'trinity_optional', 'run_cdhit', 'run_transdecoder' ]

    def args_map = [ qc_pipeline: qc_keys, 
                     stacks_pipeline: stacks_keys, 
                     codeml_pipeline: codeml_keys, 
                     consensus_pipeline: consensus_keys,
                     transcript_pipeline: transcript_keys ]

    // Print arguments to screen
    println """
    ##################################################
    ################### Arguments ####################
    """.stripIndent()

    def map_defaults = args.subMap(default_keys)
    println('--------------------- Main -----------------------\n')
    map_defaults.each {key, val ->
        if(val instanceof java.util.ArrayList) {
            println "${key}:"
            val.each {v ->
                println "  ${v}"
            }
        } else {
            println "${key}: ${val}"
        }
    }

    // Iterate through each sub-workflow
    workflow.each { wf ->
        
        def list = args_map[wf]
        def sub_map = args.subMap(list)
        String short_name = '--------------------- ' + wf.split('_')[0]
        Integer n = 50 - short_name.length() - 1

        println('\n' + short_name + ' ' + '-' * n + '\n')

        sub_map.each { key, val ->
            if(val instanceof java.util.ArrayList) {
                if(wf == 'consensus_pipeline') {
                    println "${key}:"
                    val.each { v ->
                        println "  ${v[0]} -> ${v[1]}"
                    }
                } else {
                    println "${key}:"
                    val.each {v ->
                        println "  ${v}"
                    }
                }
            } else {
                println "${key}: ${val}"
            }
        }
    }

    println"""
    ###########################################
    """.stripIndent()

}
