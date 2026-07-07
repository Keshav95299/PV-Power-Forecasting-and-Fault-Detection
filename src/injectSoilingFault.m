function soilingResults = injectSoilingFault(testResults)

disp("Injecting soiling fault...");
disp("Reached line 1");

soilingResults = testResults;

n = height(soilingResults);

% Start after 40% of the test data
faultStart = round(0.40*n);

% Ground-truth labels
soilingResults.isFault = false(n,1);
soilingResults.isFault(faultStart:end) = true;

% Copy actual power
soilingResults.actual_faulty = soilingResults.actual;

% Gradually reduce power from 100% to 85%
degradation = linspace(1.0,0.85,n-faultStart+1)';

soilingResults.actual_faulty(faultStart:end) = ...
    soilingResults.actual(faultStart:end) .* degradation;

fprintf("Soiling starts at sample: %d\n",faultStart);
fprintf("Final degradation: %.0f %%\n",(1-degradation(end))*100);

end