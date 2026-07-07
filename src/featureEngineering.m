function dataset = featureEngineering(dataset)

    disp("Adding time-based features...");

    % Hour of day
    hourValue = hour(dataset.timestamp) + minute(dataset.timestamp)/60;

    % Day of year
    dayValue = day(dataset.timestamp, 'dayofyear');

    % Cyclic encoding for hour
    dataset.hour_sin = sin(2*pi*hourValue/24);
    dataset.hour_cos = cos(2*pi*hourValue/24);

    % Cyclic encoding for day of year
    dataset.day_sin = sin(2*pi*dayValue/365);
    dataset.day_cos = cos(2*pi*dayValue/365);

 
    disp("Feature engineering complete.");
    disp("Dataset size after features:");
    disp(size(dataset));

   

end