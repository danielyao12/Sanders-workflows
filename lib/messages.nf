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
            - geneCap_pipeline: Get consensus gene models from gene-capture data
            - varCall_pipeline: Call variants against reference genomes
            - trinity_pipeline: Assemble RNA-seq data into transcriptomes

        Required arguments: main.nf
        -profile <str>                    Which pipeline to run: slurm or standard
        -work-dir <pth>                   Pipelines temporary working directory
        --outdir <pth>                    Absolute path to output directory
        --lib_type <str>                  Single or paired end sequence data
        --fastq_dir <str>                 Path to directory containing FASTQ files
        --fastq_ext '<str>'               FASTQ file extension in quotes
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
            --fastq_dir \${FASTDIR}/sequence_project/fastq \\
            --fastq_ext '*_{1,2}.fastq.gz' \\
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

        NOTE: Arguments '--adapter_file' and '--detect_adapter' are mututally
        exclusive. You can't pass both arguments. 

        Similarly, if you provide '--trim' but neither of the other two arguments
        , the software will complain. 
        
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
