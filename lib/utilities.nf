include {version_message; help_message_main; help_message_qc; help_message_stacks; help_message_codeml; help_message_consensus} from './messages.nf'

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
                    'transcriptome_pipeline' ]
    
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