#!/bin/bash
#cis-kubelet.sh

total_string=$(docker run --pid=host -v /etc:/etc:ro -v /var:/var:ro -v "$(which kubectl):/usr/local/mount-from-host/bin/kubectl" -v ~/.kube:/.kube -e KUBECONFIG=/.kube/config -t "aquasec/kube-bench:latest"  run --version 1.20 --targets node --check 4.2.1,4.2.2 --json)
total_fail=$(echo "$total_string" | jq ".Totals.total_fail")
echo "$total_fail"

if [[ "$total_fail" -ne 0 ]];
        then
                echo "CIS Benchmark Failed Kubelet while testing for 4.2.1, 4.2.2"
                exit 1;
        else
                echo "CIS Benchmark Passed Kubelet for 4.2.1, 4.2.2"
fi;
