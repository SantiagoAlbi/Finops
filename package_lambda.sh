#!/bin/bash

echo "📦 Empaquetando Lambdas..."

# Lambda 1: Cost Anomaly Detector
echo "  → Cost Anomaly Detector"
zip -q cost_anomaly_detector.zip lambda_cost_anomaly.py

# Lambda 2: Unused Resources Scanner
echo "  → Unused Resources Scanner"
zip -q unused_resources_scanner.zip lambda_unused_resources.py

echo "✅ Ambas Lambdas empaquetadas"
ls -lh *.zip
