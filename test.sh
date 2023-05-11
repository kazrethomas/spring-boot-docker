#!/bin/bash
helm template  jason ./kazre-helm/ --set image.tag=$1 > k8.yaml