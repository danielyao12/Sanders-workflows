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
    args.seq_dir = false
    args.seq_ext = false
    args.threads = false
    args.memory = false
    args.time = false
    args.email = false
    args.sub_workflows = false
    args.submission_queue = false

    // Return map of empty arguments
    return args
}

// Check arguments provided to main.nf
def check_args_main(Map args) {
    def final_args = [:]

    // Variables to build file paths
    def seq_dir = check_required_args_main(args, 'seq_dir')
    def seq_ext = check_required_args_main(args, 'seq_ext')
    def sub_workflows = check_required_args_main(args, 'sub_workflows')

    // Required arguments
    final_args.outdir = check_required_args_main(args, 'outdir')
    final_args.lib_type = check_required_args_main(args, 'lib_type')
    final_args.seqs = seq_dir + '/' + seq_ext
    final_args.threads = check_required_args_main(args, 'threads')
    final_args.memory = check_required_args_main(args, 'memory')
    final_args.time = check_required_args_main(args, 'time')
    final_args.submission_queue = check_required_args_main(args, 'submission_queue')
    
    // Check email is provided if profile == slurm
    if(workflow.profile == 'slurm' && !args.email) {
        println('ERROR: UofA email required for SLURM profile')
        System.exit(1)
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
    args.fastp_optional = false

    // Resource arguments
    args.qc_threads = false
    args.qc_memory = false
    args.qc_time = false

    // Return map of empty arguments
    return args
}

// Return checked QC arguments
def check_args_QC(Map args, Map mainArgs) {

    // Instantiate
    qc_args = empty_args_QC_map()

    /*
    Resource arguments: Default to 
        A) General threads/memory/time provided to main.nf by user
        B) Hardcoded defaults if above are not given (2 cpu/2.Gb/1.h)
    */
    qc_args.qc_threads = args.qc_threads ?: mainArgs.threads
    qc_args.qc_memory = args.qc_memory ?: mainArgs.memory
    qc_args.qc_time = args.qc_time ?: mainArgs.time

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
        qc_args.fastp_optional = args.fastp_optional ?: false

        // General arguments that are provided
        qc_args.unpaired_file = 'unpaired_reads.fastq.gz'
        qc_args.failed_file = 'failed_reads.fastq.gz'

    } else if(!args.trim && args.detect_adapter || args.adapter_file || args.fastp_optional){
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

    // Resource arguments
    args.stacks_threads = false
    args.stacks_memory = false
    args.stacks_time = false

    return args
    
}

def check_args_stacks(Map args, Map mainArgs) {

    // Instantiate
    stacks_args = empty_args_stacks_map()

    // Resource arguments
    stacks_args.stacks_threads = args.stacks_threads ?: mainArgs.threads
    stacks_args.stacks_memory = args.stacks_memory ?: mainArgs.memory
    stacks_args.stacks_time = args.stacks_time ?: mainArgs.time

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

    // Resource arguments
    args.codeml_threads = false
    args.codeml_memory = false
    args.codeml_time = false

    return args
    
}

def check_args_codeml(Map args, Map mainArgs) {

    // Initialise empty arguments
    codeml_args = empty_args_codeml_map()

    // Resource arguments
    codeml_args.codeml_threads = args.codeml_threads ?: mainArgs.threads
    codeml_args.codeml_memory = args.codeml_memory ?: mainArgs.memory
    codeml_args.codeml_time = args.codeml_time ?: mainArgs.time

    def trees = args.trees

    // Used to check if codeml_pipeline arguments have been
    // passed when the pipeline hasn't been selected
    def c_args = [
        args.trees,
        args.models,
        args.tests,
        args.mark,
        args.leaves,
        args.internals,
        args.codeml_param
    ]

    // Default eve3-evol models
    def default_models = [
        'M2', 'M1', 'M3', 'M0', 
        'M8', 'M7', 'M8a', 'bsA', 
        'bsA1', 'bsC', 'bsD', 
        'b_free', 'b_neut' 
        ]

    // CodeML pipeline is requested
    if(args.sub_workflows.contains('codeml_pipeline') ){

        codeml_args.codeml_param = args.codeml_param ?: false
        
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

        // Check models + tests
        // Arge 'tests' a fully encapsulated subset of models
        mod = args.models ? args.models.tokenize(' ') : default_models
        test = args.tests ?: false
                
        if(test){
     
            try {
                test = test.replaceAll(',', ' ').tokenize(' ')
                // test = test.tokenize(' ')
                assert mod.containsAll(test)
            } catch (AssertionError e){
                println("ERROR: discrepancy between 'models' and '--tests'\nError message: " + e.getMessage())
                System.exit(1)
            }

            codeml_args.tests = args.tests
        } else {
            // No tests provided - set to false
            codeml_args.tests = test
        }
        
        // String of models
        codeml_args.models = mod.join(' ')

        // Only one of these should be provided - if two are true error
        if(args.mark && (args.leaves || args.internals) || (args.leaves && args.internals)) {
            println("ERROR: Arguments have been passed for more than one of '--mark, --leaves and --internals'. Please only select one, not multiple.")
            System.exit(1)
        } 
        
        // How to handle --mark (string or file)
        if(args.mark){

            File file = new File(args.mark)
            bool = file.exists() // true if user passed a file

            // Read each line of the file as a list element
            if(bool){
                def lst = new File(args.mark).collect{ it }
                codeml_args.mark = lst
            } else {
                // Return list object - combine used in codeml workflow
                codeml_args.mark = [ args.mark ]
            }

        } else {
            codeml_args.mark = false
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

/*
Functions: consensus pipeline
*/

def empty_args_consensus_map() {
    def args = [:]

    args.reference = false
    args.aligner_commands = false
    args.mpileup_commands = false
    args.norm_commands = false
    args.filter_commands = false
    args.view_commands = false
    args.consensus_commands = false
    args.cleanup = false

    // Resource arguments
    args.consensus_memory = false
    args.consensus_time = false

    return args
    
}

def check_args_consensus(Map args, Map mainArgs) {
    // Initialise empty arguments
    consensus_args = empty_args_consensus_map()

    // Resource specification
    consensus_args.consensus_memory = args.consensus_memory ?: mainArgs.memory
    consensus_args.consensus_time = args.consensus_time ?: mainArgs.time
    
    // Define references
    def ref = args.reference

    // Consensus arguments - Arguments not passed without pipeline call
    def c_args = [
        args.reference,
        args.aligner_commands,
        args.mpileup_commands,
        args.norm_commands,
        args.filter_commands,
        args.view_commands,
        args.consensus_commands,
        args.cleanup
    ]

    if(args.sub_workflows.contains('consensus_pipeline') ){

        // Extra arguments to BWA/BCFtools
        consensus_args.aligner_commands = args.aligner_commands ?: false
        consensus_args.mpileup_commands = args.mpileup_commands ?: false
        consensus_args.norm_commands = args.norm_commands ?: false
        consensus_args.filter_commands = args.filter_commands ?: false
        consensus_args.view_commands = args.view_commands ?: false
        consensus_args.consensus_commands = args.consensus_commands ?: false
        consensus_args.cleanup = args.cleanup ?: false

        // Is there an argument to --reference
        if(!ref){
            println("ERROR: No argument passed to `--reference`")
            System.exit(1)
        } else if(ref == true){
            println("ERROR: '--references' argument has been requested with no input. Check your command.")
            System.exit(1)
        }

        // Argument must be a file regardless of type (fasta/csv) - check it exists
        try {
            File file = new File(ref)
            assert file.exists()
        } catch (AssertionError e) {
            println("ERROR: File passed to '--refernce' doesn't exist. Needs to be either a reference fasta file or a CSV file with sample-reference pairings\nError message: " + e.getMessage())
            System.exit(1)
        }

        // CSV - return list of tuples [ [sampleID, ref_path], [..., ...]]
        if(ref.endsWith('csv')){
            File file = new File(ref)
            def ref_lst = []

            // Append tuple to list
            file.eachLine { line ->
                def parts = line.split(",")
                ref_lst.addAll( [ [parts[0], parts[1]] ] )
            }

            // Assign list of tuples to references
            consensus_args.reference = ref_lst

        // Not CSV - check it has valid extension for genomic fasta
        } else if(ref.endsWith('fa') || ref.endsWith('fasta') || ref.endsWith('fna')) {
            consensus_args.reference = ref

        // Not CSV or Fasta - error
        } else {
            println("ERROR: File passed to `--reference` exists but isn't a CSV with extension 'csv' or a FASTA with extensions 'fa', 'fasta' or 'fna'. Please check your input")
            System.exit(1)
        }

    // Will run if another pipeline has been requested but this hasn't but there are
    // arguments to it
    } else if(! args.sub_workflows.contains('consensus_pipeline') && c_args.any {it == true}) {
        println("ERROR: Arguments for the consensus sub-workflow have been provided without specifying the '--sub_workflows consensus_pipeline' argument.")
        System.exit(1)
    }

    return consensus_args
}

/*
Functions: Transcriptome pipeline
*/

def empty_args_transcript_map() {
    def args = [:]

    args.trinity_optional = false
    args.run_cdhit = false
    args.run_transdecoder = false

    // Resource arguments
    args.transcript_threads = false
    args.transcript_memory = false
    args.transcript_time = false

    return args
    
}

def check_args_transcript(Map args, Map mainArgs) {

    // Initialise empty arguments
    transcript_args = empty_args_transcript_map()

    transcript_args.transcript_threads = args.transcript_threads ?: mainArgs.threads
    transcript_args.transcript_memory = args.transcript_memory ?: mainArgs.memory
    transcript_args.transcript_time = args.transcript_time ?: mainArgs.time

    def c_args = [
        args.trinity_optional,
        args.run_cdhit,
        args.run_transdecoder
    ]

    if(args.sub_workflows.contains('transcript_pipeline') ){
        transcript_args.trinity_optional = args.trinity_optional ?: false
        transcript_args.run_cdhit = args.run_cdhit ?: false
        transcript_args.run_transdecoder = args.run_transdecoder ?: false
    } else if(! args.sub_workflows.contains('transcript_pipeline') && c_args.any {it == true}) {
        println("ERROR: Arguments for the transcript assembly sub-workflow have been provided without specifying the '--sub_workflows transcript_pipeline' argument.")
        System.exit(1)
    }

    return transcript_args
}

/*
Functions: Variant pipeline
*/

def empty_args_variant_map() {
    def args = [:]

    args.ref = false
    args.caller = false
    args.tidy = false
    args.merge = false
    args.opt_bwa = false
    args.opt_haplotypeCaller = false
    args.opt_combineGVCF = false
    args.opt_genotypeGVCF = false
    args.opt_mpileup = false
    args.opt_norm = false

    // Resource arguments
    args.variant_threads = false
    args.variant_memory = false
    args.variant_time = false

    return args
}

def check_args_variant(Map args, Map mainArgs) {

    variant_args = empty_args_variant_map()

    // Resource arguments
    variant_args.variant_threads = args.variant_threads ?: mainArgs.threads
    variant_args.variant_memory = args.variant_memory ?: mainArgs.memory
    variant_args.variant_time = args.variant_time ?: mainArgs.time

    def c_args = [
        args.ref,
        args.caller,
        args.tidy,
        args.merge,
        args.opt_bwa,
        args.opt_haplotypeCaller,
        args.opt_combineGVCF,
        args.opt_genotypeGVCF,
        args.opt_mpileup,
        args.opt_norm
    ]

    if(args.sub_workflows.contains('variant_pipeline') ){

        // Required arguments
        if(!args.caller) {
            println("ERROR: No argument passed to `--caller`")
            System.exit(1)
        } else if(args.caller == true) {
            println("ERROR: `--caller` argument passed with no value. Please select either gatk or bcftools.")
            System.exit(1)
        } else if(args.caller == 'bcftools' && args.merge) {
            println("ERROR: Joint genotyping with BCFtools is not supported. Invalid combination of '--caller bcftools' and '--merge'")
            System.exit(1)
        } else {
            variant_args.caller = args.caller
        }

        // Is there an argument to --reference
        if(!args.ref){
            println("ERROR: No argument passed to `--ref`")
            System.exit(1)
        } else if(args.ref == true){
            println("ERROR: '--ref' argument has been requested with no input.Check your command.")
            System.exit(1)
        }

        // Argument must be a file regardless of type (fasta/csv) - check it exists
        try {
            File file = new File(args.ref)
            assert file.exists()
        } catch (AssertionError e) {
            println("ERROR: File passed to '--ref' doesn't exist. Needs to be either a reference fasta file or a CSV file with sample-reference pairings\nError message: " + e.getMessage())
            System.exit(1)
        }

        // CSV - return list of tuples [ [sampleID, ref_path], [..., ...]]
        if(args.ref.endsWith('csv')){
            File file = new File(args.ref)
            def ref_lst = []
            def ref_name = []

            // Append tuple to list
            file.eachLine { line ->
                def parts = line.split(",")
                ref_lst.addAll( [ [parts[0], parts[1]] ] )
                ref_name.add(parts[1])
            }

            // Check --merged hasn't been provided with CSV with multiple references
            if(ref_name.unique().size() > 1 && args.merge) {
                println("ERROR: CSV file contains multiple different reference genomes and '--merge' has been provided. It's not possible to merge VCFs from different genomes")
                System.exit(1)
            }
            
            variant_args.ref = ref_lst

        // Not CSV - check it has valid extension for genomic fasta
        } else if(args.ref.endsWith('fa') || args.ref.endsWith('fasta') || args.ref.endsWith('fna')){
            
            variant_args.ref = args.ref

        // Not CSV or Fasta - error
        } else {
            println("ERROR: File passed to `--ref` exists but isn't a CSV with extension 'csv' or a FASTA with extensions 'fa', 'fasta' or 'fna'. Please check your input")
            System.exit(1)
        }

        // Optional arguments
        variant_args.opt_bwa = args.opt_bwa ?: false
        variant_args.opt_haplotypeCaller = args.opt_haplotypeCaller ?: false
        variant_args.opt_combineGVCF = args.opt_combineGVCF ?: false
        variant_args.opt_genotypeGVCF = args.opt_genotypeGVCF ?: false
        variant_args.opt_mpileup = args.opt_mpileup ?: false
        variant_args.opt_norm = args.opt_norm ?: false
        variant_args.tidy = args.tidy ?: false
        variant_args.merge = args.merge ?: false

    } else if(! args.sub_workflows.contains('variant_pipeline') && c_args.any {it == true}) {
        println("ERROR: Arguments for the variant sub-workflow have been provided without specifying the '--sub_workflows variant_pipeline' argument.")
        System.exit(1)
    }

    return variant_args

}