include {run_ustacks; run_cstacks; run_sstacks; run_tsv2bam; run_gstacks; run_populations} from './processes'

workflow stacks_pipeline {
    take: reads
    take: pop_maps
    take: workflow

    main:

    run_ustacks(reads,
                workflow,
                params.outdir,
                params.ustacks_args)

    // All combinations of ustacksOut + popmap files
    run_ustacks
        .out.pth
        .collect()
        .flatten()
        .unique()
        .combine(pop_maps)
        .set { tuple_dir_map }

    // Tuple: [ Population_map, file_string ] - Not the cleanest...
    tuple_dir_map
        .map{ val -> 

            String f = val[1]
            File file = new File(f)
            sample_list = []
            file_list = []

            file.eachLine { line -> 
                def parts = line.split('\t')
                def pth = '-s ' + val[0] + '/' + parts[0]
                def fl = val[0] + '/' + parts[0] + '*'

                sample_list.add(pth)
                file_list.add(fl)
            }

            // Return file path and 
            sample_list = sample_list.join(' ')
            file_list = file_list.join(' ')
            return tuple(file, sample_list, file_list)

        }
        .set { popMap_popMapSamples }

    // Stacks pipeline
    run_cstacks(workflow,
                popMap_popMapSamples,
                params.cstacks_args,
                params.outdir)

    run_sstacks(workflow,
                run_cstacks.out.pop_path,
                params.sstacks_args)

    run_tsv2bam(workflow,
                run_sstacks.out.pop_path,
                params.tsv2bam_args)

    run_gstacks(workflow,
                run_tsv2bam.out.pop_path,
                params.gstacks_args)

    run_populations(workflow,
                run_gstacks.out.pop_path,
                params.populations_args)
    
    // emit:
    //     run_ustacks.out
}