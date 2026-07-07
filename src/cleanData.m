function [pv, weather, forecast] = cleanData(pv, weather, forecast)

    % Sort data
    pv = sortrows(pv, 'photovoltaic_measurement_timestamp');
    weather = sortrows(weather, 'weather_station_measurement_timestamp');
    forecast = sortrows(forecast, 'weather_prediction_timestamp');

    % Replace physically impossible irradiance values with NaN
    pv.photovoltaic_measurement_global_irradiance_pv_plane( ...
        pv.photovoltaic_measurement_global_irradiance_pv_plane < 0) = NaN;

    % Clip negative weather irradiance values to zero
    irrCols = contains(weather.Properties.VariableNames, 'irradiance');
    for i = find(irrCols)
        col = weather.Properties.VariableNames{i};
        weather.(col)(weather.(col) < 0) = NaN;
    end

    % Keep only PV systems with active power data: PV1, PV2, PV3
    pv = pv(pv.photovoltaic_id <= 3, :);

    % Remove rows with missing active power
    pv = pv(~isnan(pv.photovoltaic_measurement_active_power), :);

    disp("Cleaning complete.");
    disp("Cleaned PV size:");
    disp(size(pv));

end