#!/bin/bash

#Refs for OTU picking, chimera checking
#Raw was used in order to achieve compatibility with Tax4Fun
reference_seqs=SILVA_123/97_otus_16S.fasta
uclust_params_rev=params/uclust_ref_params_rev.txt
reference_tax_raw=SILVA_123/raw_taxonomy.txt

#If needed, linearize fasta files
mkdir split_labelled_split_libs_new_general_mads_pipeline

cat all_general_mads_pipeline_fixed_fastqs_split/seqs.fna | awk '{if (substr($0,1,1)==">"){if (p){print "\n";} print $0} else printf("%s",$0);p++;}END{print "\n"}' > all_general_mads_pipeline_fixed_fastqs_split/seqs_lin.fna
echo '\n seqs.fna linearized to seqs.fna \n'

# Split to input to USEARCH 6.1
# # Generates 1051218 lines-long subsets of seqs_lin.fna
split -l 1051218 all_general_mads_pipeline_fixed_fastqs_split/seqs_lin.fna split_labelled_split_libs_new_general_mads_pipeline/
echo '\n Splitted seqs_lin.fna \n'

# Rename split files to suffix .fna, create individual folders for each file in order to chimera check
for i in `ls /general_mads_pipeline/split_labelled_split_libs_new_general_mads_pipeline`;
    do
    mv split_labelled_split_libs_new_general_mads_pipeline/$i split_labelled_split_libs_new_general_mads_pipeline/$i.fna
    echo $i' renamed'
done

for i in `ls /general_mads_pipeline/split_labelled_split_libs_new_general_mads_pipeline/`;
    do
    mkdir split_labelled_split_libs_new_general_mads_pipeline/${i%.*}
    mv split_labelled_split_libs_new_general_mads_pipeline/$i split_labelled_split_libs_new_general_mads_pipeline/${i%.*}/$i
    echo $i' moved'
    # echo ${i%.*}
done

# Chimera checking for each of the split files using usearch61
for i in `ls /general_mads_pipeline/split_labelled_split_libs_new_general_mads_pipeline`;
    do
    identify_chimeric_seqs.py \
	   -i /general_mads_pipeline/split_labelled_split_libs_new_general_mads_pipeline/$i/$i* \
	   -m usearch61 \
	   -r reference_seqs \
	   -o /general_mads_pipeline/split_labelled_split_libs_new_general_mads_pipeline/$i/ \
	   --threads 6

echo '\n Finished IDing chimeras for '$i '\n'
done

mkdir chimera_ids_new_general_mads_pipeline

#Concatenate all chimeras.txt out of USEARCH 6.1
cat ./split_labelled_split_libs_new_general_mads_pipeline/*/chimeras.txt > chimera_ids_new_general_mads_pipeline/chimera_ids.txt
echo '\n Concatenated chimeras out\n'

mkdir labelled_split_libs_chimerafree_new_general_mads_pipeline

# Filter them out of the original file
filter_fasta.py \
  -f all_general_mads_pipeline_fixed_fastqs_split/seqs_lin.fna \
  -s chimera_ids_new_general_mads_pipeline/chimera_ids.txt \
  --negate \
  -o labelled_split_libs_chimerafree_new_general_mads_pipeline/labelled_split_libs_chimerafree_new.fna

echo '\n Done filtering chimeras out from linearized fasta \n'

# If needed, clean '.fastq' in sample names
# awk '{gsub(".fastq", "");print}' labelled_split_libs_chimerafree_new_general_mads_pipeline/labelled_split_libs_chimerafree_new.fna > labelled_split_libs_chimerafree_new_general_mads_pipeline/labelled_split_libs_chimerafree_new_trimmed_names.fna

echo '\n Picking Closed-Reference OTUs with reverse strand picking \n'

pick_closed_reference_otus.py \
  -i labelled_split_libs_chimerafree_new_general_mads_pipeline/labelled_split_libs_chimerafree_new_trimmed_names.fna \
  -r $reference_seqs \
  -t $reference_tax_raw \
  -p $uclust_params_rev \
  -a \
  -O 2 \
  -f \
  -o ./cr_otus_labelled_split_libs_chimerafree_rev_new_general_mads_pipeline_rawtax

echo '\n Done picking Closed-Reference OTUs  with reverse strand picking \n'

echo '\n END \n'
