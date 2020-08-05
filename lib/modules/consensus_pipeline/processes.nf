process run_index {
    tag { ref }

    publishDir "${pth}", mode: 'copy'

    label 'index'

    input:
        tuple path(ref), pth
        val wf

    output:
        tuple pth, file("${ref.baseName}*.{amb,ann,64,32,pac,0123,fai}"), val("${pth}/${ref}"), emit: refs

    when:
        wf.contains('consensus_pipeline')

    script:
        """
        if [[ -f ${pth}/${ref}.fai ]]; then
            cp ${pth}/${ref}.fai \${PWD}
        else 
            samtools faidx ${ref}
        fi 

        if [[ -f ${pth}/${ref}.bwt.2bit.64 ]]; then
            cp ${pth}/${ref}.bwt* \${PWD}
            cp ${pth}/${ref}.amb \${PWD}
            cp ${pth}/${ref}.ann \${PWD}
            cp ${pth}/${ref}.pac \${PWD}
            cp ${pth}/${ref}.0123 \${PWD}
        else 
            bwa-mem2 index ${ref}
        fi
        """
}

process run_bwa {
    tag { id }

    publishDir "${outdir}/consensus/01_bwa/${ref.simpleName}", mode: 'copy'

    label 'bwa'

    input:
        tuple id, file(seqs), path(ref), file(idx)
        val outdir
        val opt
        val wf

    output:
        tuple id, file(seqs), file(ref), file(idx), path("*.bam"), path("*.bai"), emit: bam
        file "*.flagstat"

    when:
        wf.contains('consensus_pipeline')

    script:
        def opt_args = opt ?: ''

        """
        bwa-mem2 mem -t ${task.cpus} ${ref} ${seqs} ${opt_args} | \
        samtools sort -O BAM -o ${id}.bam

        samtools index -@ ${task.cpus} ${id}.bam

        samtools flagstat -@ ${task.cpus} ${id}.bam > ${id}.flagstat
        """        
}

process run_consensus {
    tag { id }

    publishDir "${outdir}/consensus/02_consensus/${ref.simpleName}", mode: 'copy'

    label 'consensus'

    input:
        tuple id, file(seqs), path(ref), file(idx), file(bam), file(bai)
        val outdir
        val mpileup
        val norm
        val filter
        val view
        val consensus
        val wf

    output:
        path "${id}.fasta", emit: fasta
        file "${id}.vcf.gz"

    when:
        wf.contains('consensus_pipeline')

    script:
        def opt_mpileup = mpileup ?: '-d 10 -Q 20 -q 20'
        def opt_norm = norm ?: '-m +any'
        def opt_filter = filter ?: '--SnpGap 5'
        def opt_view = view ?: ''
        def opt_consensus = consensus ?: '-H 1'
        
        """
        bcftools mpileup -Ou ${opt_mpileup} -f ${ref} ${bam} | \
        bcftools call -Ou -c - | \
        bcftools norm ${opt_norm} -f ${ref} -Ou | \
        bcftools filter -Ou ${opt_filter} | \
        bcftools view ${opt_view} | \
        bcftools sort --temp-dir \${PWD} -Oz -o ${id}.vcf.gz

        bcftools index ${id}.vcf.gz

        bcftools consensus ${opt_consensus} -f ${ref} -o ${id}.fasta ${id}.vcf.gz
        """  
}

process run_consensus_clean_up {

    input:
        file fasta
        val cleanup
        val outdir
        val wf

    when:
        wf.contains('consensus_pipeline') && cleanup == true

    script:
        """
        find ${outdir} -type f -name '*.bam' -delete
        find ${outdir} -type f -name '*.bam.bai' -delete
        find ${outdir} -type f -name '*.vcf.gz' -delete
        """

}