function dataset = featureEngineering(dataset)

    disp("Adding time, lag, and rolling features...");

    %% Time features at forecast issue time t

    hourValue = hour(dataset.timestamp) + ...
                minute(dataset.timestamp)/60;

    dayValue = day(dataset.timestamp, 'dayofyear');

    % Cyclic hour encoding
    dataset.hour_sin = sin(2*pi*hourValue/24);
    dataset.hour_cos = cos(2*pi*hourValue/24);

    % Cyclic day-of-year encoding
    dataset.day_sin = sin(2*pi*dayValue/365);
    dataset.day_cos = cos(2*pi*dayValue/365);

    %% Historical PV features
    % At time t, total_power is known.
    % For a t+96 target, this represents PV power 24 hours before target.
    dataset.power_at_issue_time = dataset.total_power;

    % Older historical PV measurements
    dataset.power_lag_1h = [ ...
        NaN(4,1); ...
        dataset.total_power(1:end-4)];

    dataset.power_lag_6h = [ ...
        NaN(24,1); ...
        dataset.total_power(1:end-24)];

    dataset.power_lag_24h = [ ...
        NaN(96,1); ...
        dataset.total_power(1:end-96)];

    %% Historical irradiance features

    dataset.global_irradiance_lag_1h = [ ...
        NaN(4,1); ...
        dataset.global_irradiance(1:end-4)];

    dataset.global_irradiance_lag_24h = [ ...
        NaN(96,1); ...
        dataset.global_irradiance(1:end-96)];

    %% Trailing rolling averages
    % These use only the current and previous samples, never future data.

    dataset.power_mean_1h = movmean( ...
        dataset.total_power, ...
        [3 0], ...
        'omitnan');

    dataset.power_mean_6h = movmean( ...
        dataset.total_power, ...
        [23 0], ...
        'omitnan');

    dataset.irradiance_mean_1h = movmean( ...
        dataset.global_irradiance, ...
        [3 0], ...
        'omitnan');

    dataset.irradiance_mean_6h = movmean( ...
        dataset.global_irradiance, ...
        [23 0], ...
        'omitnan');

    %% Remove rows made incomplete by lag features

    dataset = rmmissing(dataset);

    disp("Feature engineering complete.");
    disp("Dataset size after feature engineering:");
    disp(size(dataset));

end