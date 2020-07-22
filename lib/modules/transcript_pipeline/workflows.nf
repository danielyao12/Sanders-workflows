include {run_trinity; run_cdhit; get_databases; run_transdecoder_longorfs; run_blast; run_hmmer; run_transdecoder_predict} from './processes'

workflow transcript_pipeline {
    take: seqs
    take: workflow

    main:

    // Assemble RNA-seq data
    run_trinity(seqs,
                params.lib_type,
                params.outdir,
                params.trinity_optional,
                workflow)

    // Remove redundancy - taken from: https://github.com/trinityrnaseq/trinityrnaseq/wiki/There-are-too-many-transcripts!-What-do-I-do%3F
    run_cdhit(run_trinity.out.fasta,
              params.outdir,
              params.run_cdhit,
              workflow)

    // Conditional: Assign outputs to neutral variable name
    if(params.run_cdhit) {

        run_cdhit.out.fasta.set { id_fasta }

    } else {

        run_trinity.out.fasta.set { id_fasta }

    }

    // Download databases - Only if Transdecoder == true
    get_databases(params.run_transdecoder,
                  workflow)

    // Transdecoder Long orfs
    run_transdecoder_longorfs(id_fasta,
                              params.outdir,
                              params.run_transdecoder,
                              workflow)

    // Blast
    run_blast(run_transdecoder_longorfs.out.path_longOrf,
              params.outdir,
              params.run_transdecoder,
              workflow)

    // HMMER
    run_hmmer(run_transdecoder_longorfs.out.path_longOrf,
              params.outdir,
              params.run_transdecoder,
              workflow)

    // Joing Fasta + LongORF directory + BLAST + HMMER
    fasta.join(run_transdecoder_longorfs.out.path_longOrf.join(run_blast.out.join(run_hmmer.out, by: [0]), by: [0]), by: [0]).set { input }

    // Transdecoder Predict
    run_transdecoder_predict(input,
                             params.outdir,
                             params.run_transdecoder,
                             workflow)
}