#!/usr/bin/env bash
help() {
  echo "Run tests to measure strong scaling performance on large real-world graphs"
  echo "Usage: $0 [data-dir] [logs-dir]"
  echo "  data-dir: Directory where the graphs are saved (default: ./Data)"
  echo "  logs-dir: Directory where the logs will be saved (default: ./Logs)"
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
REPO="leiden-communities-openmp"
BRANCH="strong-scaling-icpp2024"


# Parse arguments
if [[ "$1" == "-h" || "$1" == "--help" ]]; then help; fi
if [[ "$1" != "" ]]; then DATA="$1"; fi
if [[ "$2" != "" ]]; then LOGS="$2"; fi
OUT="$LOGS/$REPO--$BRANCH.log"
EXE="$REPO/a.out"


# Prepare
echo "Running tests to measure strong scaling performance on large real-world graphs ..."
mkdir -p "$LOGS"
ulimit -s unlimited
printf "" > "$OUT"


# Download program
if [[ "$DOWNLOAD" != "0" ]]; then
  rm -rf $REPO
  git clone https://github.com/puzzlef/$REPO
  cd $REPO
  git checkout $BRANCH
  cd ..
fi


# Fixed config
# export OMP_STACKSIZE="4G"
: "${TYPE:=float}"
: "${MAX_THREADS:=64}"
: "${REPEAT_METHOD:=1}"
# Define macros (dont forget to add here)
DEFINES=(""
"-DTYPE=$TYPE"
"-DMAX_THREADS=$MAX_THREADS"
"-DREPEAT_METHOD=$REPEAT_METHOD"
)


# Compile
cd $REPO
g++ ${DEFINES[*]} -std=c++17 -O3 -fopenmp main.cxx
cd ..


# Run
runEach() {
  stdbuf --output=L "$EXE" "$DATA/indochina-2004.mtx"  0 0 2>&1 | tee -a "$OUT"
  stdbuf --output=L "$EXE" "$DATA/uk-2002.mtx"         0 0 2>&1 | tee -a "$OUT"
  stdbuf --output=L "$EXE" "$DATA/arabic-2005.mtx"     0 0 2>&1 | tee -a "$OUT"
  stdbuf --output=L "$EXE" "$DATA/uk-2005.mtx"         0 0 2>&1 | tee -a "$OUT"
  stdbuf --output=L "$EXE" "$DATA/webbase-2001.mtx"    0 0 2>&1 | tee -a "$OUT"
  stdbuf --output=L "$EXE" "$DATA/it-2004.mtx"         0 0 2>&1 | tee -a "$OUT"
  stdbuf --output=L "$EXE" "$DATA/sk-2005.mtx"         0 0 2>&1 | tee -a "$OUT"
  stdbuf --output=L "$EXE" "$DATA/com-LiveJournal.mtx" 1 0 2>&1 | tee -a "$OUT"
  stdbuf --output=L "$EXE" "$DATA/com-Orkut.mtx"       1 0 2>&1 | tee -a "$OUT"
  stdbuf --output=L "$EXE" "$DATA/asia_osm.mtx"        1 0 2>&1 | tee -a "$OUT"
  stdbuf --output=L "$EXE" "$DATA/europe_osm.mtx"      1 0 2>&1 | tee -a "$OUT"
  stdbuf --output=L "$EXE" "$DATA/kmer_A2a.mtx"        1 0 2>&1 | tee -a "$OUT"
  stdbuf --output=L "$EXE" "$DATA/kmer_V1r.mtx"        1 0 2>&1 | tee -a "$OUT"
}

runEach
echo "Tests to measure strong scaling performance on large real-world graphs completed"
echo ""
