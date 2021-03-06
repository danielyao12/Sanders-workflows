// Print version of the pipeline
def version_message(String version) {
    println(
        """
        ==============================================================
                      NGS workflows pipeline ${version}              
        ==============================================================
        """.stripIndent()
    )
}

// Pipeline help message
def help_message_main() {
    println(
        """
        In this repository are the following sub-workflows:

            - qc_pipeline: Fastp/FastQC wrapper for sequence QC
            - stacks_pipeline: Run STACKS on RAD-seq data
            - codeml_pipeline: Run CodeML using ETE-Evol
            - consensus_pipeline: Get consensus gene models from gene-capture data
            - varCall_pipeline: Call variants against reference genomes
            - transcript_pipeline: Assemble RNA-seq data into transcriptomes

        Required arguments:
        -profile <str>                    Which pipeline to run: slurm or standard
        -work-dir <pth>                   Pipelines temporary working directory
        --outdir <pth>                    Absolute path to output directory
        --lib_type <str>                  Single or paired end sequence data
        --seq_dir <str>                   Path to directory containing sequence files
        --seq_ext '<str>'                 Sequence file extension pattern in quotes
        --sub_workflows                   Which sub-workflows to run

        Optional arguments:
        --threads <int>                   Number of worker threads requested for all subworkflow processes (default: 2)
        --memory <str>                    Amount of memory requested for all sub-workflow processes (default: 4.Gb)
        --time                            Time requested for each sub-workflow process (default: 1.h)

        NOTE: These resource arguments are the lowest priority. If you provide resource arguments to sub-workflows, they will be used over the values above.
        When requesting resources, ensure you use the correct syntax for memory and time (shown in defaults above).

        SLURM profile:
        --email <str>                     Email address when '--profile slurm'
        --submission_queue                Partition to submit jobs to (default: 'cpu')

        If you are interested in seeing your resource usage, provide the
        '-with-report' and/or '-with-timeline' arguments. The trace argument is 
        if you are interested in detailed metrics.

        Metric parameters:
        -with-report <pth>                Interactive HTML file summarising the run
        -with-trace <pth>                 Text file storing information about each process
        -with-timeline <pth>              Interactive HTML file showing run time of each process

        Pipeline information:
        --help                            Show this help page
        --help <pipeline_name>            Show help message for sub-workflow
        --version                         Show the pipeline version

        Example command:
        nextflow run main.nf \\
            -profile slurm \\
            -work-dir \${FASTDIR}/sequence_project/work_dir \\
            --outdir \${FASTDIR}/sequence_project \\
            --lib_type paired \\
            --seq_dir \${FASTDIR}/sequence_project/fastq \\
            --seq_ext '*_{1,2}.fastq.gz' \\
            --threads 4 \\
            --email a1234567@adelaide.edu.au \\
            --sub_workflows qc_pipeline,stacks_pipeline \\
            -with-report \${FASTDIR}/sequence_project/report.html
        """.stripIndent()
    )
}

/*
Sub-workflow help messages
*/

def help_message_qc() {
    println(
        """
        QC Pipeline: Help page

        This pipeline is a wrapper around Fastp and FastQC. It provides
        the option to quality and adapter trim sequence data, along with
        generating QC reports, both from Fastp and FastQC.

        Arguments:
        --trim                        Should sequences be trimmed
        --detect_adapter              Fastp will automatically detect adapters
        --adapter_file                File path to adapter fasta file

        Optional:
        --fastp_optional              Quoted string of custom parameters for fastp
        --qc_threads                  Number of threads to pass to Fastp
        --qc_memory                   Memory to request for Fastp/FastQC
        --qc_time                     Time to request for Fastp/FastQC

        NOTE: 
            - Arguments '--adapter_file' and '--detect_adapter' are mututally
            exclusive. You can't pass both arguments.
            - Optional resource parameters above will default to 'threads', 'memory' and 'time' values used by 'main.nf' if none are given.

        Similarly, if you provide '--trim' but neither of the other two arguments,
        the software will complain. 
        
        Example command:
        nextflow run main.nf \\
            ...\\
            --trim \\
            --detect_adapter
        """.stripIndent()
    )
}

def help_message_stacks() {
    println(
        """
        Stacks 2 Pipeline: Help page

        This pipeline is a wrapper around the Stacks software suite. It will run
        the following steps:

            - ustacks: Align short read sequences into exactly-matching stacks
            - cstacks: Build a catalogue of consensus loci using population map
            - sstacks: Search sample loci against cstacks catalogue
            - tsv2bam: Transpose data and create BAM output
            - gstacks: Genotype each individual sample at each locus (SNP)
            - populatons: Output population genetics statistics/downstream files

        These pipelines have been parameterised using the default values with some
        minor tweaks to a few parameters.
        
        Required arguments:
        --population_maps <str>                 Comma separated population map files

        Optional (but recommended) arguments:
        --ustacks_args <str>                    Arguments to pass to ustacks in quotes
        --cstacks_args <str>                    Arguments to pass to cstacks in quotes
        --sstacks_args <str>                    Arguments to pass to sstacks in quotes
        --tsv2bam_args <str>                    Arguments to pass to tsv2bam in quotes
        --gstacks_args <str>                    Arguments to pass to gstacks in quotes
        --populations_args <str>                Arguments to pass to populations in quotes
        --stacks_threads                        Number of threads requested for each of the Stacks sub-processes
        --stacks_memory                         Memory to request for each of the Stacks sub-processes
        --stacks_time                           Time to request for each of the Stacks sub-processes

        NOTE:
            - Optional resource parameters above will default to 'threads', 'memory' and 'time' values used by 'main.nf' if none are given.

        As each users run will be different, I've made it so you can provide arguments
        to stacks as a string. If no arguments are passed, the pipeline will run with
        default parameters.

        Example command:
        nextflow run main.nf \\
            ...\\
            --population_maps /path/to/popmap1.txt,/path/to/popmap2.txt \\
            --ustacks_args '-M 4 -m 10 --deleverage --min_aln_len 0.90' \\
            --cstacks_args '--max_gaps 1 --min_aln_len 0.90' \\
            --tsv2bam_args '-R /path/to/paired_end_reads'
            --gstacks_args '--min-kmer-cov 5 --min-mapq 15' \\
            --populations_args '-r 0.90 --fasta-loci --fasta-samples --vcf --genepop --structure'
        """.stripIndent()
    )
}

def help_message_codeml() {
    println(
        """
        CodeML help page - ETE Evol implementation

        This sub-workflow runs CodeML using the ETE-Evol implementation. This is
        a tool that is a wrapper around CodeML, designed to make running muliple
        models, genes and trees a breeze. For more help regarding how to run the
        software check out: http://etetoolkit.org/documentation/ete-evol

        Required arguments:
        --trees <str>                       List of tree files to use in the analysis
        --conda_env_path <str>              Path to pre-created conda environment for ete-evol (see README)

        Optional arguments:
        --models <str>                      Quoted string of models to be run by codeml
        --tests <str>                       Quoted string of model comparisons (e.g. 'M2,M1 M3,M0')
        --mark <str/file-path>              Quoted string of tree markings using ETE-Evol syntax
        --leaves                            Agument specifying if every leaf should be marked
        --internals                         Agument specifying if every node should be marked
        --codeml_param <str>                Quoted string of extra parameters to pass to ETE-Evol
        --codeml_threads                    Number of threads to request for CodeML processes
        --codeml_memory                     Amount of memory to request for CodeML processes
        --codeml_time                       Amount of time to request for CodeML processes

        NOTE:
            - By default a common default set of models and comparisons will be conducted
            - Select ONE of `--mark`, `--leaves` or `--internals` but never more than ONE
            - Optional resource parameters above will default to 'threads', 'memory' and 'time' values used by 'main.nf' if none are given.

        Example command:
        nextflow run main.nf \\
            ... \\
            --sub_workflows codeml_pipeline \\
            --trees /path/to/tree.nw,/path/to/tree.nw \\
            --models 'M2,M1,M3,M0,bsA,bsA1' \\
            --leaves
        """.stripIndent()
    )
}

def help_message_consensus() {
    println(
        """
        Consensus pipeline help page

        This sub-workflow generates consensus sequences using BWA/BCFtools. The reads are aligned
        to a reference genome/sequence using BWA, with a consensus sequence being called by BCFtools.
        Users can provide a single reference genome or a text file with key-value pairings of which
        samples (column 1) should be aligned to which genome (column 2).

        Required arguments:
        --reference <str/file-path>         File path to a reference genome or file path to a csv file with sample-reference pairings

        Optional arguments:
        --aligner_commands <str>            Quoted string of extra commands to pass to BWA-mem
        --mpileup_commands <str>            Quoted string of extra commands to pass to BCFtools mpileup
        --norm_commands <str>               Quoted string of extra commands to pass to BCFtools norm
        --filter_commands <str>             Quoted string of extra commands to pass to BCFtools filter
        --view_commands <str>               Quoted string of extra commands to pass to BCFtools view
        --consensus_commands <str>          Quoted string of extra commands to pass to BCFtools consensus
        --cleanup                           Keep only the consensus FASTA files (delete BAM and VCF files)
        --consensus_memory                  Amount of memory requested for consensus processes
        --consensus_time                    Amount of time requested for consensus processes

        NOTE:
            - Optional resource parameters above will default to 'threads', 'memory' and 'time' values used by 'main.nf' if none are given.

        Example command:
        nextflow run main.nf \\
            ... \\
            --reference /path/to/reference_mappings.csv \\
            --aligner_commands '-M -B 2' \\
            --mpileup_commands '-d 120 -Q 20 -q 20'
        """.stripIndent()
    )
}

def help_message_transcript() {
    println(
        """
        Transcript assembly pipeline help page

        This sub-workflow provides an avenue for simplified transcriptome assembly using Trinity.
        Trinity is a de novo assembly tool which integrates nicely into an annotation pipeline
        written by the same developers.

        Optional arguments:
        --trinity_optional <str>            Quoted string of extra commands to pass to Trinity
        --run_cdhit
        --run_transdecoder
        --transcript_threads                Number of threads requested for Trinity, CD-HIT and homology searches
        --transcript_memory                 Amount of memory requested for CD-HIT and homology searches
        --transcript_time                   Amount of time requested for CD-HIT and homology searches

        NOTE:
            - Optional resource parameters above will default to 'threads', 'memory' and 'time' values used by 'main.nf' if none are given.

        Example command:
        nextflow run main.nf \\
            ... \\
            --trinity_optional '--SS_lib_type FR --min_contig_length 500' \\
            --run_cdhit \\
            --run_transdecoder
        """.stripIndent()
    )
}

def help_message_variant() {
    println(
        """
        Variant calling pipeline help page

        A sub-workflow for variant calling using GATK or BCFtools.

        Required arguments:
        --ref <str/file-path>               File path to either a reference fasta or CSV file with sample-reference pairings
        --caller <str>                      Which variant calling method to use - gatk/bcftools

        Optional arguments:
        --tidy                              Pass this argument to remove BAM files to save disk space
        --merge                             Pass this argument if you want to joint call variants using GATK (not supported for BCFtools)
        --opt_bwa <str>                     Quoted string of optional commands to pass to aligner
        --opt_haplotypeCaller <str>         Quoted string of optional commands to pass to GATKs HaplotypeCaller
        --opt_combineGVCF <str>             Quoted string of optional commands to pass to GATKs CombineGVCF
        --opt_genotypeGVCF <str>            Quoted string of optional commands to pass to GATKs GenotypeGVCF
        --opt_mpileup <str>                 Quoted string of optional commands to pass to BCFtools mpileup
        --opt_norm <str>                    Quoted string of optional commands to pass to BCFtools norm
        --variant_threads                   Number of threads requested by GATK
        --variant_memory                    Amount of memory requested by GATK and BCFtools processes
        --variant_time                      Amount of memory requested by GATK and BCFtools processes

        NOTE:
            - Optional resource parameters above will default to 'threads', 'memory' and 'time' values used by 'main.nf' if none are given.

        Example command:
        nextflow run main.nf \\
            ... \\
            --ref ref-sample-pairs.csv \\
            --caller gatk
        """.stripIndent()
    )
}

// Return message on completion
def complete_message(String version){
    // Display complete message
    println """
    Pipeline execution summary
    ---------------------------
    Completed at : ${workflow.complete}
    Duration     : ${workflow.duration}
    Success      : ${workflow.success}
    Work Dir     : ${workflow.workDir}
    Exit status  : ${workflow.exitStatus}
    Error report : ${workflow.errorReport ?: '-'}
    
    """.stripIndent()
}
