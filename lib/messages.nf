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

        Required arguments: main.nf
        -profile <str>                    Which pipeline to run: slurm or standard
        -work-dir <pth>                   Pipelines temporary working directory
        --outdir <pth>                    Absolute path to output directory
        --lib_type <str>                  Single or paired end sequence data
        --seq_dir <str>                   Path to directory containing sequence files
        --seq_ext '<str>'                 Sequence file extension pattern in quotes
        --threads <int>                   Number of worker threads
        --sub_workflows                   Which sub-workflows to run

        SLURM profile:
        --email <str>                     Email address when '--profile slurm'

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

        NOTE: Arguments '--adapter_file' and '--detect_adapter' are mututally
        exclusive. You can't pass both arguments. 

        Similarly, if you provide '--trim' but neither of the other two arguments,
        the software will complain. 
        
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

        NOTE:
            - By default a common default set of models and comparisons will be conducted
            - Select ONE of `--mark`, `--leaves` or `--internals` but never more than ONE

        Example command:
        nextflow run main.nf \\
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

        Example command:
        nextflow run main.nf \\
            --reference /path/to/reference_mappings.csv \\
            --aligner_commands '-M -B 2' \\
            --mpileup_commands '-d 120 -Q 20 -q 20'
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
