function [pv, weather, forecast] = loadData()

    pv = readtable('photovoltaic_measurement_history.csv');
    weather = readtable('weather_station_measurement_history.csv');
    forecast = readtable('weather_prediction_history.csv');

    pv.photovoltaic_measurement_timestamp = datetime(pv.photovoltaic_measurement_timestamp);
    weather.weather_station_measurement_timestamp = datetime(weather.weather_station_measurement_timestamp);
    forecast.weather_prediction_timestamp = datetime(forecast.weather_prediction_timestamp);
    forecast.weather_prediction_start_timestamp = datetime(forecast.weather_prediction_start_timestamp);

end