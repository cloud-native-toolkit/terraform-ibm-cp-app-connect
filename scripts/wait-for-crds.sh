#!/usr/bin/env bash

CRD_LIST="designerauthoring.appconnect.ibm.com,integrationserver.appconnect.ibm.com,integrationserver.appconnect.ibm.com,dashboard.appconnect.ibm.com"

IFS=',' read -ra CRDS <<< "$CRD_LIST"
for crd in "${CRDS[@]}"; do
  retrycount=10
  while ! k get "${crd}" -A 1 > /dev/null 2> /dev/null && [[ "${retrycount}" -gt 0 ]]; do
    echo "Waiting for crd: ${crd}"
    sleep 30
  done

  if ! k get "${crd}" -A 1 > /dev/null 2> /dev/null; then
    echo "Timed out waiting for crd: ${crd}"
    exit 1
  fi
done
