function detectionResults = detectFaultsCUSUM(faultResults)
%DETECTFAULTSCUSUM Detect persistent PV underperformance using one-sided CUSUM.
%
% The detector uses a normalized underperformance score:
%
%   z_t = (predicted_t - actual_faulty_t) / qhat_t
%
% Positive values indicate that measured power is below prediction.
% A one-sided CUSUM accumulates persistent negative PV deviations.
%
% The first 30% of the monitoring stream is treated as healthy baseline
% data for detector calibration. In a real deployment, this should be
% replaced by a separate verified healthy calibration period.
%
% Input
% -----
% faultResults : Output from injectInverterFault.m or injectSoilingFault.m
%
% Output
% ------
% detectionResults : Input table with scores, CUSUM statistic, alarm events,
%                    and evaluation metadata.

    disp("Running one-sided CUSUM fault detector...");

    %% Required variables

    requiredVariables = { ...
        'target_timestamp', ...
        'actual_faulty', ...
        'predicted', ...
        'lower', ...
        'upper', ...
        'qhat', ...
        'isFault'};

    missingVariables = setdiff( ...
        requiredVariables, ...
        faultResults.Properties.VariableNames);

    if ~isempty(missingVariables)
        error( ...
            "faultResults is missing variables: %s", ...
            strjoin(missingVariables, ", "));
    end

    detectionResults = sortrows( ...
        faultResults, ...
        'target_timestamp');

    n = height(detectionResults);

    if n < 100
        error("The monitoring stream is too short for CUSUM calibration.");
    end

    %% Detector settings

    minimumPredictedPower = 500; % Ignore nighttime/very-low generation
    maximumGapMinutes = 30;

    % Initial portion assumed to be healthy
    baselineFraction = 0.30;
    baselineEnd = floor(baselineFraction * n);

    % Small positive drift suppresses accumulation from ordinary noise
    referenceValue = 0.05;

    % Prevent zero or extremely small normalization scales
    minimumScale = 100; % W

    %% Active-operation mask

    activeOperation = ...
        detectionResults.predicted >= minimumPredictedPower;

    %% Normalize underperformance

    scale = max( ...
        detectionResults.qhat, ...
        minimumScale);

   % Severity of lower-bound violation.
% A value of zero means the measured power is still inside the
% conformal prediction interval.
normalizedUnderperformance = ...
    (detectionResults.lower - ...
     detectionResults.actual_faulty) ./ scale;

lowerTailScore = max( ...
    normalizedUnderperformance, ...
    0);

    % Ignore inactive periods
    lowerTailScore(~activeOperation) = 0;

    %% Calibrate threshold from initial healthy baseline

    baselineCUSUM = zeros(baselineEnd,1);
    currentValue = 0;

    for i = 1:baselineEnd

        if i > 1
            gapMinutes = minutes( ...
                detectionResults.target_timestamp(i) - ...
                detectionResults.target_timestamp(i-1));

            if gapMinutes > maximumGapMinutes
                currentValue = 0;
            end
        end

        if ~activeOperation(i)
            currentValue = 0;
        else
            currentValue = max( ...
                0, ...
                currentValue + ...
                lowerTailScore(i) - ...
                referenceValue);
        end

        baselineCUSUM(i) = currentValue;
    end

    % Threshold is above normal baseline excursions.
    % A minimum of 5 avoids an unrealistically sensitive detector.
    baselineThreshold = prctile(baselineCUSUM, 99.9);

    decisionThreshold = max( ...
        5, ...
        baselineThreshold + 2);

    %% Run CUSUM on the complete monitoring stream

   %% Locate the injected fault start

faultStartIndex = find( ...
    detectionResults.isFault, ...
    1, ...
    'first');

if isempty(faultStartIndex)
    error("No ground-truth fault label was found.");
end

faultStartTime = ...
    detectionResults.target_timestamp(faultStartIndex);

%% Run CUSUM on the complete monitoring stream
%
% False positives are evaluated before the known injected fault.
% The statistic is reset at fault injection for controlled delay
% evaluation, preventing pre-fault forecasting errors from determining
% the measured post-fault detection delay.

cusumStatistic = zeros(n,1);
alarmEvent = false(n,1);

currentValue = 0;
alarmActive = false;

resetThreshold = 0.25 * decisionThreshold;

for i = 1:n

    %% Reset exactly when the synthetic fault begins

    if i == faultStartIndex
        currentValue = 0;
        alarmActive = false;
    end

    %% Reset across missing periods

    if i > 1
        gapMinutes = minutes( ...
            detectionResults.target_timestamp(i) - ...
            detectionResults.target_timestamp(i-1));

        if gapMinutes > maximumGapMinutes
            currentValue = 0;
            alarmActive = false;
        end
    end

    %% Reset during inactive PV operation

    if ~activeOperation(i)

        currentValue = 0;
        alarmActive = false;

    else

        currentValue = max( ...
            0, ...
            currentValue + ...
            lowerTailScore(i) - ...
            referenceValue);

        if currentValue >= decisionThreshold && ~alarmActive
            alarmEvent(i) = true;
            alarmActive = true;
        end

        if alarmActive && currentValue <= resetThreshold
            alarmActive = false;
        end
    end

    cusumStatistic(i) = currentValue;
end

  %% Evaluate detection

falsePositiveMask = ...
    alarmEvent & ...
    ~detectionResults.isFault;

falsePositiveCount = sum(falsePositiveMask);

detectionIndex = find( ...
    alarmEvent & detectionResults.isFault, ...
    1, ...
    'first');

if isempty(detectionIndex)

    detectionTime = NaT;
    detectionDelayHours = NaN;
    detectedAfterFault = false;

    warning("CUSUM did not detect the injected fault.");

else

    detectionTime = ...
        detectionResults.target_timestamp(detectionIndex);

    detectionDelayHours = hours( ...
        detectionTime - faultStartTime);

    detectedAfterFault = true;

end

    %% Add detector variables

    detectionResults.active_operation = activeOperation;
    detectionResults.normalized_underperformance = ...
        normalizedUnderperformance;
    detectionResults.lower_tail_score = lowerTailScore;
    detectionResults.cusum_statistic = cusumStatistic;
    detectionResults.alarm_event = alarmEvent;
    detectionResults.false_positive = falsePositiveMask;

    %% Print results

    fprintf("Baseline samples = %d\n", baselineEnd);
    fprintf("CUSUM reference value = %.2f\n", referenceValue);
    fprintf("CUSUM decision threshold = %.2f\n", decisionThreshold);
    fprintf("Fault start time = %s\n", string(faultStartTime));

    if detectedAfterFault
        fprintf("Detection time = %s\n", string(detectionTime));
        fprintf("Detection delay = %.2f hours\n", ...
            detectionDelayHours);
    else
        fprintf("Detection delay = not detected\n");
    end

    fprintf("False-positive alarm events = %d\n", ...
        falsePositiveCount);

    fprintf("Total alarm events = %d\n", ...
        sum(alarmEvent));

    %% Plot around fault period

    plotStartTime = faultStartTime - days(7);
    plotEndTime = faultStartTime + days(30);

    plotMask = ...
        detectionResults.target_timestamp >= plotStartTime & ...
        detectionResults.target_timestamp <= plotEndTime;

    plotResults = detectionResults(plotMask,:);

    figure;
    hold on;

    plot( ...
        plotResults.target_timestamp, ...
        plotResults.actual_faulty, ...
        'b', ...
        'LineWidth', 1.2);

    plot( ...
        plotResults.target_timestamp, ...
        plotResults.predicted, ...
        'r', ...
        'LineWidth', 1.2);

    plot( ...
        plotResults.target_timestamp, ...
        plotResults.lower, ...
        'k--', ...
        'LineWidth', 1.0);

    xline( ...
        faultStartTime, ...
        'm--', ...
        'Fault start', ...
        'LineWidth', 1.5);

    if detectedAfterFault
        xline( ...
            detectionTime, ...
            'g--', ...
            'Detection', ...
            'LineWidth', 1.5);
    end

    alarmPlotMask = plotResults.alarm_event;

    scatter( ...
        plotResults.target_timestamp(alarmPlotMask), ...
        plotResults.actual_faulty(alarmPlotMask), ...
        45, ...
        'ro', ...
        'LineWidth', 1.5);

    xlabel('Time');
    ylabel('PV Power (W)');
    title('CUSUM-Based PV Fault Detection');

    legend( ...
        'Faulty measured power', ...
        'Forecast', ...
        'Conformal lower bound', ...
        'Fault start', ...
        'Detection', ...
        'CUSUM alarm event', ...
        'Location', ...
        'best');

    grid on;
    hold off;

    %% Plot CUSUM statistic

    figure;
    hold on;

    plot( ...
        detectionResults.target_timestamp, ...
        detectionResults.cusum_statistic, ...
        'LineWidth', ...
        1.2);

    yline( ...
        decisionThreshold, ...
        'r--', ...
        'Decision threshold', ...
        'LineWidth', ...
        1.5);

    xline( ...
        faultStartTime, ...
        'm--', ...
        'Fault start', ...
        'LineWidth', ...
        1.5);

    if detectedAfterFault
        xline( ...
            detectionTime, ...
            'g--', ...
            'Detection', ...
            'LineWidth', ...
            1.5);
    end

    xlabel('Time');
    ylabel('CUSUM statistic');
    title('One-Sided CUSUM Monitoring Statistic');
    grid on;
    hold off;

    %% Store metadata

    detectionResults.Properties.UserData = struct( ...
        'Detector', 'One-sided CUSUM', ...
        'BaselineFraction', baselineFraction, ...
        'BaselineEndIndex', baselineEnd, ...
        'MinimumPredictedPower', minimumPredictedPower, ...
        'MaximumGapMinutes', maximumGapMinutes, ...
        'ReferenceValue', referenceValue, ...
        'DecisionThreshold', decisionThreshold, ...
        'ResetThreshold', resetThreshold, ...
        'FaultStartIndex', faultStartIndex, ...
        'FaultStartTime', faultStartTime, ...
        'DetectionIndex', detectionIndex, ...
        'DetectionTime', detectionTime, ...
        'DetectionDelayHours', detectionDelayHours, ...
        'DetectedAfterFault', detectedAfterFault, ...
        'FalsePositiveCount', falsePositiveCount, ...
        'TotalAlarmEvents', sum(alarmEvent));

    disp("CUSUM fault detection complete.");

end
