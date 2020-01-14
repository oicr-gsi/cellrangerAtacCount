version 1.0

workflow cellrangerAtacCount {
  input {
    String runID
    Array[File] fastqs
    String samplePrefix
    String referenceDirectory
    String? localCores
    Int? localMem
  }

  call symlinkFastqs {
      input:
        samplePrefix = samplePrefix,
        fastqs = fastqs
    }

  call count {
    input:
      runID = runID,
      fastqDirectory = symlinkFastqs.fastqDirectory,
      samplePrefix = samplePrefix,
      referenceDirectory = referenceDirectory,
      localCores = localCores,
      localMem = localMem
  }

  output {
    File singleCell = count.singleCell
    File possortedGenomeBam = count.possortedGenomeBam
    File possortedGenomeBamIndex = count.possortedGenomeBamIndex
    File peaks = count.peaks
    File peakBcMatrix = count.peakBcMatrix
    File analysis = count.analysis
    File fragments = count.fragments
    File fragmentsIndex = count.fragmentsIndex
    File filteredTfBcMatrix = count.filteredTfBcMatrix
    File matricesH5 = count.matricesH5
    File cloupe = count.cloupe
    File summary = count.summary
  }

  parameter_meta {
    runID: "A unique run ID string."
    fastqDirectory: "Path to folder containing symlinked fastq files."
    samplePrefix: "Path to folder containing fastq files."
    referenceDirectory: "Path to the Cell Ranger ATAC compatible geneome reference."
    localCores: "Restricts cellranger-atac to use specified number of cores to execute pipeline stages. By default, cellranger-atac will use all of the cores available on your system."
    localMem: "Restricts cellranger-atac to use specified amount of memory (in GB) to execute pipeline stages. By default, cellranger-atac will use 90% of the memory available on your system."
  }

  meta {
    author: "Angie Mosquera"
    email: "Angie.Mosquera@oicr.on.ca"
    description: "Workflow to generate single-cell accessibility counts for a single library."
    dependencies: []
  }
}

task symlinkFastqs {
  input {
    Array[File] fastqs
    String? samplePrefix
  }

  command <<<
    mkdir ~{samplePrefix}
    while read line ; do
      ln -s $line ~{samplePrefix}/$(basename $line)
    done < ~{write_lines(fastqs)}
    echo $PWD/~{samplePrefix}
  >>>

  output {
     String fastqDirectory = read_string(stdout())
  }

  parameter_meta {
    fastqs: "Array of input fastqs."
  }

  meta {
    output_meta: {
      fastqDirectory: "Path to folder containing symlinked fastq files."
    }
  }
}

task count {
  input {
    String? modules = "cellranger-atac"
    String? cellranger_atac = "cellranger-atac"
    String runID
    String fastqDirectory
    String samplePrefix
    String referenceDirectory
    String? localCores
    Int? localMem = 64
    Int timeout = 24
  }

  command <<<
    ~{cellranger_atac} count \
    --id "~{runID}" \
    --fastqs "~{fastqDirectory}" \
    --sample "~{samplePrefix}" \
    --reference "~{referenceDirectory}" \
    ~{"--localcores"} "~{localCores}" \
    ~{"--localmem"} "~{localMem}"

    # compress folders
    tar cf - \
    ~{runID}/outs/raw_peak_bc_matrix \
    ~{runID}/outs/filtered_peak_bc_matrix | gzip --no-name > peak_bc_matrix.tar.gz

    tar cf - ~{runID}/outs/analysis | gzip --no-name > analysis.tar.gz

    tar cf - \
    ~{runID}/outs/filtered_tf_bc_matrix | gzip --no-name > filtered_tf_bc_matrix.tar.gz

    tar cf - \
    ~{runID}/outs/raw_peak_bc_matrix.h5 \
    ~{runID}/outs/filtered_peak_bc_matrix.h5 \
    ~{runID}/outs/filtered_tf_bc_matrix.h5 | gzip --no-name > matrices_h5.tar.gz
  >>>

  runtime {
    memory: "~{localMem} GB"
    modules: "~{modules}"
    timeout: "~{timeout}"
  }

  output {
    File singleCell = "~{runID}/outs/singlecell.csv"
    File possortedGenomeBam = "~{runID}/outs/possorted_bam.bam"
    File possortedGenomeBamIndex = "~{runID}/outs/possorted_bam.bam.bai"
    File peaks = "~{runID}/outs/peaks.bed"
    File peakBcMatrix = "peak_bc_matrix.tar.gz"
    File analysis = "analysis.tar.gz"
    File fragments = "~{runID}/outs/fragments.tsv.gz"
    File fragmentsIndex = "~{runID}/outs/fragments.tsv.gz.tbi"
    File filteredTfBcMatrix = "filtered_tf_bc_matrix.tar.gz"
    File matricesH5 = "matrices_h5.tar.gz"
    File cloupe = "~{runID}/outs/cloupe.cloupe"
    File summary = "~{runID}/outs/summary.csv"
  }

  parameter_meta {
    runID: "A unique run ID string."
    fastqDirectory: "Path to folder containing symlinked fastq files."
    samplePrefix: "Path to folder containing fastq files."
    referenceDirectory: "Path to the Cell Ranger ATAC compatible geneome reference."
    localCores: "Restricts cellranger-atac to use specified number of cores to execute pipeline stages. By default, cellranger-atac will use all of the cores available on your system."
    localMem: "Restricts cellranger-atac to use specified amount of memory (in GB) to execute pipeline stages. By default, cellranger-atac will use 90% of the memory available on your system."
    modules: "Environment module name to load before command execution."
  }

  meta {
    output_meta: {
      singleCell: "Per-barcode fragment counts & metrics.",
      possortedGenomeBam: "Position sorted BAM file.",
      possortedGenomeBamIndex: "Position sorted BAM index.",
      peaks: "Bed file of all called peak locations.",
      peakBcMatrix: "Raw and unfiltered peak barcode matrix in mex format.",
      analysis: "Zipped directory of analysis files.",
      fragments: "Barcoded and aligned fragment file.",
      fragmentsIndex: "Fragment file index.",
      filteredTfBcMatrix: "Filtered peak barcode matrix.",
      matricesH5: "Barcode matrices in hdf5 format.",
      cloupe: "Loupe Cell Browser input file.",
      summary: "CSV summarizing important metrics and values."
    }
  }
}
