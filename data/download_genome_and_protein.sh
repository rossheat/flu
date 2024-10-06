#!/usr/bin/env bash
set -euo pipefail

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

install_package() {
    if command_exists apt-get; then
        sudo apt-get update && sudo apt-get install -y "$1"
    elif command_exists yum; then
        sudo yum install -y "$1"
    elif command_exists brew; then
        brew install "$1"
    else
        echo "Unable to install $1. Please install it manually."
        exit 1
    fi
}

windows_download_extract() {
    echo "Downloading data using PowerShell..."
    powershell.exe -Command "Invoke-WebRequest -Uri '$1' -OutFile 'influenza_a_data.zip'"
    echo "Extracting data..."
    powershell.exe -Command "Expand-Archive -Path 'influenza_a_data.zip' -DestinationPath 'temp_influenza_data'"
}

if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
    if ! command_exists powershell.exe; then
        echo "PowerShell is required but not found. Please install PowerShell."
        exit 1
    fi
else
    for tool in wget unzip; do
        if ! command_exists "$tool"; then
            echo "$tool is not installed. Attempting to install..."
            install_package "$tool"
        fi
    done
fi

URL="https://api.ncbi.nlm.nih.gov/datasets/v2alpha/genome/accession/GCA_042608115.1/download?include_annotation_type=GENOME_FASTA&include_annotation_type=GENOME_GFF&include_annotation_type=RNA_FASTA&include_annotation_type=CDS_FASTA&include_annotation_type=PROT_FASTA&include_annotation_type=SEQUENCE_REPORT&hydrated=FULLY_HYDRATED"

if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
    windows_download_extract "$URL"
else
    wget -q -O influenza_a_data.zip "$URL"
    unzip -q influenza_a_data.zip -d temp_influenza_data
fi

if [[ ! -f temp_influenza_data/ncbi_dataset/data/GCA_042608115.1/GCA_042608115.1_ASM4260811v1_genomic.fna ]]; then
    echo "Error: Required genomic.fna file not found after extraction."
    echo "Please download the data manually from https://www.ncbi.nlm.nih.gov/datasets/genome/GCA_042608115.1/"
    echo "and place the GCA_042608115.1_ASM4260811v1_genomic.fna file in the current directory."
    exit 1
fi

if [[ ! -f temp_influenza_data/ncbi_dataset/data/GCA_042608115.1/protein.faa ]]; then
    echo "Warning: protein.faa file not found after extraction."
    echo "The protein.faa file may not be included in the download or may have a different name."
else
    mv temp_influenza_data/ncbi_dataset/data/GCA_042608115.1/protein.faa .
    echo "protein.faa file has been moved to the current directory."
fi

mv temp_influenza_data/ncbi_dataset/data/GCA_042608115.1/GCA_042608115.1_ASM4260811v1_genomic.fna .
rm -rf temp_influenza_data influenza_a_data.zip

echo "Process complete. GCA_042608115.1_ASM4260811v1_genomic.fna is now in the current directory."
if [[ -f protein.faa ]]; then
    echo "protein.faa is also in the current directory."
fi