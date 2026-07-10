function dataset = buildDayAheadDataset(forecastDecoded, pv15)
%BUILDDAYAHEADDATASET Build a 24-hour-ahead PV forecasting dataset.
%
% Each weather forecast vector is assumed to contain hourly forecasts:
%     element 1  = lead time 0 hours
%     element 2  = lead time 1 hour
%     ...
%     element 73 = lead time 72 hours
%
% The hourly weather forecasts are interpolated to 15-minute resolution.
% The function creates 96 target points:
%     +15 minutes, +30 minutes, ..., +24 hours
%
% Inputs
% ------
% forecastDecoded : Output table from decodeForecast.m
% pv15             : PV table at 15-minute resolution. It must contain:
%                    - timestamp
%                    - total_power
%
% Output
% ------
% dataset : Flattened table containing forecast weather variables and
%           corresponding measured PV power for each target timestamp.

    disp("Building 24-hour-ahead forecasting dataset...");

    %% Configuration

    stepsPerDay = 96;
    minutesPerStep = 15;

    % The required 96 target lead times:
    % 0.25, 0.50, ..., 24.00 hours
    targetLeadHours = (1:stepsPerDay)' * minutesPerStep / 60;

    %% Validate input tables

    requiredForecastVariables = { ...
        'forecastTime', ...
        'startTime', ...
        'irradiance', ...
        'temperature', ...
        'cloudCover', ...
        'humidity'};

    requiredPVVariables = {'timestamp', 'total_power'};

    missingForecastVariables = setdiff( ...
        requiredForecastVariables, ...
        forecastDecoded.Properties.VariableNames);

    if ~isempty(missingForecastVariables)
        error( ...
            "forecastDecoded is missing variables: %s", ...
            strjoin(missingForecastVariables, ", "));
    end

    missingPVVariables = setdiff( ...
        requiredPVVariables, ...
        pv15.Properties.VariableNames);

    if ~isempty(missingPVVariables)
        error( ...
            "pv15 is missing variables: %s", ...
            strjoin(missingPVVariables, ", "));
    end

    %% Clean and sort PV data

    pv15 = sortrows(pv15, 'timestamp');

    % Prevent ambiguous matching if duplicate PV timestamps exist
    [~, uniquePVIndices] = unique(pv15.timestamp, 'stable');
    pv15 = pv15(uniquePVIndices, :);

    %% Remove duplicated forecast origins if present

    forecastDecoded = sortrows( ...
        forecastDecoded, ...
        {'startTime', 'forecastTime'});

    % If several records have the same forecast start time,
    % retain the last available record.
    [~, uniqueForecastIndices] = unique( ...
        forecastDecoded.startTime, ...
        'last');

    forecastDecoded = forecastDecoded( ...
        sort(uniqueForecastIndices), :);

    nForecasts = height(forecastDecoded);
    maximumRows = nForecasts * stepsPerDay;

    %% Preallocate output arrays

    forecastOriginTime = NaT(maximumRows, 1);
    forecastRecordTime = NaT(maximumRows, 1);
    targetTimestamp = NaT(maximumRows, 1);

    leadStep = NaN(maximumRows, 1);
    leadHours = NaN(maximumRows, 1);

    forecastIrradiance = NaN(maximumRows, 1);
    forecastTemperature = NaN(maximumRows, 1);
    forecastCloudCover = NaN(maximumRows, 1);
    forecastHumidity = NaN(maximumRows, 1);

    actualPower = NaN(maximumRows, 1);

    rowCounter = 0;

    %% Process every forecast vector

    for i = 1:nForecasts

        irradianceVector = forecastDecoded.irradiance{i}(:);
        temperatureVector = forecastDecoded.temperature{i}(:);
        cloudVector = forecastDecoded.cloudCover{i}(:);
        humidityVector = forecastDecoded.humidity{i}(:);

        vectorLengths = [ ...
            length(irradianceVector), ...
            length(temperatureVector), ...
            length(cloudVector), ...
            length(humidityVector)];

        if any(vectorLengths ~= vectorLengths(1))
            warning( ...
                "Skipping forecast row %d because vector lengths differ.", ...
                i);
            continue;
        end

        numberOfForecastHours = vectorLengths(1);

        if numberOfForecastHours < 25
            warning( ...
                "Skipping forecast row %d: fewer than 25 hourly points.", ...
                i);
            continue;
        end

        % Hourly source positions:
        % index 1 = 0 h, index 2 = 1 h, etc.
        sourceLeadHours = (0:numberOfForecastHours-1)';

        %% Interpolate hourly forecasts to 15-minute resolution

        irradiance15 = interp1( ...
            sourceLeadHours, ...
            irradianceVector, ...
            targetLeadHours, ...
            'linear');

        temperature15 = interp1( ...
            sourceLeadHours, ...
            temperatureVector, ...
            targetLeadHours, ...
            'linear');

        cloud15 = interp1( ...
            sourceLeadHours, ...
            cloudVector, ...
            targetLeadHours, ...
            'linear');

        humidity15 = interp1( ...
            sourceLeadHours, ...
            humidityVector, ...
            targetLeadHours, ...
            'linear');

        % Irradiance cannot physically be negative
        irradiance15 = max(irradiance15, 0);

        %% Construct valid target timestamps

        originTime = forecastDecoded.startTime(i);

        currentTargetTimes = originTime + ...
            minutes((1:stepsPerDay)' * minutesPerStep);

        %% Match target timestamps to measured PV power

        [isAvailable, pvLocations] = ismember( ...
            currentTargetTimes, ...
            pv15.timestamp);

        if ~any(isAvailable)
            continue;
        end

        validPositions = find(isAvailable);
        numberOfValidRows = length(validPositions);

        outputIndices = ...
            rowCounter + (1:numberOfValidRows);

        forecastOriginTime(outputIndices) = originTime;
        forecastRecordTime(outputIndices) = ...
            forecastDecoded.forecastTime(i);

        targetTimestamp(outputIndices) = ...
            currentTargetTimes(validPositions);

        leadStep(outputIndices) = validPositions;
        leadHours(outputIndices) = ...
            targetLeadHours(validPositions);

        forecastIrradiance(outputIndices) = ...
            irradiance15(validPositions);

        forecastTemperature(outputIndices) = ...
            temperature15(validPositions);

        forecastCloudCover(outputIndices) = ...
            cloud15(validPositions);

        forecastHumidity(outputIndices) = ...
            humidity15(validPositions);

        actualPower(outputIndices) = ...
            pv15.total_power(pvLocations(validPositions));

        rowCounter = rowCounter + numberOfValidRows;
    end

    %% Trim unused preallocated rows

    forecastOriginTime = forecastOriginTime(1:rowCounter);
    forecastRecordTime = forecastRecordTime(1:rowCounter);
    targetTimestamp = targetTimestamp(1:rowCounter);

    leadStep = leadStep(1:rowCounter);
    leadHours = leadHours(1:rowCounter);

    forecastIrradiance = forecastIrradiance(1:rowCounter);
    forecastTemperature = forecastTemperature(1:rowCounter);
    forecastCloudCover = forecastCloudCover(1:rowCounter);
    forecastHumidity = forecastHumidity(1:rowCounter);

    actualPower = actualPower(1:rowCounter);

    %% Create target-time cyclic variables

    targetHour = hour(targetTimestamp) + ...
        minute(targetTimestamp) / 60;

    targetDay = day(targetTimestamp, 'dayofyear');

    targetHourSin = sin(2*pi*targetHour/24);
    targetHourCos = cos(2*pi*targetHour/24);

    targetDaySin = sin(2*pi*targetDay/365);
    targetDayCos = cos(2*pi*targetDay/365);

    %% Construct output table

    dataset = table( ...
        forecastOriginTime, ...
        forecastRecordTime, ...
        targetTimestamp, ...
        leadStep, ...
        leadHours, ...
        forecastIrradiance, ...
        forecastTemperature, ...
        forecastCloudCover, ...
        forecastHumidity, ...
        targetHourSin, ...
        targetHourCos, ...
        targetDaySin, ...
        targetDayCos, ...
        actualPower, ...
        'VariableNames', { ...
            'forecast_origin_time', ...
            'forecast_record_time', ...
            'target_timestamp', ...
            'lead_step', ...
            'lead_hours', ...
            'forecast_irradiance', ...
            'forecast_temperature', ...
            'forecast_cloud_cover', ...
            'forecast_humidity', ...
            'target_hour_sin', ...
            'target_hour_cos', ...
            'target_day_sin', ...
            'target_day_cos', ...
            'target_power'});

    %% Remove invalid rows and sort

    dataset = rmmissing(dataset);

    dataset = sortrows( ...
        dataset, ...
        {'forecast_origin_time', 'lead_step'});

    fprintf("Forecast origins processed: %d\n", nForecasts);
    fprintf("Day-ahead dataset rows: %d\n", height(dataset));
    fprintf("Forecast points per complete origin: %d\n", stepsPerDay);
    fprintf("Maximum lead time: %.2f hours\n", max(dataset.lead_hours));

    disp("Day-ahead dataset variables:");
    disp(dataset.Properties.VariableNames');

end