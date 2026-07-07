function analyzeResiduals(testData, yPred)

disp("Analyzing residuals...");

yTrue = testData.total_power;
residuals = yTrue - yPred;
absResiduals = abs(residuals);

hourValue = hour(testData.timestamp) + minute(testData.timestamp)/60;

% Plot 1: residuals vs time of day
figure;
scatter(hourValue, residuals, 10, 'filled');
xlabel('Hour of Day');
ylabel('Residual (Actual - Predicted) [W]');
title('Residuals vs Time of Day');
grid on;

% Plot 2: absolute residuals vs global irradiance
figure;
scatter(testData.global_irradiance, absResiduals, 10, 'filled');
xlabel('Global Irradiance (W/m^2)');
ylabel('Absolute Error (W)');
title('Absolute Error vs Global Irradiance');
grid on;

% Plot 3: residual histogram
figure;
histogram(residuals,50);
xlabel('Residual (W)');
ylabel('Count');
title('Residual Distribution');
grid on;

fprintf('Residual mean = %.2f W\n', mean(residuals));
fprintf('Residual std  = %.2f W\n', std(residuals));
fprintf('Max abs error = %.2f W\n', max(absResiduals));

end