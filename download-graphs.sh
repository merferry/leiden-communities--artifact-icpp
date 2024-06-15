#!/usr/bin/env bash
help() {
  echo "Download large real-world graphs from the SuiteSparse Matrix Collection"
  echo "Usage: $0 [data-dir]"
  echo "  data-dir: Directory where the graphs will be saved (default: ./Data)"
  echo ""
  echo "Example:"
  echo "  $0 ./Data"
  echo ""
  echo "Note: This script requires 'wget' and 'gzip' to be installed"
  exit 1
}

# Download and extract tar zipped file
download() {
  url="$1"
  file=$(basename "$url")
  name="${file%%.*}"
  rm -f "$name"*
  echo "Downloading $file ..."
  wget "$url"
  echo "Extracting $file ..."
  tar -xzf "$file"
  mv "$name"/* .
  rm -rf "$name"
  rm -f "$file"
  echo "Done"
  echo ""
}

# Defaults
DATA="Data"

# Parse arguments
if [[ "$1" == "-h" || "$1" == "--help" ]]; then help; fi
if [[ "$1" != "" ]]; then DATA="$1"; fi

# Download graphs
echo "Downloading large real-world graphs to $DATA ..."
mkdir -p "$DATA"
cd "$DATA"
base="https://suitesparse-collection-website.herokuapp.com/MM"
download "$base/LAW/indochina-2004.tar.gz"
download "$base/LAW/uk-2002.tar.gz"
download "$base/LAW/arabic-2005.tar.gz"
download "$base/LAW/uk-2005.tar.gz"
download "$base/LAW/webbase-2001.tar.gz"
download "$base/LAW/it-2004.tar.gz"
download "$base/LAW/sk-2005.tar.gz"
download "$base/SNAP/com-LiveJournal.tar.gz"
download "$base/SNAP/com-Orkut.tar.gz"
download "$base/DIMACS10/asia_osm.tar.gz"
download "$base/DIMACS10/europe_osm.tar.gz"
download "$base/GenBank/kmer_A2a.tar.gz"
download "$base/GenBank/kmer_V1r.tar.gz"
echo "Large real-world graphs downloaded"
echo ""
