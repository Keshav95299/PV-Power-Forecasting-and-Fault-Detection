function dataset = mergeData(pv15, weather15)

    disp("Merging PV and weather data...");

    % Merge on timestamp: keep only timestamps present in both tables
    dataset = innerjoin(pv15, weather15, 'Keys', 'timestamp');

    % Remove wind speed for now because values are physically invalid
    if ismember('wind_speed', dataset.Properties.VariableNames)
        dataset.wind_speed = [];
    end

    % Remove rows with missing values
    dataset = rmmissing(dataset);

    % Keep only daytime / production rows
  dataset = dataset(dataset.total_power > 0,:);

    disp("Merged dataset complete.");
    disp("Dataset size:");
    disp(size(dataset));

    disp("Dataset variables:");
    disp(dataset.Properties.VariableNames');

end