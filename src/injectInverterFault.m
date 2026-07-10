function faultyResults = injectInverterFault(monitoringResults)
%INJECTINVERTERFAULT Inject a sudden 10% PV underperformance fault.
%
% The fault starts at the first daytime sample after 40% of the
% monitoring period where measured PV power exceeds 1000 W.

    disp("Injecting inverter underperformance fault...");

    faultyResults = monitoringResults;
    n = height(faultyResults);

    %% Select a meaningful daytime fault start

    searchStart = max(1, round(0.40 * n));
    minimumActivePower = 4000; % W

    relativeIndex = find( ...
        faultyResults.actual(searchStart:end) >= minimumActivePower, ...
        1, ...
        'first');

    if isempty(relativeIndex)
        error("No suitable daytime sample found for inverter fault injection.");
    end

    faultStart = searchStart + relativeIndex - 1;

    %% Inject sudden inverter underperformance

    faultFactor = 0.80; % 10% reduction

    faultyResults.isFault = false(n,1);
    faultyResults.isFault(faultStart:end) = true;

    faultyResults.actual_faulty = faultyResults.actual;

    faultyResults.actual_faulty(faultStart:end) = ...
        faultyResults.actual(faultStart:end) .* faultFactor;

    faultyResults.residual_faulty = ...
        faultyResults.actual_faulty - faultyResults.predicted;

    %% Store fault information

    faultyResults.Properties.UserData = struct( ...
        'FaultType', 'Inverter underperformance', ...
        'FaultStartIndex', faultStart, ...
        'FaultStartTime', faultyResults.target_timestamp(faultStart), ...
        'FaultFactor', faultFactor);

    fprintf("Fault starts at sample: %d\n", faultStart);
    fprintf("Fault start time: %s\n", ...
        string(faultyResults.target_timestamp(faultStart)));
    fprintf("Power reduction: %.0f %%\n", ...
        (1-faultFactor)*100);

end