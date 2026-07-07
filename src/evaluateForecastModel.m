function yPred = evaluateForecastModel(model, testData, featureNames)

    disp("Evaluating forecasting model...");

    % Features
    XTest = testData(:, featureNames);

    % True values
    yTrue = testData.total_power;

    % Predictions
    yPred = predict(model, XTest);

    % Error metrics
    rmse = sqrt(mean((yTrue - yPred).^2));
    mae = mean(abs(yTrue - yPred));

    fprintf('RMSE = %.2f W\n', rmse);
    fprintf('MAE  = %.2f W\n', mae);

    % Plot
    figure;
    figure;

idx = 1:300;

plot(idx, yTrue(idx), 'b', 'LineWidth', 1.5);
hold on;
plot(idx, yPred(idx), 'r', 'LineWidth', 1.5);

legend('Actual','Predicted');
xlabel('Sample');
ylabel('PV Power (W)');
title('Forecast Model Performance (First 300 Samples)');
grid on;

end