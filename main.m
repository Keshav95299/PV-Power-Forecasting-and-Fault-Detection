clear;
clc;
close all;

addpath("src");

disp("Starting PV monitoring pipeline...");

%% 1. Load raw datasets

[pv, weather, forecast] = loadData();

%% 2. Clean and sort datasets

[pv, weather, forecast] = cleanData( ...
    pv, ...
    weather, ...
    forecast);

%% 3. Resample PV and measured weather data

[pv15, weather15] = resampleData( ...
    pv, ...
    weather);

% weather15 is retained for exploratory analysis.
% The forecasting model uses archived weather forecasts.

%% 4. Decode archived weather forecasts

forecastDecoded = decodeForecast( ...
    forecast);

%% 5. Build the true 24-hour-ahead forecasting dataset

dayAheadDataset = buildDayAheadDataset( ...
    forecastDecoded, ...
    pv15);

%% 6. Split chronologically by forecast origin

[trainData, calibData, testData] = splitData( ...
    dayAheadDataset);

%% 7. Train the point forecasting model

[model, featureNames] = trainForecastModel( ...
    trainData);

%% 8. Evaluate point forecast performance

pointForecastResults = evaluateForecastModel( ...
    model, ...
    testData, ...
    featureNames);

%% 9. Apply lead-time-conditioned split conformal prediction

[qhat, testResults] = conformalPrediction( ...
    model, ...
    calibData, ...
    testData, ...
    featureNames);

%% 10. Construct one chronological monitoring stream

monitoringResults = prepareMonitoringStream( ...
    testResults);

%% 11. Inject inverter underperformance

inverterResults = injectInverterFault( ...
    monitoringResults);

%% 12. Inject gradual soiling

soilingResults = injectSoilingFault( ...
    monitoringResults);

%% 13. Required sliding-window fault detection

k = 4;

slidingInverter = detectFaults( ...
    inverterResults, ...
    k, ...
    "Inverter Underperformance", ...
    fullfile( ...
        "figures", ...
        "inverter_fault_sliding_window.png"));

slidingSoiling = detectFaults( ...
    soilingResults, ...
    k, ...
    "Gradual Soiling", ...
    fullfile( ...
        "figures", ...
        "soiling_fault_sliding_window.png"));

%% 14. Optional CUSUM comparison
%
% Uncomment these lines only if you want to include CUSUM as an additional
% comparison. Sliding-window detection remains the required main method.

% cusumInverter = detectFaultsCUSUM( ...
%     inverterResults);
%
% cusumSoiling = detectFaultsCUSUM( ...
%     soilingResults);

%% 15. Display point forecast metrics

disp(" ");
disp("========================================");
disp("POINT FORECAST RESULTS");
disp("========================================");

disp(pointForecastResults.Properties.UserData);

%% 16. Display conformal prediction metrics

disp(" ");
disp("========================================");
disp("CONFORMAL PREDICTION RESULTS");
disp("========================================");

disp(testResults.Properties.UserData);

fprintf("Global conformal qhat: %.2f W\n", qhat);

%% 17. Display inverter sliding-window results

disp(" ");
disp("========================================");
disp("SLIDING-WINDOW INVERTER RESULTS");
disp("========================================");

disp(slidingInverter.Properties.UserData);

%% 18. Display soiling sliding-window results

disp(" ");
disp("========================================");
disp("SLIDING-WINDOW SOILING RESULTS");
disp("========================================");

disp(slidingSoiling.Properties.UserData);

disp(" ");
disp("PV monitoring pipeline complete.");