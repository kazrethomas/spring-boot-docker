#!/bin/bash
helm template  kazre ./kazre-spring-chart/ --set image.tag=$1 > k8.yaml