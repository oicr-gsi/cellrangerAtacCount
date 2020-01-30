# cellrangerAtacCount

Workflow to generate single-cell accessibility counts for a single library.

## Overview

## Usage

### Cromwell
```
java -jar cromwell.jar run cellrangerAtacCount.wdl --inputs inputs.json
```

### Inputs

#### Required workflow parameters:
Parameter|Value|Description
---|---|---
`runID`|String|A unique run ID string.
`fastqs`|Array[File]|Array of input fastqs.
`samplePrefix`|String|Path to folder containing fastq files.
`referenceDirectory`|String|Path to the Cell Ranger ATAC compatible geneome reference.


#### Optional workflow parameters:
Parameter|Value|Default|Description
---|---|---|---
`localCores`|String?|None|Restricts cellranger-atac to use specified number of cores to execute pipeline stages. By default, cellranger-atac will use all of the cores available on your system.
`localMem`|Int?|None|Restricts cellranger-atac to use specified amount of memory (in GB) to execute pipeline stages. By default, cellranger-atac will use 90% of the memory available on your system.


#### Optional task parameters:
Parameter|Value|Default|Description
---|---|---|---
`count.modules`|String?|"cellranger-atac"|Environment module name to load before command execution.
`count.cellranger_atac`|String?|"cellranger-atac"|
`count.timeout`|Int|24|


### Outputs

Output | Type | Description
---|---|---
`singleCell`|File|Per-barcode fragment counts & metrics.
`possortedGenomeBam`|File|Position sorted BAM file.
`possortedGenomeBamIndex`|File|Position sorted BAM index.
`peaks`|File|Bed file of all called peak locations.
`peakBcMatrix`|File|Raw and unfiltered peak barcode matrix in mex format.
`analysis`|File|Zipped directory of analysis files.
`fragments`|File|Barcoded and aligned fragment file.
`fragmentsIndex`|File|Fragment file index.
`filteredTfBcMatrix`|File|Filtered peak barcode matrix.
`matricesH5`|File|Barcode matrices in hdf5 format.
`cloupe`|File|Loupe Cell Browser input file.
`summary`|File|CSV summarizing important metrics and values.


## Niassa + Cromwell

This WDL workflow is wrapped in a Niassa workflow (https://github.com/oicr-gsi/pipedev/tree/master/pipedev-niassa-cromwell-workflow) so that it can used with the Niassa metadata tracking system (https://github.com/oicr-gsi/niassa).

* Building
```
mvn clean install
```

* Testing
```
mvn clean verify \
-Djava_opts="-Xmx1g -XX:+UseG1GC -XX:+UseStringDeduplication" \
-DrunTestThreads=2 \
-DskipITs=false \
-DskipRunITs=false \
-DworkingDirectory=/path/to/tmp/ \
-DschedulingHost=niassa_oozie_host \
-DwebserviceUrl=http://niassa-url:8080 \
-DwebserviceUser=niassa_user \
-DwebservicePassword=niassa_user_password \
-Dcromwell-host=http://cromwell-url:8000
```

## Support

For support, please file an issue on the [Github project](https://github.com/oicr-gsi) or send an email to gsi@oicr.on.ca .

_Generated with wdl_doc_gen (https://github.com/oicr-gsi/wdl_doc_gen/)_
