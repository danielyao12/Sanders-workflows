# Sanders group common workflows

This repository contains `Nextflow` implementations of common workflows used by
the Sanders research group. The current workflows I am looking to implement are:

* [x] [QC pipeline](https://github.com/a-lud/Sanders-workflows/wiki/QC-Pipeline)
* [x] [Stacks 2 pipeline](https://github.com/a-lud/Sanders-workflows/wiki/Stacks-pipeline)
* [x] [CodeML](https://github.com/a-lud/Sanders-workflows/wiki/CodeML-pipeline)
* [x] [Consensus calling](https://github.com/a-lud/Sanders-workflows/wiki/Consensus-calling)
* [x] [Transcriptome assembly pipeline](https://github.com/a-lud/Sanders-workflows/wiki/Transcript-assembly-pipeline)
* [x] [Variant calling](https://github.com/a-lud/Sanders-workflows/wiki/Variant-calling-pipeline)

If there are any other analyses that you are interested in having as a workflow,
create an issue or message me and I'll look into implementing it.

## TODO:

Below are functionalities I wish to implement.

* Deomgraphic history sub-workflows:
  * PSMC
  * MSMC
* MSA pipeline
  * Align peptide
  * Convert peptide alignment to nucleotide sequence
  * Clean alignments
    * HmmClean/PREQUAL/Gblocks/GUIDANCE2
* HyPhy
  * (Better) alternative to CodeML
* File checks:
  * Stacks: Population maps contain `tab` spacing and not spaces
  * Multiple: CSV files actually are comma separated

## Installation

Below are the install instructions for

- Nextflow
- Sanders-workflow pipeline
- Conda setup

### Nextflow install
Use the following command to install the Nextflow executable to **your** Phoenix
account. **This is not the pipeline!** This is the software used to run the
pipeline. I recommend installing this in your `Fast` directory (`$FASTDIR`) in a
sub-directory that is in your path (`$PATH`). Below is an example.

```{shell}
$ mkdir -p $FASTDIR/bin                     # Create the directory
$ cd $FASTDIR/bin                           # Change into the directory
$ wget -qO- https://get.nextflow.io | bash  # Download Nextflow executable in the directory
$ nextflow --help                           # Check that the installation worked
```

To add Nextflow to your path, simply run the following code **once**

```{shell}
$ echo "export PATH=$PATH:$FASTDIR/bin" >> ~/.bashrc
```

This will append the `export` command to your `.bashrc` file which is sourced
every time you log onto Phoenix. The export command essentially appends
`$FASTDIR/bin` to your `$PATH` variable, making the contents of
the `$FASTDIR/bin` directory available at the command line, meaning
you don't have to provide the full path to the Nextflow executable when you
want to use it.

### Sanders-workflow installation

To install the pipeline, I recommend creating a `pipelines` directory in
`$FASTDIR`. Below is how I would install this software.

```{shell}
$ mkdir -p ${FASTDIR}/pipelines
$ cd ${FASTDIR}/pipelines
$ git clone https://github.com/a-lud/Sanders-workflows.git # HTTPS installation
## OR
$ git clone git@github.com:a-lud/Sanders-workflows.git     # SSH installation
```

The directory `Sanders-workflows` should now exist within `${FASTDIR}/pipelines`
with all the required scripts.

### Conda setup

Each of the sub-workflows needs to install software to run. I've set this up to use
`conda`. First all users need to follow the instructions from
[here](https://wiki.adelaide.edu.au/hpc/Anaconda) under the `Configuring your conda pkgs_dirs and envs_dirs`
heading. Once that has been done, we're going to add a few conda channels, which essentially
tell conda where to look online when installing software. Run the following at the
terminal to add the required channels to your account.

```{shell}
$ module load Anaconda3
$ conda config --add channels r
$ conda config --add channels anaconda
$ conda config --add channels bioconda
$ conda config --add channels etetoolkit
$ conda config --add channels conda-forge
```

Check the channels are there by running the following command:

```{shell}
$ conda config --show
```

This will print a whole lot of stuff to screen, but within the printout
you should see something like the following:

```{shell}
channels:
  - conda-forge
  - etetoolkit
  - bioconda
  - anaconda
  - r
  - defaults
```

If this information is there, then you are good to go.

## Pipeline specifics

Please visit the [wiki](https://github.com/a-lud/Sanders-workflows/wiki) for detailed information regarding each sub-workflow.

## Author

Alastair Ludington: alastair.ludington@adelaide.edu.au