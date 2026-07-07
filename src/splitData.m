function [trainData, calibData, testData] = splitData(dataset)

    disp("Splitting dataset...");

    n = height(dataset);

    trainEnd = floor(0.70*n);
    calibEnd = floor(0.85*n);

    trainData = dataset(1:trainEnd,:);
    calibData = dataset(trainEnd+1:calibEnd,:);
    testData  = dataset(calibEnd+1:end,:);

    fprintf('Training samples: %d\n',height(trainData));
    fprintf('Calibration samples: %d\n',height(calibData));
    fprintf('Testing samples: %d\n',height(testData));

end