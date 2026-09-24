function finalImage = preprocess_image(img)
% PREPROCESS_IMAGE
% Preprocesses a fundus image for downstream diabetic retinopathy grading.
%
% INPUT:
%   img - RGB or grayscale fundus image
%
% OUTPUT:
%   finalImage - enhanced RGB image resized to 224 x 224
%
% Processing:
%   1. Retinal region estimation
%   2. Illumination normalization
%   3. Median denoising
%   4. CLAHE enhancement
%   5. Resize to 224 x 224
%
% NOTE:
%   This is a preprocessing prototype. It does not perform
%   diabetic retinopathy diagnosis.

    %% 1. Validate input

    if nargin < 1
        error('No input image was provided.');
    end

    if isempty(img)
        error('Input image is empty.');
    end

    %% 2. Convert image to double

    img = im2double(img);

    %% 3. Handle RGB / grayscale input

    if ndims(img) == 3 && size(img, 3) == 3

        % RGB image
        rgbImage = img;

        gray = rgb2gray(img);

    elseif ismatrix(img)

        % Grayscale image
        gray = img;

        % Convert grayscale to RGB so that the rest of the
        % pipeline consistently produces a 3-channel image
        rgbImage = repmat(img, [1 1 3]);

    else

        error('Input must be an RGB or grayscale image.');

    end

    %% 4. Create preliminary retinal mask

    mask = gray > 0.05;

    % Keep the largest connected region
    if any(mask(:))
        mask = bwareafilt(mask, 1);
    else
        % If no retinal region is detected, use the full image
        % as a fallback for preprocessing.
        mask = true(size(gray));
    end

    %% 5. Illumination normalization

    illumination = imgaussfilt(gray, 80);

    meanIllumination = mean(illumination(mask));

    gain = meanIllumination ./ (illumination + eps);

    % Limit correction strength
    gain = min(max(gain, 0.85), 1.15);

    corrected = zeros(size(rgbImage));

    for c = 1:3

        corrected(:,:,c) = rgbImage(:,:,c) .* gain;

    end

    % Keep original pixels outside the retinal region

    for c = 1:3

        channel = corrected(:,:,c);
        originalChannel = rgbImage(:,:,c);

        channel(~mask) = originalChannel(~mask);

        corrected(:,:,c) = channel;

    end

    % Keep pixel values within valid range

    corrected = min(max(corrected, 0), 1);

    %% 6. Denoising

    denoised = zeros(size(corrected));

    for c = 1:3

        denoised(:,:,c) = medfilt2( ...
            corrected(:,:,c), ...
            [3 3]);

    end

    %% 7. CLAHE enhancement

    labImg = rgb2lab(denoised);

    L = labImg(:,:,1);

    L_enhanced = adapthisteq( ...
        L / 100, ...
        'NumTiles', [4 4], ...
        'ClipLimit', 0.001);

    labImg(:,:,1) = L_enhanced * 100;

    claheImage = lab2rgb(labImg);

    % Keep values within valid range

    claheImage = min(max(claheImage, 0), 1);

    %% 8. Resize for downstream model

    finalImage = imresize(claheImage, [224 224]);

    %% 9. Ensure final output is valid

    finalImage = min(max(finalImage, 0), 1);

end