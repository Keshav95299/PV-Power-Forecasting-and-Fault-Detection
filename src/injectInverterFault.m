function faultyResults = injectInverterFault(testResults)

    disp("Injecting inverter underperformance fault...");

    faultyResults = testResults;

    n = height(faultyResults);

    % Start fault after 40% of test period
    faultStart = round(0.40 * n);

    % Inverter underperformance: 10% drop
    faultFactor = 0.90;

    % Ground-truth anomaly label
    faultyResults.isFault = false(n,1);
    faultyResults.isFault(faultStart:end) = true;

    % Inject fault into actual measured power
    faultyResults.actual_faulty = faultyResults.actual;
    faultyResults.actual_faulty(faultStart:end) = ...
        faultyResults.actual(faultStart:end) * faultFactor;

    fprintf("Fault starts at sample: %d\n", faultStart);
    fprintf("Fault factor: %.2f\n", faultFactor);

end