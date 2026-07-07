clear;
clc;
close all;

addpath('src');

[pv, weather, forecast] = loadData();

exploreData(pv, weather, forecast);

[pv, weather, forecast] = cleanData(pv, weather, forecast);

forecastDecoded = decodeForecast(forecast);
[pv15, weather15] = resampleData(pv, weather);
dataset = mergeData(pv15, weather15);
dataset = featureEngineering(dataset);
[trainData, calibData, testData] = splitData(dataset);
[model, featureNames] = trainForecastModel(trainData);
yPred = evaluateForecastModel(model, testData, featureNames);
analyzeResiduals(testData, yPred);
[qhat, testResults] = conformalPrediction(model, calibData, testData, featureNames);
faultyResults = injectInverterFault(testResults);
detectionResultsInverter = detectFaults( ...
    faultyResults, ...
    'Inverter Underperformance Detection');

soilingResults = injectSoilingFault(testResults);
detectionResultsSoiling = detectFaults( ...
    soilingResults, ...
    'Soiling Fault Detection');
sweepInverter = kSensitivitySweep(faultyResults, 'Inverter Underperformance');

sweepSoiling = kSensitivitySweep(soilingResults, 'Soiling');

disp("Step 1 complete.");