# Sanders group common workflows

This repository contains `Nextflow` implementations of common workflows used by
the Sanders research group. The current workflows I am looking to implement are:

- [x] QC pipline
- [x] Stacks (v2) pipeline
- [] CodeML
- [] Gene Capture
- [] Variant calling

If there are any other analyses that you are interested in having as a workflow,
create an issue or message me and I'll look into implementing it.

## Installation

Use the following command to install the Nextflow executable to **your** Phoenix
account. **This is not the pipeline!** This is the software used to run the
pipeline. I recommend installing this in your `Fast` directory (`$FASTDIR`) in a
sub-directory that is in your path (`$PATH`). Below is an example.

```{shell}
$ mkdir -p $FASTDIR/bin            # Create the directory
$ cd $FASTDIR/bin                  # Change into the directory
$ wget -qO- https://get.nextflow.io | bash  # Download Nextflow executable in the directory
$ nextflow --help                           # Check that the installation worked
```

To add Nextflow to your path, simply run the following code **once**

```{shell}
$ echo "export PATH=$PATH:'$FASTDIR/bin'" >> ~/.bashrc
```

This will append the `export` command to your `.bashrc` file which is sourced
every time you log onto Phoenix. The export command essentially appends
`$FASTDIR/bin` to your `$PATH` variable, making the contents of
the `$FASTDIR/bin` directory available at the command line, meaning
you don't have to provide the full path to the Nextflow executable when you
want to use it.

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

## Pipeline specifics

Please visit the wiki for detailed information regarding each sub-workflow.
