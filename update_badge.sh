#!/bin/bash
sonar-scanner -Dsonar.projectKey=juice-shop -Dsonar.host.url=http://localhost:9000 -Dsonar.login=sqp_61a2aec4adabefbb2a2be2a06ca2eda4e00fc363
if [ $? -eq 0 ]; then
    BADGE="![SonarQube Analysis Passed](https://img.shields.io/badge/sonarqube-passed-brightgreen.svg)"
else
    BADGE="![SonarQube Analysis Failed](https://img.shields.io/badge/sonarqube-failed-red.svg)"
fi
echo -e "\n$BADGE" >> README.md
