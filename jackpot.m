function [trialData, trialsToJackpot, pJackpot] = jackpot(nTrials, nReps)
prob = rand()*0.05;
trialData = randsrc(nTrials, nReps, [0 1; 1-prob prob]);
[row, col] = find(trialData);

RepData = cat(2,col,row);
CellData = num2cell(RepData, 2);
pJackpot = numel(row) ./ (nTrials.*nReps);
trialsToJackpot = NaN(nReps,1);

trialsToJackpot = arrayfun(@(x) min(row(col==x)), 1:nReps, ...
                           'UniformOutput', false)';