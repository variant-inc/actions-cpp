#!/bin/bash

cov_linux()
{
  rm -rf reports
  mkdir reports 
  pushd reports 
  for f in `find ../build/src -name '*.o'`; do
    echo "Processing $f file..."
    gcov-9 -o ${f} x
  done
  ls | wc -l
  popd
}

cov_mac(){
  gcovr -r src ./build
}

echo "Starting coverage on $OSTYPE"

if [[ "$OSTYPE" == "darwin"* ]];then
   echo "coverage on mac.."
   cov_mac
else
   echo "coverage on linux.."
   cov_linux
fi