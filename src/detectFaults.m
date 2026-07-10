function detectionResults = detectFaults( ...
    faultResults, k, faultName, outputFile)
%DETECTFAULTS Sliding-window lower-bound fault detector.
%
% A violation occurs when the faulty measured PV power falls below the
% conformal lower prediction bound during active daytime operation.
%
% An alarm is generated when k consecutive violations occur.
% For 15-minute data, k = 4 represents one hour of persistent abnormal
% operation.
%
% Inputs
% ------
% faultResults : Output from injectInverterFault.m or injectSoilingFault.m
% k            : Number of consecutive violations required
% faultName    : Text used in the figure title
% outputFile   : Optional path for saving the generated figure
%
% Output
% -------
% detectionResults : Table containing detector outputs and metrics

    %% Default arguments

    if nargin < 2 || isempty(k)
        k = 4;
    end

    if nargin < 3 || strlength(string(faultName)) == 0
        faultName = "PV Fault";
    end

    if nargin < 4
        outputFile = "";
    end

    faultName = string(faultName);
    outputFile = string(outputFile);

    disp("Running sliding-window fault detector...");
    fprintf("Fault scenario: %s\n", faultName);

    %% Validate input variables

    requiredVariables = { ...
        'target_timestamp', ...
        'actual_faulty', ...
        'predicted', ...
        'lower', ...
        'upper', ...
        'isFault'};

    missingVariables = setdiff( ...
        requiredVariables, ...
        faultResults.Properties.VariableNames);

    if ~isempty(missingVariables)
        error( ...
            "faultResults is missing required variables: %s", ...
            strjoin(missingVariables, ", "));
    end

    if k < 1 || mod(k,1) ~= 0
        error("k must be a positive integer.");
    end

    %% Sort monitoring results chronologically

    detectionResults = sortrows( ...
        faultResults, ...
        'target_timestamp');

    n = height(detectionResults);

    if n == 0
        error("faultResults is empty.");
    end

    %% Detector configuration

    % This is used as a daytime-operation proxy because solar elevation
    % is not present in the final monitoring table.
    minimumPredictedPower = 500;  % W

    % A larger time gap breaks the consecutive sequence.
    maximumGapMinutes = 30;

    %% Identify active daytime operation

    activeOperation = ...
        detectionResults.predicted >= minimumPredictedPower;

    %% Detect lower conformal-bound violations

    violation = ...
        activeOperation & ...
        detectionResults.actual_faulty < detectionResults.lower;

    %% Apply k-consecutive sliding-window rule

    consecutiveCount = zeros(n,1);
    alarmEvent = false(n,1);

    currentCount = 0;

    for i = 1:n

        % Reset the sequence across missing-data gaps.
        if i > 1

            gapMinutes = minutes( ...
                detectionResults.target_timestamp(i) - ...
                detectionResults.target_timestamp(i-1));

            if gapMinutes > maximumGapMinutes
                currentCount = 0;
            end
        end

        % Continue counting only during active operation and while the
        % measurement remains below the lower conformal bound.
        if violation(i)

            currentCount = currentCount + 1;

        else

            currentCount = 0;
        end

        consecutiveCount(i) = currentCount;

        % Generate one alarm when the run first reaches k samples.
        if currentCount == k
            alarmEvent(i) = true;
        end
    end

    %% Locate the injected fault

    faultStartIndex = find( ...
        detectionResults.isFault, ...
        1, ...
        'first');

    if isempty(faultStartIndex)
        error("No ground-truth fault label was found.");
    end

    faultStartTime = ...
        detectionResults.target_timestamp(faultStartIndex);

    %% Locate the first post-fault alarm

    detectionIndex = find( ...
        alarmEvent & detectionResults.isFault, ...
        1, ...
        'first');

    if isempty(detectionIndex)

        detectionTime = NaT;
        detectionDelaySteps = NaN;
        detectionDelaySamples = NaN;
        detectionDelayHours = NaN;
        detectedAfterFault = false;

        warning("%s was not detected.", faultName);

    else

        detectionTime = ...
            detectionResults.target_timestamp(detectionIndex);

        % Number of elapsed 15-minute intervals.
        detectionDelaySteps = ...
            detectionIndex - faultStartIndex;

        % Number of samples from the fault-start sample through alarm.
        detectionDelaySamples = ...
            detectionIndex - faultStartIndex + 1;

        % Actual elapsed time, robust to timestamp gaps.
        detectionDelayHours = hours( ...
            detectionTime - faultStartTime);

        detectedAfterFault = true;
    end

    %% Calculate false-positive rate on clean daytime samples

    cleanDaytimeMask = ...
        ~detectionResults.isFault & ...
        activeOperation;

    falsePositiveMask = ...
        alarmEvent & ...
        cleanDaytimeMask;

    falsePositiveCount = sum(falsePositiveMask);
    cleanDaytimeSamples = sum(cleanDaytimeMask);

    if cleanDaytimeSamples > 0

        falsePositiveRate = ...
            100 * falsePositiveCount / cleanDaytimeSamples;

    else

        falsePositiveRate = NaN;
    end

    %% Add detector results to table

    detectionResults.active_operation = activeOperation;
    detectionResults.violation = violation;
    detectionResults.consecutive_count = consecutiveCount;
    detectionResults.alarm_event = alarmEvent;
    detectionResults.detected = alarmEvent;
    detectionResults.false_positive = falsePositiveMask;

    %% Print summary

    fprintf("\n");
    fprintf("Sliding-window detector results\n");
    fprintf("----------------------------------------\n");
    fprintf("Fault scenario: %s\n", faultName);
    fprintf("Sliding-window parameter k = %d\n", k);
    fprintf("Persistence represented by k = %.2f hours\n", ...
        k * 0.25);
    fprintf("Fault start time = %s\n", string(faultStartTime));

    if detectedAfterFault

        fprintf("Detection time = %s\n", string(detectionTime));
        fprintf("Elapsed detection steps = %.0f\n", ...
            detectionDelaySteps);
        fprintf("Samples from fault start to alarm = %.0f\n", ...
            detectionDelaySamples);
        fprintf("Detection delay = %.2f hours\n", ...
            detectionDelayHours);

    else

        fprintf("Detection result = not detected\n");
    end

    fprintf("Clean daytime samples = %d\n", ...
        cleanDaytimeSamples);

    fprintf("False-positive alarms = %d\n", ...
        falsePositiveCount);

    fprintf("False-positive rate = %.4f %%\n", ...
        falsePositiveRate);

    fprintf("Total lower-bound violations = %d\n", ...
        sum(violation));

    fprintf("Total alarm events = %d\n", ...
        sum(alarmEvent));

    %% Plot around the injected fault

    plotStartTime = faultStartTime - days(2);
    plotEndTime = faultStartTime + days(10);

    plotMask = ...
        detectionResults.target_timestamp >= plotStartTime & ...
        detectionResults.target_timestamp <= plotEndTime;

    plotResults = detectionResults(plotMask,:);

    figureHandle = figure( ...
        'Name', ...
        sprintf('%s Sliding-Window Detection', faultName), ...
        'NumberTitle', ...
        'off');

    hold on;

    plot( ...
        plotResults.target_timestamp, ...
        plotResults.actual_faulty, ...
        'b', ...
        'LineWidth', 1.4);

    plot( ...
        plotResults.target_timestamp, ...
        plotResults.predicted, ...
        'r', ...
        'LineWidth', 1.2);

    plot( ...
        plotResults.target_timestamp, ...
        plotResults.lower, ...
        'k--', ...
        'LineWidth', 1.1);

    faultLine = xline( ...
        faultStartTime, ...
        'm--', ...
        'Fault start', ...
        'LineWidth', 1.5);

    faultLine.LabelVerticalAlignment = 'middle';

    if detectedAfterFault

        detectionLine = xline( ...
            detectionTime, ...
            'g--', ...
            'Detection', ...
            'LineWidth', 1.5);

        detectionLine.LabelVerticalAlignment = 'bottom';
    end

    alarmMask = plotResults.alarm_event;

    scatter( ...
        plotResults.target_timestamp(alarmMask), ...
        plotResults.actual_faulty(alarmMask), ...
        45, ...
        'ro', ...
        'LineWidth', 1.4);

    xlabel('Time');
    ylabel('PV Power (W)');

    title(sprintf( ...
        '%s Detection Using Sliding Window, k = %d', ...
        faultName, ...
        k));

    if detectedAfterFault

        legend( ...
            'Faulty measured power', ...
            'Forecast', ...
            'Conformal lower bound', ...
            'Fault start', ...
            'Detection', ...
            'Alarm event', ...
            'Location', ...
            'best');

    else

        legend( ...
            'Faulty measured power', ...
            'Forecast', ...
            'Conformal lower bound', ...
            'Fault start', ...
            'Alarm event', ...
            'Location', ...
            'best');
    end

    grid on;
    hold off;

    %% Save the figure when a filename is supplied

    if strlength(outputFile) > 0

        outputFolder = fileparts(outputFile);

        if strlength(outputFolder) > 0 && ~isfolder(outputFolder)
            mkdir(outputFolder);
        end

        exportgraphics( ...
            figureHandle, ...
            outputFile, ...
            'Resolution', ...
            300);

        fprintf("Figure saved to: %s\n", outputFile);
    end

    %% Store summary metadata

    detectionResults.Properties.UserData = struct( ...
        'Detector', 'Sliding-window lower-bound detector', ...
        'FaultName', faultName, ...
        'K', k, ...
        'PersistenceHours', k * 0.25, ...
        'MinimumPredictedPower', minimumPredictedPower, ...
        'MaximumGapMinutes', maximumGapMinutes, ...
        'FaultStartIndex', faultStartIndex, ...
        'FaultStartTime', faultStartTime, ...
        'DetectionIndex', detectionIndex, ...
        'DetectionTime', detectionTime, ...
        'DetectionDelaySteps', detectionDelaySteps, ...
        'DetectionDelaySamples', detectionDelaySamples, ...
        'DetectionDelayHours', detectionDelayHours, ...
        'DetectedAfterFault', detectedAfterFault, ...
        'CleanDaytimeSamples', cleanDaytimeSamples, ...
        'FalsePositiveCount', falsePositiveCount, ...
        'FalsePositiveRate', falsePositiveRate, ...
        'TotalViolations', sum(violation), ...
        'TotalAlarmEvents', sum(alarmEvent), ...
        'OutputFile', outputFile);

    disp("Sliding-window fault detection complete.");

end