clc;
clear;
close all;

%% ================= LOAD MODEL =================
load("DR_Grading_Model.mat");

%% ================= SELECT IMAGE =================
[file, path] = uigetfile( ...
    {'*.jpg;*.jpeg;*.png', 'Fundus Images'}, ...
    'Select Fundus Image');

if isequal(file, 0)
    fprintf("No image selected.\n");
    return;
end

imagePath = fullfile(path, file);

fprintf("\n============================================\n");
fprintf(" DIABETIC RETINOPATHY SCREENING PIPELINE\n");
fprintf("============================================\n");

fprintf("\nSelected Image : %s\n", file);

%% ================= IMAGE QUALITY =================
fprintf("\n--- IMAGE QUALITY CHECK ---\n");

r = image_quality_check(imagePath);

fprintf("Image Quality : %s\n", r.quality);
fprintf("Reason        : %s\n", r.reason);

if r.passToPreprocessing == 0

    fprintf("\nImage rejected.\n");
    fprintf("Please select/capture another image.\n");

    return;
end

fprintf("Status        : PASSED\n");

%% ================= PREPROCESSING =================
fprintf("\n--- PREPROCESSING ---\n");

img = im2single(imread(imagePath));

%% Retinal mask
gray = rgb2gray(img);

mask = gray > 0.05;

mask = bwareafilt(mask, 1);

%% Illumination normalization
illumination = imgaussfilt(gray, 80);

meanIllumination = mean(illumination(mask));

gain = meanIllumination ./ ...
       (illumination + eps('single'));

gain = min(max(gain, 0.85), 1.15);

corrected = zeros(size(img), 'single');

for c = 1:3
    corrected(:,:,c) = img(:,:,c) .* gain;
end

%% Keep original pixels outside retina
for c = 1:3

    channel = corrected(:,:,c);

    originalChannel = img(:,:,c);

    channel(~mask) = originalChannel(~mask);

    corrected(:,:,c) = channel;

end

corrected = min(max(corrected, 0), 1);

%% Denoising
denoised = zeros(size(corrected), 'single');

for c = 1:3
    denoised(:,:,c) = medfilt2( ...
        corrected(:,:,c), [3 3]);
end

%% CLAHE
labImg = rgb2lab(denoised);

L = labImg(:,:,1);

L_enhanced = adapthisteq( ...
    L/100, ...
    'NumTiles', [4 4], ...
    'ClipLimit', 0.001);

labImg(:,:,1) = L_enhanced * 100;

claheImage = lab2rgb(labImg);

claheImage = min(max(claheImage, 0), 1);

%% Resize for ResNet-18
finalImage = imresize(claheImage, [224 224]);

fprintf("Preprocessing : COMPLETED\n");
fprintf("Final Size    : %d x %d x %d\n", size(finalImage));

%% ================= DR GRADING =================
fprintf("\n--- DR SEVERITY GRADING ---\n");

[predictedLabel, scores] = ...
    classify(trainedNet, finalImage);

grade = str2double(string(predictedLabel));

severityNames = ["No DR", ...
                 "Mild DR", ...
                 "Moderate DR", ...
                 "Severe DR", ...
                 "Proliferative DR"];

confidence = max(scores) * 100;

fprintf("\n============================================\n");
fprintf("          DR GRADING RESULT\n");
fprintf("============================================\n");

fprintf("Grade      : %d\n", grade);
fprintf("Severity   : %s\n", severityNames(grade + 1));
fprintf("Confidence : %.2f%%\n", confidence);

fprintf("\nProbabilities:\n");

for i = 1:5
    fprintf("Grade %d : %.2f%%\n", ...
        i-1, scores(i)*100);
end

fprintf("============================================\n");