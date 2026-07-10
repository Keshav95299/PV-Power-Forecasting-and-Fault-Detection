function [model, featureNames] = trainForecastModel(trainData)
%TRAINFORECASTMODEL Train the 24-hour-ahead PV forecasting model.
%
% The model uses weather forecasts, forecast lead time, and target-time
% cyclic variables to predict PV power for lead times from 15 minutes
% to 24 hours.

    disp("Training 24-hour-ahead forecasting model...");

    %% Target variable

    targetName = 'target_power';

    %% Predictor variables

    featureNames = { ...
        'forecast_irradiance', ...
        'forecast_temperature', ...
        'forecast_cloud_cover', ...
        'forecast_humidity', ...
        'lead_hours', ...
        'target_hour_sin', ...
        'target_hour_cos', ...
        'target_day_sin', ...
        'target_day_cos'};

    %% Check required variables

    requiredVariables = [featureNames, {targetName}];

    missingVariables = setdiff( ...
        requiredVariables, ...
        trainData.Properties.VariableNames);

    if ~isempty(missingVariables)
        error( ...
            "Training data is missing required variables: %s", ...
            strjoin(missingVariables, ", "));
    end

    
    %% Prepare model inputs

    XTrain = trainData(:, featureNames);
    yTrain = trainData.(targetName);

    %% Remove invalid rows if any remain

  validRows = ~ismissing(yTrain);

for i = 1:length(featureNames)
    validRows = validRows & ...
        ~ismissing(XTrain.(featureNames{i}));
end

fprintf("Training samples after daylight filtering: %d\n", sum(validRows));

    XTrain = XTrain(validRows, :);
    yTrain = yTrain(validRows);

    if isempty(yTrain)
        error("No valid training samples remain after filtering.");
    end

    %% Define regression tree template

treeTemplate = templateTree( ...
    'MinLeafSize',20,...
    'MaxNumSplits',100);

model = fitrensemble( ...
    XTrain,...
    yTrain,...
    'Method','LSBoost',...
    'Learners',treeTemplate,...
    'NumLearningCycles',300,...
    'LearnRate',0.05);
    %% Training information

    fprintf("Training samples used: %d\n", height(XTrain));
    fprintf("Number of predictors: %d\n", length(featureNames));

    disp("Predictor variables:");
    disp(featureNames');

    disp("24-hour-ahead forecasting model training complete.");

end