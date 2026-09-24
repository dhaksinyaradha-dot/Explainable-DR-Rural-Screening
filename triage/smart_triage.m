function result = smart_triage(imageQuality, grade, confidence)
% SMART_TRIAGE
% Determines the screening action and ophthalmologist referral priority.
%
% INPUT:
%   imageQuality - "GOOD" or "POOR"
%   grade        - DR grade (0 to 4)
%   confidence   - model confidence as a value from 0 to 1
%
% OUTPUT:
%   result.action
%   result.priority
%   result.reason
%   result.sendToOphthalmologist

% Initialize result
result.action = "";
result.priority = 0;
result.reason = "";
result.sendToOphthalmologist = false;

% 1. Check image quality first
if imageQuality == "POOR"

    result.action = "RECAPTURE";
    result.priority = 0;
    result.reason = "Image quality is poor. Recapture required.";
    result.sendToOphthalmologist = false;

    % 2. High DR grade
elseif grade >= 3

    result.action = "PRIORITY REVIEW";
    result.priority = 3;
    result.reason = "High DR grade requires priority ophthalmologist review.";
    result.sendToOphthalmologist = true;

    % 3. Mild/moderate DR
elseif grade >= 1

    result.action = "REVIEW";
    result.priority = 2;
    result.reason = "DR detected. Ophthalmologist review recommended.";
    result.sendToOphthalmologist = true;

    % 4. No DR
else

    result.action = "ROUTINE";
    result.priority = 1;
    result.reason = "No DR detected by the grading model.";
    result.sendToOphthalmologist = false;

end

end