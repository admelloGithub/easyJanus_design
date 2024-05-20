#!/bin/bash

usage() {
	echo "" >&2
	echo "Usage: $0 [-f /path/to/genome.fasta] [-t /path/to/targets.txt]  [-o /path/to/output_directory] [-c or -d]" >&2
	echo "" >&2
	echo "Required options:" >&2
	echo "" >&2
	echo " -t : Full path to a file containing a list of targets in 4 columns listed below:" >&2
	echo "		contig_name - From the genome.fasta with no spaces or special characters (except underscores) " >&2
	echo "		target_name - No spaces or special characters (except underscores) " >&2
	echo "		start coordinate (digits)"  >&2
	echo "		end coordinate (digits)"  >&2
	echo "       Columns are separated by spaces or tabs"  >&2
	echo "       start > end if target is on the reverse strand"  >&2
	echo "" >&2
	echo " -f : Full path to a genome nucleotide sequence file in (multi)fasta format without duplicated headers " >&2
	echo "" >&2
	echo " -o : Full path to an output directory where files can be written " >&2
	echo "" >&2
	echo " -c or -d : -c for circular replicons without overlapping ends or -d for draft or linear genomes" >&2	
	echo "" >&2
	echo "Example command: $0 -f /path/to/folder/TIGR4.fasta -t /path/to/folder/targets.txt -o /path/to/folder/easyJanus_output -c "
	echo "" >&2
	echo "The generated files will be in /path/to/folder/easyJanus_output " 
	echo "" >&2
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

if [ -z "$tf" ] || [ -z "$gf" ] || [ -z "$od" ] || [ -z "$flag" ] ; then
	echo "Error: Missing required arguments" >&2
	usage
	exit 1
fi

base=$(basename "${tf%.*}")

#############
sudo docker run -v $tf:/app/targets.txt -v $gf:/app/input.fasta -v $od:/app/output/ easyjanus_design:latest /usr/bin/perl easyJanus_design.sh -$flag 
#############

if [ -s $od/targets_design.csv ]; then
mv -f $od/targets_design.csv $od/$base\_design.csv
fi

if [ -s $od/targets_fragments.fasta ]; then
mv -f $od/targets_fragments.fasta $od/$base\_fragments.fasta
fi

if [ -s $od/targets_skipped.txt ]; then
mv -f $od/targets_skipped.txt $od/$base\_skipped.txt
else
rm -f $od/$base\_skipped.txt
fi

