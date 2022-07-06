#!/bin/bash
#cis-master.sh

#total_fail=$(kube-bench master  --version 1.20 --check 1.2.7,1.2.8,1.2.9 --json | jq .Totals.total_fail)
total_fail=$(docker run --pid=host -v "/etc:/etc:ro" -v "/var:/var:ro" -v "$(which kubectl):/usr/local/mount-from-host/bin/kubectl" -v "~/.kube:/.kube" -e "KUBECONFIG=/.kube/config" -t "aquasec/kube-bench:latest"  run --version 1.20 --targets node --check 1.2.7,1.2.8,1.2.9 --json | jq .Totals.total_fail)
echo $total_fail

if [[ "$total_fail" -ne 0 ]];
        then
                echo "CIS Benchmark Failed MASTER while testing for 1.2.7, 1.2.8, 1.2.9"
                exit 1;
        else
                echo "CIS Benchmark Passed for MASTER - 1.2.7, 1.2.8, 1.2.9"
fi;