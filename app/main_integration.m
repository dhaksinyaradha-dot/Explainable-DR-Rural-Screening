clc;
clear;
close all;

fprintf("\n============================================\n");
fprintf(" DIABETIC RETINOPATHY SCREENING SYSTEM\n");
fprintf("============================================\n");

%% SELECT FUNDUS IMAGE

[file, path] = uigetfile( ...
    {'*.jpg;*.jpeg;*.png', 'Fundus Images'}, ...
    'Select Fundus Image');

if isequal(file, 0)
    fprintf("\nNo image selected.\n");
    return;
end

imagePath = fullfile(path, file);

fprintf("\nSelected Image: %s\n", file);
%% IMAGE QUALITY CHECK

fprintf("\n--- IMAGE QUALITY CHECK ---\n");

r = image_quality_check(imagePath);

fprintf("Image Quality : %s\n", r.quality);
fprintf("Reason        : %s\n", r.reason);
fprintf("Recommendation: %s\n", r.recommendation);

if r.passToPreprocessing == 0
    fprintf("\nImage rejected.\n");
    fprintf("Please recapture/select another fundus image.\n");
    return;
end

fprintf("Status        : PASSED\n");
%% PREPROCESSING

fprintf("\n--- PREPROCESSING ---\n");

img = imread(imagePath);

finalImage = preprocess_image(img);

fprintf("Preprocessing : COMPLETED\n");
fprintf("Final Size    : %d x %d x %d\n", ...
    size(finalImage,1), ...
    size(finalImage,2), ...
    size(finalImage,3));
%% DR SEVERITY GRADING

fprintf("\n--- DR SEVERITY GRADING ---\n");

load("DR_Grading_Model.mat", "trainedNet");

[predictedLabel, scores] = ...
    classify(trainedNet, finalImage);

grade = str2double(string(predictedLabel));

confidence = max(scores);

fprintf("\nDR Grade      : %d\n", grade);
fprintf("Confidence    : %.2f%%\n", confidence * 100);

fprintf("\nClass Probabilities:\n");

for i = 1:numel(scores)
    fprintf("Class %d : %.2f%%\n", ...
        i-1, scores(i) * 100);
end
%% EXPLAINABILITY - GRAD-CAM

fprintf("\n--- GRAD-CAM EXPLAINABILITY ---\n");

[scoreMap, camConfidence] = ...
    explain_dr(trainedNet, finalImage, predictedLabel, scores);

fprintf("Grad-CAM     : GENERATED\n");
fprintf("Confidence   : %.2f%%\n", camConfidence * 100);
%% SMART TRIAGE

fprintf("\n--- SMART TRIAGE ---\n");

triage = smart_triage( ...
    r.quality, ...
    grade, ...
    confidence);

fprintf("Action       : %s\n", triage.action);
fprintf("Priority     : %d\n", triage.priority);
fprintf("Reason       : %s\n", triage.reason);
fprintf("Ophthalmologist Review: %d\n", ...
    triage.sendToOphthalmologist);
%% OPHTHALMOLOGIST QUEUE

fprintf("\n--- OPHTHALMOLOGIST QUEUE ---\n");

patient.id = file;
patient.priority = triage.priority;
patient.action = triage.action;
patient.reason = triage.reason;
patient.grade = grade;
patient.confidence = confidence;

queue = ophthalmologist_queue(patient);

fprintf("Patient added to ophthalmologist queue.\n");
fprintf("Queue Priority : %d\n", queue.priority);
fprintf("Action         : %s\n", queue.action);
%% FINAL SCREENING RESULT

originalImage = imread(imagePath);

scoreMapOriginal = imresize( ...
    scoreMap, ...
    [size(originalImage,1), size(originalImage,2)]);

% Convert confidence to percentage
confidencePercent = confidence * 100;

% Create result window
figure( ...
    'Name', 'DR Screening System - Final Result', ...
    'NumberTitle', 'off', ...
    'Color', 'w', ...
    'Position', [100 100 1200 700]);

%% Original image

subplot(2,2,1);

imshow(originalImage);

title('Original Fundus Image', ...
    'FontSize', 14, ...
    'FontWeight', 'bold');

%% Grad-CAM

subplot(2,2,2);

imshow(originalImage);

hold on;

imagesc(scoreMapOriginal);

colormap jet;

colorbar;

alpha(0.45);

title('Grad-CAM Explainability', ...
    'FontSize', 14, ...
    'FontWeight', 'bold');

hold off;

%% Result information

subplot(2,2,3);

axis off;

text(0.05, 0.90, 'SCREENING RESULT', ...
    'FontSize', 16, ...
    'FontWeight', 'bold');

text(0.05, 0.72, ...
    sprintf('Image Quality : %s', string(r.quality)), ...
    'FontSize', 13);

text(0.05, 0.58, ...
    sprintf('DR Grade      : %d', grade), ...
    'FontSize', 13);

text(0.05, 0.44, ...
    sprintf('Confidence    : %.2f%%', confidencePercent), ...
    'FontSize', 13);

text(0.05, 0.30, ...
    sprintf('Priority      : %d', triage.priority), ...
    'FontSize', 13);

text(0.05, 0.16, ...
    sprintf('Action        : %s', triage.action), ...
    'FontSize', 13);

%% Recommendation

subplot(2,2,4);

axis off;

text(0.05, 0.85, 'RECOMMENDATION', ...
    'FontSize', 16, ...
    'FontWeight', 'bold');

text(0.05, 0.65, ...
    sprintf('%s', triage.reason), ...
    'FontSize', 13, ...
    'Units', 'normalized');

if triage.sendToOphthalmologist

    text(0.05, 0.40, ...
        'Ophthalmologist Review: REQUIRED', ...
        'FontSize', 13, ...
        'FontWeight', 'bold');

else

    text(0.05, 0.40, ...
        'Ophthalmologist Review: NOT REQUIRED', ...
        'FontSize', 13, ...
        'FontWeight', 'bold');

end

text(0.05, 0.20, ...
    'Grad-CAM shows model-attribution evidence.', ...
    'FontSize', 11);

text(0.05,0.10,'It is not independent clinical lesion confirmation.','FontSize',11);