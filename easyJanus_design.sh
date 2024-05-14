#!/bin/bash

usage() {
	echo "Usage: $0 [-t /path/to/targets.txt] [-f /path/to/genome.fasta] [-o /path/to/output_directory] [-c|-d]" >&2
	echo "Required options:" >&2
	echo " -t : Full path to a file containing a list of targets in 4 columns:" >&2
	echo "		contig_name - From the genome.fasta with no spaces or special characters (except underscores) " >&2
	echo "		target_name - No spaces or special characters (except underscores) " >&2
	echo "		start coordinate (digits)"  >&2
	echo "		end coordinate (digits)"  >&2
	echo "			Columns are separated by spaces or tabs"  >&2
	echo "			start > end if target is on the reverse strand"  >&2
	echo " -f : Full path to a genome nucleotide sequence file in (multi)fasta format without duplicated headers " >&2
	echo " -o : Full path to an output directory where files can be written " >&2
	echo " -c|-d : -c for circular replicons without overlapping ends or -d for draft or linear genomes" >&2	
	echo "Example command: $0 -f /home/user/Documents/TIGR4.fasta -t /home/user/Documents/targets.txt -o /home/user/Documents/easyJanus_output -c "
	echo "The generated files will be in /home/user/Documents/easyJanus_output " 
}

is_dir() {
	local path=$1
	[ -d "$path" ]
}

is_file() {
	local path=$1
	[ -f "$path" ]
}

case "$1" in -h|--help)
	usage
	exit 0
	;;
esac

while getopts ":t:f:o:cd" opt; do
	case $opt in
		t) tf="$OPTARG" 
			if ! is_file "$tf"; then
				echo "Error: $tf is not a regular file" >&2
				usage
				exit 1
			fi
		;;
		f) gf="$OPTARG"
			if ! is_file "$gf"; then
				echo "Error: $gf is not a regular file" >&2
				usage
				exit 1
			fi
		 ;;
		o) od="$OPTARG" 
			if ! is_dir "$od"; then
				echo "Error: $od is not a directory" >&2
				usage
				exit 1
			fi		
		;;
		c)
		if [ ! -z "$flag" ]; then
			echo "Error: Only one of -c or -d is allowed" >&2
			usage
			exit 1
		fi
		flag="c" 
		;;
		d) 
		if [ ! -z "$flag" ]; then
			echo "Error: Only one of -c or -d is allowed" >&2
			usage
			exit 1
		fi
		flag="d"
		;;
		\?)
			echo "Error: Invalid option -$OPTARG" >&2
			usage
			exit 1
			;;
		:)
			echo "Error: Option -$OPTARG requires an argument" >&2
			usage
			exit 1
			;;
	esac
done

base=$(basename "${tf%.*}")

sudo docker run -v $tf:/app/targets.txt -v $gf:/app/input.fasta -v $od:/app/output/ easyjanus_design:latest /usr/bin/perl easyJanus_design.sh -$flag 

mv -f $od/targets_design.csv $od/$base\_design.csv
mv -f $od/targets_fragments.fasta $od/$base\_fragments.fasta
if [ -s $od/targets_skipped.txt ]; then
mv -f $od/targets_skipped.txt $od/$base\_skipped.txt
else
mv -f $od/targets_skipped.txt $od/$base\_skipped.txt
rm -f $od/$base\_skipped.txt
fi

