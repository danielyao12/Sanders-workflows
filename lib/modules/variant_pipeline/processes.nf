process run_index {
    tag { ref }

    publishDir "${pth}", mode: 'copy'

    label 'index'

    input:
        tuple path(ref), pth
        val wf

    output:
        tuple pth, file("${ref.baseName}*.{amb,ann,64,32,pac,0123,fai,dict}"), val("${pth}/${ref}"), emit: refs

    when:
        wf.contains('variant_pipeline')

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

        if [[ -f ${pth}/${ref.baseName}.dict ]]; then
            cp ${pth}/${ref.baseName}.dict \${PWD}
        else
            gatk CreateSequenceDictionary -R ${ref} 
        fi
        """
}

process run_bwa {
    tag { id }

    publishDir "${outdir}/variants/01_bwa/${ref.simpleName}", mode: 'copy'

    label 'bwa'

    input:
        tuple id, file(seqs), path(ref), file(idx)
        val outdir
        val opt
        val wf

    output:
        tuple id, path("*bam"), path("*bam.bai"), emit: bam
        file "*.flagstat"

    when:
        wf.contains('variant_pipeline')

    script:
        def opt_args = opt ?: ''

        """
        bwa-mem2 mem ${opt_args} -t ${task.cpus} ${ref} ${seqs} | \
        samtools sort -O BAM -o ${id}.bam

        samtools index -@ ${task.cpus} ${id}.bam

        samtools flagstat -@ ${task.cpus} ${id}.bam > ${id}.flagstat
        """        
}

process run_variantCalling_bcftools {
    tag { id } 

    publishDir "${outdir}/variants/02_variants/${ref.simpleName}/bcftools", mode: 'copy'

    label 'varCall'

    input:
        tuple id, path(ref), file(idx), file(bam), file(bai)
        val outdir
        val opt_mpileup
        val opt_norm
        val wf
    
    output:
        tuple file("${id}.vcf.gz"), file("${id}.vcf.gz.csi")

    when:
        wf.contains('variant_pipeline')
    
    script:
        def opt_m = opt_mpileup ?: ''
        def opt_n = opt_norm ?: ''

        """
        bcftools mpileup -Ou ${opt_m} -f ${ref} ${bam} | \
        bcftools call -Ou -c - | \
        bcftools norm ${opt_n} -f ${ref} -Ou | \
        bcftools sort --temp-dir \${PWD} -Oz -o ${id}.vcf.gz

        bcftools index ${id}.vcf.gz
        """
}

process run_gatk_haplotypeCaller {
    tag { id } 

    publishDir "${outdir}/variants/02_variants/${ref.simpleName}/haplotypeCaller", mode: 'copy'

    label 'varCall'

    input:
        tuple id, path(ref), file(idx), file(bam), file(bai)
        val outdir
        val opt_haplotypeCaller
        val wf

    output:
        tuple id, file("${id}.g.vcf.gz"), file("${id}.g.vcf.gz.tbi"), emit: vcf_files

    when:
        wf.contains('variant_pipeline')
    
    script:
    def opt = opt_haplotypeCaller ?: ''
    """
    gatk HaplotypeCaller \
    --input ${bam} \
    --output ${id}.g.vcf.gz \
    --reference ${ref} \
    --native-pair-hmm-threads ${task.cpus} \
    --tmp-dir \${PWD} \
    -ERC GVCF
    """
}

process run_gatk_combine {
    tag { 'CombineGVCF' } 

    publishDir "${outdir}/variants/02_variants/${ref.simpleName}/combineGVCF", mode: 'copy'

    label 'varCall'

    input:
        tuple path(ref), file(idx), file(data), val(str)
        val outdir
        val opt_combine
        val wf

    output:
        tuple file(ref), file(idx), file("combined.g.vcf.gz"), file("combined.g.vcf.gz.tbi"), emit: combined

    when:
        wf.contains('variant_pipeline')
    
    script:
    def opt = opt_combine ?: ''
    """
    gatk CombineGVCFs \
    ${opt} \
    --reference ${ref} \
    ${str} \
    --output combined.g.vcf.gz
    """
}

process run_genotypeGVCF_combined {
    tag { 'genotypeCombined' } 

    publishDir "${outdir}/variants/02_variants/${ref.simpleName}/genotypeGVCF", mode: 'copy'

    label 'varCall'

    input:
        tuple path(ref), file(idx), file(vcf), file(tbi)
        val outdir
        val opt_genotype
        val wf

    output:
        tuple file("genotyped.vcf.gz"), file("genotyped.vcf.gz.tbi")

    when:
        wf.contains('variant_pipeline')

    script:
        def opt = opt_genotype ?: ''
        """
        gatk GenotypeGVCFs \
        --reference ${ref} \
        --variant ${vcf} \
        --output genotyped.vcf.gz \
        --include-non-variant-sites \
        ${opt}
        """

}

process run_genotypeGVCF {
    tag { id } 

    publishDir "${outdir}/variants/02_variants/${ref.simpleName}/genotypeGVCF", mode: 'copy'

    label 'varCall'

    input:
        tuple id, path(ref), file(idx), file(vcf), file(tbi)
        val outdir
        val opt_genotype
        val wf

    output:
        tuple file("${id}.genotyped.vcf.gz"), file("${id}.genotyped.vcf.gz.tbi")

    when:
        wf.contains('variant_pipeline')

    script:
        def opt = opt_genotype ?: ''
        """
        gatk GenotypeGVCFs \
        --reference ${ref} \
        --variant ${vcf} \
        --output ${id}.genotyped.vcf.gz \
        --include-non-variant-sites \
        ${opt}
        """
}

process run_variant_clean_up {

    input:
        file vcfs
        val tidy
        val caller
        val combine
        val outdir
        val wf

    when:
        wf.contains('variant_pipeline') && tidy == true

    script:
    if(caller == 'bcftools') {
        """
        find ${outdir} -type f -name '*.bam' -delete
        find ${outdir} -type f -name '*.bam.bai' -delete
        """
    } else {
        if(combine){
            """
            find ${outdir} -type f -name '*.bam' -delete
            find ${outdir} -type f -name '*.bam.bai' -delete
            find ${outdir} -type d -name 'haplotypeCaller' -exec rm -r {} +
            find ${outdir} -type d -name 'combineGVCF' -exec rm -r {} +
            """
        } else {
            """
            find ${outdir} -type f -name '*.bam' -delete
            find ${outdir} -type f -name '*.bam.bai' -delete
            find ${outdir} -type d -name 'haplotypeCaller' -exec rm -r {} +
            """
        }
    }
}