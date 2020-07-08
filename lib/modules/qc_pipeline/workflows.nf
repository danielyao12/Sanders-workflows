include {run_fastp; run_fastqc_raw; run_fastqc_trim} from './processes'

workflow qc_pipeline {
    take: data
    take: workflow

    main:

    // Run Fastp
    run_fastp(data,
    workflow,
    params.outdir,
    params.lib_type,
    params.detect_adapter,
    params.unpaired_file,
    params.failed_file,
    params.adapter_file,
    params.trim,
    params.fastp_optional)

    // Run fastqc trimmed data
    run_fastqc_trim(run_fastp.out.trimmed_reads,
    workflow,
    params.outdir,)
    
    // Run fastqc
    run_fastqc_raw(data,
    workflow,
    params.outdir)
    
    emit:
        run_fastp.out.trimmed_reads
}