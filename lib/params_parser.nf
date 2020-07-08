include {check_required_args_main; check_subWorkflow_selection} from './utilities.nf'

/*
Functions: main.nf
*/

// Instantiate required arguments for main
def empty_args_main_map() {
    def args = [:] // Empty map

    // Instantiate required args
    args.outdir = false
    args.lib_type = false
    args.fastq_dir = false
    args.fastq_ext = false
    args.threads = false
    args.email = false
    args.sub_workflows = false

    // Return map of empty arguments
    return args
}

// Check arguments provided to main.nf
def check_args_main(Map args) {
    def final_args = [:]

    // Variables to build file paths
    def fastq_dir = check_required_args_main(args, 'fastq_dir')
    def fastq_ext = check_required_args_main(args, 'fastq_ext')
    def sub_workflows = check_required_args_main(args, 'sub_workflows')

    // Required arguments
    final_args.outdir = check_required_args_main(args, 'outdir')
    final_args.lib_type = check_required_args_main(args, 'lib_type')
    final_args.reads = fastq_dir + '/' + fastq_ext
    final_args.threads = check_required_args_main(args, 'threads')
    
    // Check email is provided if profile == slurm
    if(workflow.profile == 'slurm' && !args.email) {
        println('ERROR: UofA email required for SLURM profile')
    } else {
        final_args.email = args.email
    }

    // Check passed pipelines
    final_args.sub_workflows = check_subWorkflow_selection(sub_workflows)

    // Max resource allocation
    final_args.max_cpus = args.max_cpus
    final_args.max_mem = args.max_mem
    final_args.max_time = args.max_time

    return [ main_args: final_args,  usr_args: args]

}

/*
Functions: QC pipeline
*/

// Instantiate the variables
def empty_args_QC_map() {
    def args = [:] // Empty map

    // Instantiate required args
    args.trim = false
    args.detect_adapter = false
    args.adapter_file = false
    args.unpaired_file = false
    args.failed_file = false

    // Return map of empty arguments
    return args
}

// Return checked QC arguments
def check_args_QC(Map args) {

    // Instantiate
    qc_args = empty_args_QC_map()

    // 
    if(args.trim) { // Trim the reads

        qc_args.trim = args.trim

        if(!args.detect_adapter && !args.adapter_file){
            println("ERROR: Trimming requested but no arguments passed to 'detect_adapter' or 'adapter_file'")
            System.exit(1)
        } else if(args.detect_adapter && args.adapter_file){
            println("ERROR: Trimming selected but both 'detect_adapter' and 'adapter_file' have been provided. Choose one.")
            System.exit(1)
        }

        // Assign variables
        qc_args.adapter_file = args.adapter_file ?: false
        qc_args.detect_adapter = args.detect_adapter ?: false

        // General arguments that are provided
        qc_args.unpaired_file = 'unpaired_reads.fastq.gz'
        qc_args.failed_file = 'failed_reads.fastq.gz'

    } else if(!args.trim && args.detect_adapter || args.adapter_file){
        println("ERROR: Trimming has not been selected but arguments relating to trimming have been provided. Check that 'detect_adapter' or 'adapter_file' has not been set")
        System.exit(1)
    }

    return qc_args

}

/*
Functions: Stacks Pipeline
*/

def empty_args_stacks_map() {
    def args = [:]

    args.ustacks_args = false
    args.cstacks_args = false
    args.sstacks_args = false
    args.tsv2bam_args = false
    args.gstacks_args = false
    args.populations_args = false
    args.population_maps = false

    return args
    
}

def check_args_stacks(Map args) {

    // Instantiate
    stacks_args = empty_args_stacks_map()

    // Custom args as list
    def c_args = [ args.ustacks,
                   args.cstacks,
                   args.sstacks,
                   args.tsv2bam_args,
                   args.gstacks,
                   args.populations_args,
                   args.population_maps ]

    def pop_maps = args.population_maps

    // Requesting stacks pipeline
    if(args.sub_workflows.contains('stacks_pipeline') ){
        
        stacks_args.ustacks_args = args.ustacks_args ?: false
        stacks_args.cstacks_args = args.cstacks_args ?: false
        stacks_args.sstacks_args = args.sstacks_args ?: false
        stacks_args.tsv2bam_args = args.tsv2bam_args ?: false
        stacks_args.gstacks_args = args.gstacks_args ?: false
        stacks_args.populations_args = args.populations_args ?: false
        
        if(!pop_maps){
            println("ERROR: Provide at least one population map file to '--population_maps'")
            System.exit(1)
        } else if(pop_maps == true){
            println("ERROR: '--population_maps' argument has been specified with no input. Check your command.")
            System.exit(1)
        }

        // Get each map file and check it exists
        def mp = []
        pop_maps.tokenize(',').each {
            try {
                File file = new File(it)
                assert file.exists()
                mp.add(file)
            } catch (AssertionError e){
                println('ERROR: One of the provided population map files do not exist.\nError message: ' + e.getMessage())
                System.exit(1)
            }
        }
        
        // Assign to final map object
        stacks_args.population_maps = mp

    } else if(! args.sub_workflows.contains('stacks_pipeline') && c_args.any {it == true}) {

        println("ERROR: Arguments for the Stacks sub-workflow have been provided without specifying the '--sub_workflows stacks_pipeline' argument.")
        System.exit(1)

    }

    return stacks_args
}

/*
Functions: codeml pipeline
*/

def empty_args_codeml_map() {
    def args = [:]

    args.trees = false
    args.models = false
    args.tests = false
    args.mark = false
    args.leaves = false
    args.internals = false
    args.codeml_param = false

    return args
    
}

def check_args_codeml(Map args) {

    // Initialise empty arguments
    codeml_args = empty_args_codeml_map()

    // trees variable
    def trees = args.trees
    def c_args = [
        args.trees,
        args.models,
        args.tests,
        args.mark,
        args.leaves,
        args.internals,
        args.codeml_param
    ]

    // Requesting codeml pipeline
    if(args.sub_workflows.contains('codeml_pipeline') ){
        
        // Have tree files been provided
        if(!trees){
            println("ERROR: Provide at lease one tree file to '--trees'")
            System.exit(1)
        } else if(trees == true){
            println("ERROR: '--trees' argument has been requested with no input. Check your command.")
            System.exit(1)
        }

        // Get each tree file and check it exists
        def tr = []
        trees.tokenize(',').each {
            try {
                File file = new File(it)
                assert file.exists()
                tr.add(file)
            } catch (AssertionError e){
                println('ERROR: One of the provided tree files does not exist.\nError message: ' + e.getMessage())
                System.exit(1)
            }
        }

        codeml_args.trees = tr

        // Check remaining arguments
        codeml_args.models = args.models ?: false
        codeml_args.tests = args.tests ?: false

        // Only one of these should be provided - if two are true error
        if(args.mark && (args.leaves || args.internals) || (args.leaves && args.internals)) {
            println("ERROR: Arguments have been passed for more than one of '--mark, --leaves and --internals'. Please only select one, not multiple.")
            System.exit(1)
        } 
        
        // How to handle --mark (string or file)
        File file = new File(args.mark)
        bool = file.exists() // Logical if file exists

        // Read each line of the file as a list element
        if(bool){
            def lst = new File(args.mark).collect{ it }
            codeml_args.mark = lst
        } else {
            codeml_args.mark = args.mark ?: false
        }

        // Assign final variables
        codeml_args.leaves = args.leaves ?: false
        codeml_args.internals = args.internals ?: false

    // Arguments passed but pipeline not selected
    } else if(! args.sub_workflows.contains('codeml_pipeline') && c_args.any {it == true}) {

        println("ERROR: Arguments for the CodeML sub-workflow have been provided without specifying the '--sub_workflows codeml_pipeline'.")
        System.exit(1)

    }

    return codeml_args
}