process run_trinity {
    
    tag { id }

    publishDir "${outdir}/trinity", mode: 'copy'

    label 'trin'

    input:
        tuple id, file(reads)
        val lib_type
        val outdir
        val trinity_opt
        val wf

    output:
        tuple id, file("*.Trinity.fasta"), emit: fasta
        file "*SuperTrans*"
        file "*.gene_trans_map"

    when:
        wf.contains('transcript_pipeline')

    script:
    def opt_args = trinity_opt ?: ''

    if(lib_type == 'paired') {
        """
        Trinity \
        --seqType fq \
        --max_memory 50G \
        --left ${reads[0]} \
        --right ${reads[1]} \
        --output \${PWD}/Trinity_${id} \
        --CPU ${task.cpus} \
        --include_supertranscripts \
        --full_cleanup \
        ${opt_args}
        """
    } else if(lib_type == 'single') {
        """
        Trinity \
        --seqType fq \
        --max_memory 50G \
        --single ${reads} \
        --output \${PWD}/Trinity_${id} \
        --CPU ${task.cpus} \
        --include_supertranscripts \
        --full_cleanup \
        ${opt_args}
        """
    }
    
}

process run_cdhit {
    
    tag { id }

    publishDir "${outdir}/cdhit", mode: 'copy'

    input:
        tuple id, path(fastaFile)
        val outdir
        val cdhit
        val wf

    output:
        tuple id, file("*.fasta"), emit: fasta
        file "*.clstr"

    when:
        wf.contains('transcript_pipeline') && cdhit == true

    script:
    """
    cd-hit-est -o ${id}_cdhit.fasta -c 0.98 -i ${fastaFile} -p 1 -d 0 -b 3 -T ${task.cpus}
    """
}

process get_databases {
    
    publishDir "${FASTDIR}/nf-databases", mode: 'copy'

    input:
        val transdecoder
        val wf

    output:
        path "*.fasta*", optional: true
        path "*.hmm*", optional: true

    when:
        wf.contains('transcript_pipeline') && transdecoder == true

    script:
    """
    if [[ ! -f \${FASTDIR}/nf-databases/uniprot_sprot.fasta || ! -f \${FASTDIR}/nf-databases/Pfam-A.hmm ]]; then
        wget ftp://ftp.uniprot.org/pub/databases/uniprot/current_release/knowledgebase/complete/uniprot_sprot.fasta.gz

        wget ftp://ftp.ebi.ac.uk/pub/databases/Pfam/current_release/Pfam-A.hmm.gz

        gunzip uniprot_sprot.fasta.gz
        gunzip Pfam-A.hmm.gz

        makeblastdb \
        -in uniprot_sprot.fasta \
        -dbtype nucl \
        -input_type fasta \
        -parse_seqids

        hmmpress Pfam-A.hmm

    else
        echo "Databases exist"
    fi
    
    """

}

process run_transdecoder_longorfs {

    tag { id }

    publishDir "${outdir}/transdecoder", mode: 'copy'

    label 'transd'

    input:
        tuple id, path(fastaFile)
        val outdir
        val transdecoder
        val wf

    output:
        tuple id, path("${id}_longOrf"), emit: path_longOrf

    when:
        wf.contains('transcript_pipeline') && transdecoder == true
    
    script:
    """
    Transdecoder.LongOrfs -t ${fastaFile} --output_dir ${id}_longOrf
    """
}

process run_blast {
    
    tag { id }

    publishDir "${outdir}/transdecoder/blast", mode: 'copy'

    label 'homology'

    input:
        tuple id, path(longOrf)
        val outdir
        val transdecoder
        val wf

    output:
        tuple id, path("${id}.outfmt6")

    when:
        wf.contains('transcript_pipeline') && transdecoder == true

    script:
    """
    blastp \
    -query ${longOrf}/longest_orfs.pep \
    -db \${FASTDIR}/nf-databases/uniprot_sprot.fasta \
    -max_target_seqs 1 \
    -outfmt 6 \
    evalue 1e-5 \
    -num_threads ${task.cpus} > ${id}.outfmt6
    """

}

process run_hmmer {
    
    tag { id }

    publishDir "${outdir}/transdecoder/hmmer", mode: 'copy'

    label 'homology'

    input:
        tuple id, path(longOrf)
        val outdir
        val transdecoder
        val wf

    output:
        tuple id, path("${id}.domtblout")

    when:
        wf.contains('transcript_pipeline') && transdecoder == true

    script:
    """
    hmmscan \
    --cpu ${task.cpus} \
    --domtblout ${id}.domtblout \
    \${FASTDIR}/nf-databases/Pfam-A.hmm \
    ${longOrf}/longest_orfs.pep
    """
}

process run_transdecoder_predict {

    tag { id }

    publishDir "${outdir}/transdecoder", mode: 'copy'

    label 'transd'

    input:
        tuple id, path(fastaFile), path(longOrfs), path(blast), path(hmmer)
        val outdir
        val transdecoder
        val wf

    output:
        path longOrfs
        path "*.{gff3,bed,pep,cds}"

    when:
        wf.contains('transcript_pipeline') && transdecoder == true
    
    script:
    """
    Transdecoder.Predict -t ${fastaFile} \
    --retain_pfam_hits ${hmmer} \
    --retain_blastp_hits ${blast} \
    --output_dir ${longOrfs}
    """
}