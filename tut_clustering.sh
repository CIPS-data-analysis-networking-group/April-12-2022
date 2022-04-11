#Simplified clustering tutorial. Acer VanWallendael April 11 2022

##if you haven't already upload the files using a file manager or SFTP
##in a new window
sftp user@rsync.hpcc.msu.edu
put tut_files.tar.gz
##exit the sftp window
bye

#log into HPCC. 
ssh user@gateway.hpcc.msu.edu

#In the SSH window, unzip the tutorial files
tar -xzvf tut_files.tar.gz 

cd tut_files

ll

#you should have a file and a directory: 
#drwxr-s--- 2 vanwall1 lowrylab     8192 Apr 11 11:01 phix_index
#-rw-r----- 1 vanwall1 lowrylab 56993448 Apr 11 09:53 seqs_new_LSU.fastq

#START CLUSTERING####

#load modules. If you have been on the cluster use module purge to clean previous ones
module load icc/2018.1.163-GCC-6.4.0-2.28
module load ifort/2018.1.163-GCC-6.4.0-2.28
module load impi/2018.1.163
module load Bowtie2/2.3.4.1

mkdir no_phix

#REMOVE PHIX. use the prefix of the phix bowtie2 index files
#high memory usage, but quick run. Better as a job submission for larger samples
bowtie2 -x phix_index/my_phix -U seqs_new_LSU.fastq -t -p 20 --un no_phix/seqs_new_LSU_R1.nophix.fastq -S no_phix/seqs_new_LSU_R1.contaminated_align.sam 2> no_phix/seqs_new_LSU_R1.nophix.log

#REMOVE PRIMERS
module load GCC/7.3.0-2.30  OpenMPI/3.1.1
module load cutadapt/2.1-Python-3.6.6
cutadapt -g ACCCGCTGAACTTAAGC -e 0.01 --discard-untrimmed --match-read-wildcards no_phix/seqs_new_LSU_R1.nophix.fastq > stripped_LSU_R1.fastq

#STRIP 3bp variable region
/mnt/research/rdp/public/thirdParty/usearch11.0.667_i86linux64 -fastq_filter stripped_LSU_R1.fastq -fastq_stripleft 3 -fastqout trimmed_LSU_R1.fastq

mkdir filtered
#FILTER poor quality reads
/mnt/research/rdp/public/thirdParty/usearch11.0.667_i86linux64 -fastq_filter trimmed_LSU_R1.fastq -fastq_maxee 1.0 -fastq_trunclen 200 -fastq_maxns 0 -fastqout filtered/filtered_LSU_R1.fastq

mkdir clustered_OTU_ESV/

#DEREPLICATE
/mnt/research/rdp/public/thirdParty/usearch11.0.667_i86linux64 -fastx_uniques filtered/filtered_LSU_R1.fastq -fastaout clustered_OTU_ESV/uniques_LSU_R1.fasta -sizeout

#UPARSE 97% OTUs
#Slowest, memory intensive steps. Require job submission for most projects.
#clustering 
/mnt/research/rdp/public/thirdParty/usearch11.0.667_i86linux64 -cluster_otus clustered_OTU_ESV/uniques_LSU_R1.fasta -minsize 2 -otus clustered_OTU_ESV/otus_LSU_R1.fasta -uparseout clustered_OTU_ESV/uparse_otus_LSU_R1.txt -relabel OTU_ --threads 20

#making OTU table. 
/mnt/research/rdp/public/thirdParty/usearch11.0.667_i86linux64 -otutab filtered/filtered_LSU_R1.fastq -otus clustered_OTU_ESV/otus_LSU_R1.fasta -otutabout clustered_OTU_ESV/otu_table_LSU_UPARSE_R1.txt

#check outputs
ll clustered_OTU_ESV
head clustered_OTU_ESV/otu_table_LSU_UPARSE_R1.txt

#count the lines and subtract 1 to get the number of OTUs
wc -l clustered_OTU_ESV/otu_table_LSU_UPARSE_R1.txt 