function dataset = createForecastHorizon(dataset, horizonSteps)

    disp("Creating future forecasting target...");

    n = height(dataset);

    if horizonSteps <= 0 || horizonSteps >= n
        error("horizonSteps must be greater than 0 and smaller than the dataset.");
    end

    % At row t, predict PV power at t + horizonSteps
    dataset.target_power_24h = [ ...
        dataset.total_power(horizonSteps+1:end); ...
        NaN(horizonSteps,1)];

    % Store the timestamp corresponding to the target
    dataset.target_timestamp_24h = [ ...
        dataset.timestamp(horizonSteps+1:end); ...
        NaT(horizonSteps,1)];

    % Remove final rows for which future power is unavailable
    dataset = rmmissing(dataset, ...
        'DataVariables', {'target_power_24h'});

    fprintf("Forecast horizon = %d time steps\n", horizonSteps);
    fprintf("Forecast horizon = %.2f hours\n", ...
        horizonSteps * 15 / 60);

    disp("Dataset size after target construction:");
    disp(size(dataset));

end