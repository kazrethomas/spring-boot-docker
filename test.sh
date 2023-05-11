#!/bin/bash
helm template  kazre ./kazre-helm/ --set image.tag=$1 > k8.yaml