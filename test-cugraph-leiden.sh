#!/usr/bin/env bash
help() {
  echo "Run performance tests of cuGraph Leiden on large real-world graphs"
  echo "Usage: $0 [data-dir] [logs-dir]"
  echo "  data-dir: Directory where the graphs are saved (default: ./Data)"
  echo "  logs-dir: Directory where the logs will be saved (default: ./Logs)"
  echo ""
  echo "If cuGraph is not installed, please install it using the following commands:"
  echo "  $ conda create --name cugraph-env -y"
  echo "  $ conda activate cugraph-env"
  echo "  $ conda install -c rapidsai -c conda-forge -c nvidia cugraph cuda-version=11.4 -y"
  echo ""
  echo "Before running this script, please activate the cuGraph environment using the following command:"
  echo "  $ conda activate cugraph-env"
  echo ""
  echo "Example:"
  echo "  $0 ./Data ./Logs"
  echo ""
  echo "Note: This script requires 'g++' v9.4+, 'git', and 'stdbuf' to be installed"
  exit 1
}


# Defaults
DATA="Data"
LOGS="Logs"
REPO="test-cugraph-leiden"
BRANCH="main-icpp2024"


# Parse arguments
if [[ "$1" == "-h" || "$1" == "--help" ]]; then help; fi
if [[ "$1" != "" ]]; then DATA="$1"; fi
if [[ "$2" != "" ]]; then LOGS="$2"; fi
OUT="$LOGS/$REPO--$BRANCH.log"
EXE="$REPO/a.out"


# Prepare
echo "Running performance tests of cuGraph Leiden on large real-world graphs ..."
mkdir -p "$LOGS"
ulimit -s unlimited
printf "" > "$OUT"


# Download program
if [[ "$DOWNLOAD" != "0" ]]; then
  rm -rf $REPO
  git clone https://github.com/puzzlef/$REPO && echo ""
  cd $REPO
  git checkout $BRANCH
  cd ..
fi


# Configuration
: "${CUDA_VERSION:=11.4}"


# Download tool to count disconnected communities
TOOL="graph-count-disconnected-communities"
if [[ "$DOWNLOAD" != "0" ]]; then
  rm -rf $TOOL
  git clone https://github.com/ionicf/$TOOL && echo ""
fi


# Fixed config
: "${KEY_TYPE:=uint32_t}"
: "${EDGE_VALUE_TYPE:=float}"
: "${MAX_THREADS:=64}"
# Define macros (dont forget to add here)
DEFINES=(""
"-DKEY_TYPE=$KEY_TYPE"
"-DEDGE_VALUE_TYPE=$EDGE_VALUE_TYPE"
"-DMAX_THREADS=$MAX_THREADS"
)


# Build tool
buildTool() {
  g++ ${DEFINES[*]} -std=c++17 -O3 -fopenmp main.cxx
  mv a.out ../count.out
}
cd $TOOL
buildTool
cd ..


# Run
runCugraph() {
  # $1: input file name
  # $2: is graph weighted (0/1)
  # $3: is graph symmetric (0/1)
  # $4: memory manager (default/managed)
  opt2=""
  opt3=""
  if [[ "$2" == "1" ]]; then opt2="-w"; fi
  if [[ "$3" == "1" ]]; then opt3="-s"; fi
  # Convert the graph in MTX format to CSV (space-separated)
  stdbuf --output=L printf "Converting $1 to $1.csv ...\n"                          | tee -a "$OUT"
  lines="$(node "$REPO/process.js" header-lines "$1")"
  echo "src dst" > "$1.csv"
  tail -n +$((lines+1)) "$1" >> "$1.csv"
  # Run cuGraph leiden, and save the obtained communities
  stdbuf --output=L printf "Running cuGraph Leiden on $1.csv ...\n"                 | tee -a "$OUT"
  stdbuf --output=L python3 "$REPO/main.py" "$1.csv" "$1.clstr" "$3"           2>&1 | tee -a "$OUT"
  # Count disconnected communities
  stdbuf --output=L printf "Counting disconnected communities ...\n"                | tee -a "$OUT"
  stdbuf --output=L ./count.out -i "$1" -m "$1.clstr" -k -r 0 "$opt2" "$opt3"  2>&1 | tee -a "$OUT"
  stdbuf --output=L printf "\n\n"                                                   | tee -a "$OUT"
  # Clean up
  rm -rf "$1.csv"
  rm -rf "$1.clstr"
}

runAll() {
  runCugraph "$DATA/indochina-2004.mtx"  0 0 default
  runCugraph "$DATA/uk-2002.mtx"         0 0 default
  # runCugraph "$DATA/arabic-2005.mtx"     0 0 managed
  # runCugraph "$DATA/uk-2005.mtx"         0 0 managed
  # runCugraph "$DATA/webbase-2001.mtx"    0 0 managed
  # runCugraph "$DATA/it-2004.mtx"         0 0 managed
  # runCugraph "$DATA/sk-2005.mtx"         0 0 managed
  runCugraph "$DATA/com-LiveJournal.mtx" 0 1 default
  runCugraph "$DATA/com-Orkut.mtx"       0 1 default
  runCugraph "$DATA/asia_osm.mtx"        0 1 default
  runCugraph "$DATA/europe_osm.mtx"      0 1 default
  runCugraph "$DATA/kmer_A2a.mtx"        0 1 default
  runCugraph "$DATA/kmer_V1r.mtx"        0 1 default
}

runAll
echo "Performance tests of cuGraph Leiden on large real-world graphs done"
echo ""
