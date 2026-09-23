
function result = image_quality_check(inputImage)

    % 1. Read image
    I = imread(inputImage);

    % 2. Convert to grayscale and double
    if size(I, 3) == 3
        grayImage = rgb2gray(I);
    else
        grayImage = I;
    end
    grayImage = im2double(grayImage);

    % 3. Create preliminary retinal mask
    retinaMask = grayImage > 0.05;

    if ~any(retinaMask(:))
    result = struct( ...
        'quality', 'POOR', ...
        'reason', 'No retinal area detected', ...
        'recommendation', 'Recapture the image', ...
'passToPreprocessing', false, ...
'brightness', NaN, ...
'contrastScore', NaN, ...
'focusScore', NaN, ...
'darkPixelPercent', NaN, ...
'retinalCoverage', 0);

    disp(result);
    return;
end

   % 4. Calculate quality measurements
retinalPixels = grayImage(retinaMask);

brightness = mean(retinalPixels);
contrastScore = std(retinalPixels);

% New: percentage of dark retinal pixels
darkPixelPercent = 100 * mean(retinalPixels < (80/255));
% Estimate retinal coverage
retinalCoverage = 100 * nnz(retinaMask) / numel(retinaMask);
    lapKernel = [0 1 0; 1 -4 1; 0 1 0];
    lapResponse = imfilter(grayImage, lapKernel, 'replicate');
    focusScore = var(lapResponse(retinaMask));

    % 5. Preliminary thresholds - NOT clinically validated
    focusThreshold = 0.0001;
    minBrightness = 0.15;
    maxBrightness = 0.80;
    minContrast = 0.02;

    % Review bands: values close to limits need review
    focusReview = 1.2 * focusThreshold;
    brightnessMargin = 0.03;
    contrastReview = 1.2 * minContrast;

    % 6. Classify image
    quality = 'GOOD';
    reason = 'All preliminary checks passed';

    if brightness < minBrightness
    quality = 'POOR';
    reason = 'Image may be too dark';
elseif focusScore < focusThreshold
    quality = 'POOR';
    reason = 'Image may be blurry';
    elseif brightness > maxBrightness
        quality = 'POOR';
        reason = 'Image may be overexposed';

    elseif contrastScore < minContrast
        quality = 'POOR';
        reason = 'Image may have low contrast';

    elseif focusScore < focusReview || ...
       brightness < minBrightness + brightnessMargin || ...
       brightness > maxBrightness - brightnessMargin || ...
       contrastScore < contrastReview || ...
       darkPixelPercent > 60
    quality = 'UNCERTAIN';
    reason = sprintf('Review needed: dark pixels %.2f%%', darkPixelPercent);
end
    % 7. Recommendation and handoff
    if strcmp(quality, 'POOR')
    recommendation = 'Recapture image';
    passToPreprocessing = false;

elseif strcmp(quality, 'UNCERTAIN')
    recommendation = ['Check illumination and retinal coverage; ' ...
                      'review or recapture if needed'];
    passToPreprocessing = false;

else
    recommendation = 'Preliminary quality checks passed';
    passToPreprocessing = true;
end

    % 8. Display report
    fprintf('\n--- IMAGE QUALITY REPORT ---\n');
    fprintf('Image Quality: %s\n', quality);
    fprintf('Reason: %s\n', reason);
    fprintf('Brightness: %.4f\n', brightness);
    fprintf('Contrast: %.4f\n', contrastScore);
    fprintf('Focus Score: %.6f\n', focusScore);
    fprintf('Dark Pixels: %.2f%%\n', darkPixelPercent);
    fprintf('Retinal Coverage: %.2f%%\n', retinalCoverage);
    fprintf('Recommendation: %s\n', recommendation);

   % 9. Return result
result = struct( ...
    'quality', quality, ...
    'reason', reason, ...
    'recommendation', recommendation, ...
    'passToPreprocessing', passToPreprocessing, ...
    'brightness', brightness, ...
    'contrastScore', contrastScore, ...
    'focusScore', focusScore, ...
    'darkPixelPercent', darkPixelPercent, ...
    'retinalCoverage', retinalCoverage);
    % 10. Display image
    figure;
    subplot(1,2,1);
    imshow(I);
    title('Original Fundus Image');

    subplot(1,2,2);
    imshow(grayImage);
    title('Grayscale Image');
    % 11. Display retinal mask
    figure;
    imshow(retinaMask);
    title('Preliminary Retinal Mask');
    figure;
    imshow(I);
    hold on;
    visboundaries(retinaMask, 'Color', 'r');
    title('Retinal Mask Boundary');
    hold off;
end