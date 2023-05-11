#!/bin/bash
helm template  jason ./jason-spring-chart/ --set image.tag=$1 > k8.yaml