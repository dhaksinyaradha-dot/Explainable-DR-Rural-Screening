function [scoreMap, confidence] = explain_dr(trainedNet, finalImage, predictedLabel, scores)
% EXPLAIN_DR
% Generates Grad-CAM explanation for a diabetic retinopathy prediction.
%
% INPUT:
%   trainedNet      - trained DR classification network
%   finalImage      - preprocessed 224x224 RGB fundus image
%   predictedLabel  - predicted DR class
%   scores          - class probability scores
%
% OUTPUT:
%   scoreMap        - Grad-CAM heatmap
%   confidence      - prediction confidence

% Model-specific feature layer
featureLayer = "res5b_branch2b";

% Generate Grad-CAM
scoreMap = gradCAM( ...
    trainedNet, ...
    finalImage, ...
    predictedLabel, ...
    FeatureLayer=featureLayer);

% Prediction confidence
confidence = max(scores);

end