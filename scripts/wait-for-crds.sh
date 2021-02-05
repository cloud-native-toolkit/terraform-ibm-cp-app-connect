#!/usr/bin/env bash

CRD_LIST="designerauthorings.appconnect.ibm.com,integrationservers.appconnect.ibm.com,integrationservers.appconnect.ibm.com,dashboards.appconnect.ibm.com"

IFS=',' read -ra CRDS <<< "$CRD_LIST"
for crd in "${CRDS[@]}"; do
  retrycount=10
  while [[ $(k get crd "${crd}" -o jsonpath='{.metadata.name}{"\n"}' | wc -l) -eq 0 ]] && [[ "${retrycount}" -gt 0 ]]; do
    echo "Waiting for crd: ${crd}"
    retrycount=$(( retrycount - 1 ))
    sleep 30
  done

  if [[ $(k get crd "${crd}" -o jsonpath='{.metadata.name}{"\n"}' | wc -l) -eq 0 ]]; then
    echo "Timed out waiting for crd: ${crd}"
    exit 1
  fi
done
