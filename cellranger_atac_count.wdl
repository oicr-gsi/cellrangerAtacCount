version 1.0

workflow cellranger_atac_count {
  input {
    String runID
    String fastqDirectory
    String samplePrefix
    String referenceDirectory
    String? localCores
    String? localMem
  }

  call count {
    input:
      runID = runID,
      fastqDirectory = fastqDirectory,
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
    fastqDirectory: "Sample name (FASTQ file prefix). Can take multiple comma-separated values."
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

task count {
  input {
    String? modules = "cellranger-atac"
    String? cellranger_atac = "cellranger-atac"
    String runID
    String fastqDirectory
    String samplePrefix
    String referenceDirectory
    String? localCores
    String? localMem = "2"
  }

  command <<<
    ~{cellranger_atac} count \
    --id "~{runID}" \
    --fastqs "~{fastqDirectory}" \
    --sample "~{samplePrefix}" \
    --reference "~{referenceDirectory}" \
    ~{"--localcores"} "~{localCores}" \
    ~{"--localmem"} "~{localMem}"

    # zip peak bc matrices
    zip -r peak_bc_matrix \
    outs/raw_peak_bc_matrix \
    outs/filtered_peak_bc_matrix

    # zip analysis
    zip -r analysis \
    outs/analysis

    # zip filtered tf bc matrix
    zip -r filtered_tf_bc_matrix \
    outs/filtered_tf_bc_matrix

    # zip matrices
    zip -r matrices_h5 \
    outs/raw_peak_bc_matrix.h5 \
    outs/filtered_peak_bc_matrix.h5 \
    outs/filtered_tf_bc_matrix.h5
  >>>

  runtime {
    memory: "~{localMem}"
    modules: "~{modules}"
  }

  output {
    File singleCell = "outs/singlecell.csv"
    File possortedGenomeBam = "outs/possorted_bam.bam"
    File possortedGenomeBamIndex = "outs/possorted_bam.bam.bai"
    File peaks = "outs/peaks.bed"
    File peakBcMatrix = "peak_bc_matrix.zip"
    File analysis = "analysis.zip"
    File fragments = "outs/fragments.tsv.gz"
    File fragmentsIndex = "outs/fragments.tsv.gz.tbi"
    File filteredTfBcMatrix = "filtered_tf_bc_matrix.zip"
    File matricesH5 = "matrices_h5.zip"
    File cloupe = "outs/cloupe.cloupe"
    File summary = "outs/summary.csv"
  }

  parameter_meta {
    runID: "A unique run ID string."
    fastqDirectory: "Sample name (FASTQ file prefix). Can take multiple comma-separated values."
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