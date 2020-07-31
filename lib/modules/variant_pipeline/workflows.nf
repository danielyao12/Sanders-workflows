include {run_index; run_bwa; run_variantCalling_bcftools; 
run_gatk_haplotypeCaller; run_gatk_combine;
run_genotypeGVCF_combined; run_genotypeGVCF; run_variant_clean_up} from './processes'

workflow variant_pipeline {
    take: seqs
    take: workflow

    main:

    // Get reference genome path
    seqs
        .map { val ->
            // Path to reference files
            String path = val[2].substring(0, val[2].lastIndexOf('/'))
            return tuple(val[2], path)
            }
        .unique()
        .set { ref }

    // Index reference + BWA index
    run_index(ref,
              workflow)

    // Join index output with sequence files - different join method based on input
    if(params.ref instanceof java.lang.String){
        
        seqs
            .combine(run_index.out.refs)
            .map {val ->
                return tuple(
                    val[0],
                    val[1],
                    val[2],
                    val[4]
                )
            }
            .set { seqs }

    } else if(params.ref instanceof java.util.ArrayList){
        
        seqs
            .join(run_index.out.refs, by: [2])
            .map {val ->
                return tuple(val[1], 
                             val[2], 
                             val[0], 
                             val[4])
            }
            .set { seqs }
    }

    // Align data to reference
    run_bwa(seqs,
            params.outdir,
            params.opt_bwa,
            workflow)

    // Make a clean reference channel: [ id, ref_file, [idx1, idx2, ...] ]
    seqs
        .map { val ->
            return tuple(val[0], val[2], val[3])
        }
        .set { clean_ref }

    // Join the ref information with the bam output
    // I'm doing this to avoid each sample having the same reference
    // but from a different working directory.
    clean_ref
        .join(run_bwa.out.bam, by: [0])
        .set { clean_var_input }

    // Method to call variants
    if(params.caller == 'bcftools') {
        run_variantCalling_bcftools(clean_var_input,
                                    params.outdir,
                                    params.opt_mpileup,
                                    params.opt_norm,
                                    workflow)
        if(params.merge) {
            // [ id, ref, [idx], vcf, csi ]
            clean_ref
                .join(run_variantCalling_bcftools.out, by: [0])
                .set { temp }

            // [ 'vcf1 vcf2 vcf3 ... vcfn' ]
            temp
                .collect { it[3] }
                .map { it.join(' ') }
                .set { vcf_str }
            
            // VCF and CSI files
            temp
                .collect{ tuple(it[3], it[4]) }
                .toList()
                .set { vcf_files }

            // Reference file + idx files
            temp
                .take(1)
                .map {return tuple(it[1], it[2])}
                .set { ref_files }

            ref_files.combine(vcf_files.combine(vcf_str)).set { merge_input }
            run_bcftools_merge(merge_input,
                               params.outdir,
                               workflow)
            run_bcftools_merge.out.set { cleanup_ch }
        } else {
            run_variantCalling_bcftools.out.collect().set { cleanup_ch }
        }
    } else {
        run_gatk_haplotypeCaller(clean_var_input,
                                 params.outdir,
                                 params.opt_haplotypeCaller,
                                 workflow)

        // Combine GVCF files?
        if(params.merge) {

            clean_ref
                .join(run_gatk_haplotypeCaller.out.vcf_files, by: [0])
                .set { temp }

            // Make string that's to be passed to gatk combineGVCFs
            // In the collect - keep only the basename of the file
            temp
                .collect {'--variant ' + it[3]}
                .map { it.join(' ')}
                .set { vcf_str }
            
            // Collect all VCF + TBI files
            temp
                .collect{ tuple(it[3], it[4]) }
                .toList()
                .set { vcf_files }

            // Reference file
            temp
                .take(1)
                .map {return tuple(it[1], it[2])}
                .set { ref_files }
            
            ref_files.combine(vcf_files.combine(vcf_str)).set { combine_input }

            run_gatk_combine(combine_input,
                             params.outdir,
                             params.opt_combineGVCF,
                             workflow)

            run_genotypeGVCF_combined(run_gatk_combine.out.combined,
                                      params.outdir,
                                      params.opt_genotypeGVCF,
                                      workflow)
            
            run_genotypeGVCF_combined.out.set{ cleanup_ch }
            
        } else {
           // Join HaplotypeCaller output with reference info
           clean_ref
                .join(run_gatk_haplotypeCaller.out.vcf_files, by: [0])
                .set { input_genotype }

            run_genotypeGVCF(input_genotype,
                             params.outdir,
                             params.opt_genotypeGVCF,
                             workflow)

            run_genotypeGVCF.out.collect().set { cleanup_ch }
        }
    }

    // Collect all fasta files so the final step happens last
    run_variant_clean_up(cleanup_ch,
                         params.tidy,
                         params.caller,
                         params.merge,
                         params.outdir,
                         workflow)
}