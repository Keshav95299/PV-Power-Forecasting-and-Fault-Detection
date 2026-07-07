function forecastDecoded = decodeForecast(forecast)

    n = height(forecast);

    irr        = cell(n,1);
    temp       = cell(n,1);
    cloud      = cell(n,1);
    wind       = cell(n,1);
    humidity   = cell(n,1);

    for i = 1:n
        irr{i}      = parseForecastVector(forecast.weather_prediction_total_solar_irradiance{i});
        temp{i}     = parseForecastVector(forecast.weather_prediction_temperature_at_2m{i});
        cloud{i}    = parseForecastVector(forecast.weather_prediction_total_cloud_coverage{i});
        wind{i}     = parseForecastVector(forecast.weather_prediction_mean_wind_speed_at_10m{i});
        humidity{i} = parseForecastVector(forecast.weather_prediction_relative_humidity_at_2m{i});
    end

    forecastDecoded = table( ...
        forecast.weather_prediction_timestamp, ...
        forecast.weather_prediction_start_timestamp, ...
        irr, temp, cloud, wind, humidity, ...
        'VariableNames', ...
        {'forecastTime','startTime','irradiance','temperature','cloudCover','windSpeed','humidity'});

    disp("Forecast decoding complete.");
    disp(size(forecastDecoded));

    disp("First decoded vector lengths:");
    disp([ ...
        length(forecastDecoded.irradiance{1}), ...
        length(forecastDecoded.temperature{1}), ...
        length(forecastDecoded.cloudCover{1}), ...
        length(forecastDecoded.windSpeed{1}), ...
        length(forecastDecoded.humidity{1}) ...
    ]);

end


function x = parseForecastVector(s)

    s = erase(s, {'[',']'});
    x = str2num(s); %#ok<ST2NM>

end