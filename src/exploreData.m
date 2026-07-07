function exploreData(pv, weather, forecast)

    disp("PV size:");
    disp(size(pv));

    disp("Weather size:");
    disp(size(weather));

    disp("Forecast size:");
    disp(size(forecast));

    disp("PV variable names:");
    disp(pv.Properties.VariableNames');

    disp("Weather variable names:");
    disp(weather.Properties.VariableNames');

    disp("Forecast variable names:");
    disp(forecast.Properties.VariableNames');

    disp("PV IDs:");
    disp(unique(pv.photovoltaic_id));

    disp("Weather station IDs:");
    disp(unique(weather.weather_station_id));

    disp("Missing values in PV:");
    disp(sum(ismissing(pv)));

end