function sweepResults = kSensitivitySweep(faultResults, scenarioName)

disp("Running k-sensitivity sweep...");

kValues = 1:10;
n = height(faultResults);

faultStart = find(faultResults.isFault,1);

delaySamples = NaN(length(kValues),1);
delayHours = NaN(length(kValues),1);
falsePositives = zeros(length(kValues),1);

for j = 1:length(kValues)

    k = kValues(j);
    detected = false(n,1);
    count = 0;

    for i = 1:n

        if faultResults.actual_faulty(i) < faultResults.lower(i)
            count = count + 1;
        else
            count = 0;
        end

        if count == k
            detected(i) = true;
        end
    end

    firstDetection = find(detected & ((1:n)' >= faultStart),1);

    if ~isempty(firstDetection)
        delaySamples(j) = firstDetection - faultStart;
        delayHours(j) = delaySamples(j) * 15 / 60;
    end

    falsePositives(j) = sum(detected & ~faultResults.isFault);
end

sweepResults = table(kValues', delaySamples, delayHours, falsePositives, ...
    'VariableNames', {'k','delay_samples','delay_hours','false_positives'});

disp(sweepResults);

figure;
plot(sweepResults.k, sweepResults.delay_hours, '-o','LineWidth',1.5);
xlabel('k consecutive violations');
ylabel('Detection Delay (hours)');
title(['Detection Delay vs k - ', scenarioName]);
grid on;

figure;
plot(sweepResults.k, sweepResults.false_positives, '-o','LineWidth',1.5);
xlabel('k consecutive violations');
ylabel('False Positives');
title(['False Positives vs k - ', scenarioName]);
grid on;

figure;
plot(sweepResults.false_positives, sweepResults.delay_hours, ...
    '-o','LineWidth',1.5);
xlabel('False Positives');
ylabel('Detection Delay (hours)');
title(['Delay vs False Positive Tradeoff - ', scenarioName]);
grid on;
end