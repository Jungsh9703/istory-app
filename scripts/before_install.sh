#!/bin/bash
set -euo pipefail

# 애플리케이션 디렉토리 정리/생성
if [ -d /home/ec2-user/app ]; then
    rm -rf /home/ec2-user/app/*
else
    mkdir -p /home/ec2-user/app
fi
mkdir -p /home/ec2-user/app/logs

# Java 설치 확인 및 설치 (Amazon Linux 계열 가정)
if ! command -v java >/dev/null 2>&1; then
    echo "Java not found. Installing Amazon Corretto 17..."
    sudo yum clean all -y || true
    sudo yum install -y java-17-amazon-corretto-headless || sudo amazon-linux-extras install -y java-openjdk11 || true
    echo "Java installed: $(java -version 2>&1 | head -n1)"
else
    echo "Java already installed: $(java -version 2>&1 | head -n1)"
fi