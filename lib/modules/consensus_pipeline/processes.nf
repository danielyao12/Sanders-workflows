process run_index {
    tag { ref }

    publishDir "${pth}", mode: 'copy'

    label 'index'

    input:
        tuple path(ref), pth
        val wf

    output:
        tuple pth, file("${ref.baseName}*.{amb,ann,bwt,pac,sa,fai}"), val("${pth}/${ref}"), emit: refs

    when:
        wf.contains('consensus_pipeline')

    script:
        """
        if [[ -f ${pth}/${ref}.fai ]]; then
            cp ${pth}/${ref}.fai \${PWD}
        else 
            samtools faidx ${ref}
        fi 

        if [[ -f ${pth}/${ref}.bwt ]]; then
            cp ${pth}/${ref}.bwt \${PWD}
            cp ${pth}/${ref}.amb \${PWD}
            cp ${pth}/${ref}.ann \${PWD}
            cp ${pth}/${ref}.pac \${PWD}
            cp ${pth}/${ref}.sa \${PWD}
        else 
            bwa index ${ref}
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
        tuple path("*filtered.bam"), path("*filtered.bam.bai"), emit: bam
        file "*.flagstat"

    when:
        wf.contains('consensus_pipeline')

    script:
        def opt_args = opt ?: ''

        """
        bwa mem ${opt_args} -t ${task.cpus} ${ref} ${seqs} | \
        samtools sort -@ ${task.cpus} -O BAM -o ${id}.bam

        samtools index -@ ${task.cpus} ${id}.bam

        samtools flagstat -@ ${task.cpus} ${id}.bam > ${id}.flagstat

        samtools view -b -@ ${task.cpus} -F 4 ${id}.bam | \
        samtools sort -O BAM -@ ${task.cpus} -o ${id}_filtered.bam

        samtools index -@ ${task.cpus} ${id}_filtered.bam

        samtools flagstat -@ ${task.cpus} ${id}_filtered.bam > ${id}_filtered.flagstat
        """        
}

process run_consensus {
    tag { id }

    publishDir "${outdir}/consensus/02_consensus/${ref.simpleName}", mode: 'copy'

    input:
        tuple id, file(seqs), path(ref), file(idx)
        val outdir
        tuple file(bam), file(bai)
        val mpileup
        val norm
        val filter
        val view
        val consensus
        val wf

    output:
        file "${id}.fasta"
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