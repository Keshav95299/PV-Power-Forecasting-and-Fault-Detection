function detectionResults = detectFaults(inputResults, plotTitle)

disp("Running sliding-window fault detector...");

k = 4;   % 4 consecutive violations = 1 hour at 15-min resolution

n = height(inputResults);
detected = false(n,1);
count = 0;

for i = 1:n

    if inputResults.actual_faulty(i) < inputResults.lower(i)
        count = count + 1;
    else
        count = 0;
    end

    if count == k
        detected(i) = true;
    end

end

detectionResults = inputResults;
detectionResults.detected = detected;

faultStart = find(detectionResults.isFault,1);

firstDetection = find(detectionResults.detected & ((1:n)' >= faultStart),1);

if isempty(firstDetection)
    fprintf('No fault detected.\n');
    delay = NaN;
else
    delay = firstDetection - faultStart;
    fprintf('Detection delay = %d samples\n',delay);
    fprintf('Detection delay = %.2f hours\n',delay*15/60);
end

falsePositives = sum(detectionResults.detected & ~detectionResults.isFault);
fprintf('False positives = %d\n',falsePositives);

% Plot around fault start and detection
if ~isempty(firstDetection)
    startPlot = max(1, faultStart - 50);
    endPlot   = min(n, firstDetection + 100);
else
    startPlot = max(1, faultStart - 50);
    endPlot   = min(n, faultStart + 500);
end

figure;
hold on;

h = [];
labels = {};

h(end+1) = plot(startPlot:endPlot, ...
    detectionResults.actual_faulty(startPlot:endPlot), ...
    'b','LineWidth',1.5);
labels{end+1} = 'Faulty Power';

h(end+1) = plot(startPlot:endPlot, ...
    detectionResults.lower(startPlot:endPlot), ...
    'k--','LineWidth',1);
labels{end+1} = 'Lower Bound';

h(end+1) = plot(startPlot:endPlot, ...
    detectionResults.upper(startPlot:endPlot), ...
    'k--','LineWidth',1);
labels{end+1} = 'Upper Bound';

detIdx = find(detectionResults.detected);
detIdx = detIdx(detIdx >= startPlot & detIdx <= endPlot);

if ~isempty(detIdx)
    h(end+1) = plot(detIdx, ...
        detectionResults.actual_faulty(detIdx), ...
        'ro','MarkerSize',7,'LineWidth',1.5);
    labels{end+1} = 'Detected';
end

h(end+1) = xline(faultStart,'m--','LineWidth',2);
labels{end+1} = 'Fault Start';

if ~isempty(firstDetection)
    h(end+1) = xline(firstDetection,'g--','LineWidth',2);
    labels{end+1} = 'Detection';
end

xlabel('Sample');
ylabel('Power (W)');
title(plotTitle);
legend(h, labels, 'Location','northwest');
grid on;

end