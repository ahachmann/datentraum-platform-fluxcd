#!/bin/bash

kubectl -n opencost create configmap pricing-configs --from-literal=Pricing.json="$(cat <<EOF
{
  "nodes": [
    {"name": "k3s-agent-small-jxa", "nodeCostPerHour": 0.00537},
    {"name": "k3s-agent-small-nhj", "nodeCostPerHour": 0.00537},
    {"name": "k3s-agent-small-nll", "nodeCostPerHour": 0.00537},
    {"name": "k3s-agent-small-qmf", "nodeCostPerHour": 0.00537},
    {"name": "k3s-control-plane-fsn1-meq", "nodeCostPerHour": 0.00537}
  ]
}
EOF
)"