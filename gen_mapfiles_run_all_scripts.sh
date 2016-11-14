#!/bin/bash

#generating mapping files for all samples in study
#
mkdir mapping_files
#
#Copy each line from SraRunTable_final.txt after the first one, write to individual txt, copy first line in SraRunTable_final.txt to all those files
awk 'NR>1{printf "%s\n", $line>"last_mapping_files/"$1".map.txt"}' general_metadata.txt
grep "#SampleID" general_metadata.txt | tee -a last_mapping_files/*.map.txt

#Switch first to second line, File name according to sampleID (RunS, for now)
for file in last_mapping_files/*.map.txt; do
  sed '1{h;d};2{x;H;x}' $file > tmp_file
  mv tmp_file $file
done

# generating processing scripts for each individual study
# copies general script to folder, changes name accordingly, alters file to correspond to folder's name

for folder in `ls Studies`;
  do
    cp general_mads_pipeline.sh Studies/$folder/
    echo 'Copied script to '$folder
    mv Studies/$folder/*.sh Studies/$folder/$folder.sh
    echo 'Renamed script'
    grep -rl 'general_mads_pipeline' Studies/$folder/$folder.sh | xargs sed -i 's/general_mads_pipeline/'$folder'/g'
    echo 'Altered script to match current folder'
done

# Running all individual studies, one at a time.

for folder in `ls Studies`;
  do
    echo '\nStarting study ' $folder
    sh Studies/$folder/$folder.sh
    echo '\nDone running ' $folder
done
