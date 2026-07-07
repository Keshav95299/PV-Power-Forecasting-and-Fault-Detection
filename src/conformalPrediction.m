function [qhat, testResults] = conformalPrediction(model, calibData, testData, featureNames)

    disp("Applying split conformal prediction...");

    alpha = 0.10;   % 90% prediction interval

    %% ===== Calibration predictions =====
    XCalib = calibData(:, featureNames);
    yCalib = calibData.total_power;

    yCalibPred = predict(model, XCalib);

    %% ===== Nonconformity scores =====
    scores = abs(yCalib - yCalibPred);

    %% ===== Conformal quantile (order statistic) =====
    scores = sort(scores);

    n = length(scores);
    k = ceil((n + 1) * (1 - alpha));
    k = min(k, n);

    qhat = scores(k);

    %% ===== Test predictions =====
    XTest = testData(:, featureNames);
    yTest = testData.total_power;

    yTestPred = predict(model, XTest);

    lower = yTestPred - qhat;
    upper = yTestPred + qhat;

    % PV power cannot be negative
    lower(lower < 0) = 0;

    %% ===== Store results =====
    testResults = table( ...
        testData.timestamp, ...
        yTest, ...
        yTestPred, ...
        lower, ...
        upper, ...
        'VariableNames', ...
        {'timestamp','actual','predicted','lower','upper'});

    %% ===== Metrics =====
    inside = (yTest >= lower) & (yTest <= upper);

    coverage = mean(inside);
    avgWidth = mean(upper - lower);

    fprintf('Conformal qhat = %.2f W\n', qhat);
    fprintf('Empirical coverage = %.2f %%\n', coverage*100);
    fprintf('Average interval width = %.2f W\n', avgWidth);

    %% ===== Plot =====
    idx = 1:min(300,height(testResults));

    figure;
    hold on;

    plot(idx, testResults.actual(idx), 'b', 'LineWidth', 1.5);
    plot(idx, testResults.predicted(idx), 'r', 'LineWidth', 1.5);
    plot(idx, testResults.lower(idx), 'k--');
    plot(idx, testResults.upper(idx), 'k--');

    xlabel('Sample');
    ylabel('PV Power (W)');
    title('Conformal Prediction Intervals');

    legend('Actual','Predicted','Lower bound','Upper bound', ...
           'Location','best');

    grid on;

end