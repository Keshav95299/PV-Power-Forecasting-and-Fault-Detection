function soilingResults = injectSoilingFault(monitoringResults)
%INJECTSOILINGFAULT Inject gradual PV degradation caused by soiling.
%
% The fault starts at the first active daytime sample after 40% of the
% monitoring period. Degradation increases according to elapsed calendar
% time, making the simulation robust to missing timestamps.

    disp("Injecting gradual soiling fault...");

    soilingResults = monitoringResults;
    n = height(soilingResults);

    %% Select a meaningful daytime fault start

    searchStart = max(1, round(0.40 * n));
    minimumActivePower = 4000; % W

    relativeIndex = find( ...
        soilingResults.actual(searchStart:end) >= minimumActivePower, ...
        1, ...
        'first');

    if isempty(relativeIndex)
        error("No suitable daytime sample found for soiling injection.");
    end

    faultStart = searchStart + relativeIndex - 1;

    %% Ground-truth labels

    soilingResults.isFault = false(n,1);
    soilingResults.isFault(faultStart:end) = true;

    soilingResults.actual_faulty = soilingResults.actual;

  %% Gradual calendar-time degradation

finalLoss = 0.20;             % Final 20% reduction
degradationDurationDays = 14; % Reach final loss after 14 days

elapsedHours = hours( ...
    soilingResults.target_timestamp(faultStart:end) - ...
    soilingResults.target_timestamp(faultStart));

degradationDurationHours = degradationDurationDays * 24;

% Progress increases from 0 to 1 and then remains at 1
degradationProgress = min( ...
    elapsedHours ./ degradationDurationHours, ...
    1);

degradationFactor = ...
    1 - finalLoss .* degradationProgress;

soilingResults.actual_faulty(faultStart:end) = ...
    soilingResults.actual(faultStart:end) .* degradationFactor;
    %% Store degradation factor

    soilingResults.degradation_factor = ones(n,1);
    soilingResults.degradation_factor(faultStart:end) = ...
        degradationFactor;

   soilingResults.Properties.UserData = struct( ...
    'FaultType', 'Gradual soiling', ...
    'FaultStartIndex', faultStart, ...
    'FaultStartTime', soilingResults.target_timestamp(faultStart), ...
    'FinalLoss', finalLoss, ...
    'DegradationDurationDays', degradationDurationDays);

    fprintf("Soiling starts at sample: %d\n", faultStart);
    fprintf("Soiling start time: %s\n", ...
        string(soilingResults.target_timestamp(faultStart)));
    fprintf("Final simulated power loss: %.0f %%\n", ...
        finalLoss*100);

end