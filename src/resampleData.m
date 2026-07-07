function [pv15, weather15] = resampleData(pv, weather)

    disp("Resampling PV and weather data to 15-minute resolution...");

    %% -------- PV DATA --------
    % Keep only useful columns
    pvSmall = pv(:, { ...
        'photovoltaic_id', ...
        'photovoltaic_measurement_timestamp', ...
        'photovoltaic_measurement_active_power'});

    % Rename for readability
    pvSmall.Properties.VariableNames = {'pv_id','timestamp','power'};

    % Keep PV1-PV3 only
    pvSmall = pvSmall(pvSmall.pv_id <= 3, :);

    % Remove missing power rows
    pvSmall = pvSmall(~isnan(pvSmall.power), :);

    % Create separate 15-min power signals for PV1, PV2, PV3
    pv15 = table();

    for id = 1:3
        temp = pvSmall(pvSmall.pv_id == id, :);
        temp = sortrows(temp, 'timestamp');

        tt = table2timetable(temp(:, {'timestamp','power'}), ...
            'RowTimes', 'timestamp');

        % 15-min average active power
        tt15 = retime(tt, 'regular', 'mean', 'TimeStep', minutes(15));

        varName = sprintf('power_pv%d', id);

        if id == 1
            pv15 = timetable2table(tt15);
            pv15.Properties.VariableNames = {'timestamp', varName};
        else
            tempTable = timetable2table(tt15);
            tempTable.Properties.VariableNames = {'timestamp', varName};
            pv15 = outerjoin(pv15, tempTable, ...
                'Keys', 'timestamp', ...
                'MergeKeys', true);
        end
    end

    % Total PV power from PV1-PV3
    pv15.total_power = sum(pv15{:, {'power_pv1','power_pv2','power_pv3'}}, ...
        2, 'omitnan');


    %% -------- WEATHER DATA --------
    weatherSmall = weather(:, { ...
        'weather_station_measurement_timestamp', ...
        'weather_station_measurement_sun_zenith_angle', ...
        'weather_station_measurement_sun_azimuth', ...
        'weather_station_measurement_outdoor_temperature_south', ...
        'weather_station_measurement_global_irradiance', ...
        'weather_station_measurement_direct_solar_irradiance', ...
        'weather_station_measurement_diffuse_solar_irradiance', ...
        'weather_station_measurement_wind_speed', ...
        'weather_station_measurement_relative_humidity'});

    weatherSmall.Properties.VariableNames = { ...
        'timestamp', ...
        'sun_zenith', ...
        'sun_azimuth', ...
        'temperature', ...
        'global_irradiance', ...
        'direct_irradiance', ...
        'diffuse_irradiance', ...
        'wind_speed', ...
        'humidity'};

    weatherSmall = sortrows(weatherSmall, 'timestamp');

    weatherTT = table2timetable(weatherSmall, 'RowTimes', 'timestamp');

    % 15-min average weather values
    weather15TT = retime(weatherTT, 'regular', 'mean', 'TimeStep', minutes(15));

    weather15 = timetable2table(weather15TT);

    disp("Resampling complete.");
    disp("PV 15-min size:");
    disp(size(pv15));

    disp("Weather 15-min size:");
    disp(size(weather15));

end