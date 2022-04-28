%% Code for tests of Monotonicity and Figures
% This file is called from "paper forward looking reduced form.do"
% (henceforth referred to as "the STATA file"). The STATA file exports data
% to "T:\HealthCost\analysis\temp\relevantEstimates*.csv", where the *
% denotes the sub-group (refer to the STATA file for more details).
% This file consists of the following data, in the following order:
% For a specification (check the STATA file for the naming convention),
% column:
%   1: Estimated change in PC expenditures around turn of year
%   2: 1 - P^E_{1,y+1}
%   3: Standard errors of estimated change in PC exp
%   4: Estimated change in extensive margin around turn of year
%   5: Standard errors of estimated change in extensive margin
%   6: Estimated average PC expenditure in first day of new year
%   7: Estimated average PC expenditure in last day of old year
%   8: Number of individuals in year-pair
%   9: Estimated prob. daily expenditure in first day of new year
%   10: Estimated prob. daily expenditure in last day of old year
%   11: Deductible size in new year.

clear
% declare temp directory. This should be the same one as in the STATA file!
directoryForTempFiles = 'T:\HealthCost\analysis\temp\';
directoryForOutputFiles = 'T:\HealthCost\analysis\output\forward looking reduced form\';
directoryForOutputFigures = 'T:\HealthCost\analysis\output\forward looking reduced form\figures\';
% There are two types of tables produced by this program: an excel table
% (for easy access and readability) and a txt table (for the tablefill
% package). The excel tables will be in the directory mentioned in the
% STATA file.
directoryForTxtTable = 'M:\SVN\healthcost\write\03 forward looking reduced form\tables\';

removeLastYearRobustSpec = 51;
bothIntExtSpec = [13,15,19,32,33,42,43,44,45,46,47];

% loop over all specifications
for specification = 1:removeLastYearRobustSpec
    %% prepare data
    if specification == 14 
        continue;
    end
    
    if sum(specification == removeLastYearRobustSpec) >= 1
        if specification == removeLastYearRobustSpec
            filename = [directoryForTempFiles,'relevantEstimates13.csv'];
        else
            filename = [directoryForTempFiles,'relevantEstimates',int2str(specification),'.csv'];
        end
        K = csvread(filename);
        rowToRemove = K(:,11) == 375;
        K = K(~rowToRemove,:);
    else
        filename = [directoryForTempFiles,'relevantEstimates',int2str(specification),'.csv'];
        K = csvread(filename);  
    end
    
    % store data for last section (Table 5)
    if specification == 1
        allData = K;
        save([directoryForTempFiles,'allData.mat'],'allData');
    elseif sum(specification == removeLastYearRobustSpec) == 0
        load([directoryForTempFiles,'allData.mat'])
        allData(:,:,specification) = K;
        save([directoryForTempFiles,'allData.mat'],'allData');
    end
    
    tableLabel = {"<tab:specEst"+int2str(specification)+"a>";
        "<tab:specEst"+int2str(specification)+"b>";"<tab:specTest"+int2str(specification)+"a>";
        "<tab:specTest"+int2str(specification)+"b>"};
    
    estimatesTable = [directoryForTxtTable,'tables.txt'];
    
    if specification == 1
        fid = fopen(estimatesTable,'w');
    else
        fid = fopen(estimatesTable,'a');
    end
    
    fprintf(fid,tableLabel{1});
    fclose(fid);
    
    %% Figures and tables
    
    y = K(:,1);
    x = 1 - K(:,2);
    se = K(:,3);
    N = K(:,8);
    
    y2 = K(:,4);
    se2 = K(:,5);
    x2 = x;
    % This code writes down the estimates for each specification (Table 2 in
    % the paper is generated when specification = 13.
    checkIfSortingCorrect = round(K(:,11),3) == K(:,11); 
    
    if sum(checkIfSortingCorrect) ~= size(K,1)
        error('You are not sorting according to the deductible!')
    end
    
    estimatesInTable = sortrows(K,11);
    estimatesInTable = estimatesInTable(:,[1,3,4,5])';
    estimatesInTable = [reshape(estimatesInTable(1:2,:),size(K,1)*2,1), reshape(estimatesInTable(3:4,:),size(K,1)*2,1)];
    dlmwrite(estimatesTable,estimatesInTable,'-append','delimiter','\t','roffset',1);
    
    % Plot estimated change on P^{E}_{1,y+1}. Generates Figures 3, 4, 5 and
    % other similar figures in the appendix. Differenct figures are generated
    % depending on the specification being analyzed in the STATA file.
    
    plot(x,y,'ko');
    hold on
    
    upper = y + se*1.96;
    lower = y - se*1.96;
    
    for i = 1:length(x)
        plot([x(i) x(i)],[lower(i) upper(i)],'k-')
    end
    
    b = regress(y,[ones(size(x2,1),1),x]);
    fitted = b(1) + b(2)*x;
    
    plot(x,fitted)
    xlabel('change in dynamic incentives, $$ (\bar{P}^{e}_{1,y+1}) $$','Interpreter','latex')
    ylabel('discontinuity around change of the year','Interpreter','latex')
    ax = gca;

    if specification == 16
        ylabel('static incentives, $$ (\bar{P}^{c}_{1,y+1}) $$','Interpreter','latex')
        ax.YLim = [0.9,1];
        ax.YTick = [0.9:0.025:1];
    end

    ax.FontSize = 12;
    fig = gcf;
    fig.PaperOrientation = 'landscape';
    fig.PaperUnits = 'inches';
    fig.PaperPosition = [0 0 7 5];
    fig.PaperSize = [7 5];
    print([directoryForOutputFigures,'Coefficients',int2str(specification)],'-dpdf');
    
    hold off
    
    plot(x2,y2,'ko');
    hold on
    
    upper = y2 + se2*1.96;
    lower = y2 - se2*1.96;
    
    for i = 1:length(x)
        plot([x2(i) x2(i)],[lower(i) upper(i)],'k-')
    end
    
    b = regress(y2,[ones(size(x2,1),1),x2]);
    fitted = b(1) + b(2)*x2;
    
    plot(x2,fitted)
    xlabel('change in dynamic incentives, $$ (\bar{P}^{e}_{1,y+1}) $$','Interpreter','latex')
    ylabel('discontinuity around change of the year','Interpreter','latex')
     ax = gca;

    ax.FontSize = 12;
    fig = gcf;
    fig.PaperOrientation = 'landscape';
    fig.PaperUnits = 'inches';
    fig.PaperPosition = [0 0 7 5];
    fig.PaperSize = [7 5];
    
    print([directoryForOutputFigures,'CoefficientsExtensive',int2str(specification)],'-dpdf');
    
    hold off
    %% Run monotonicity tests
    inverseIt = size(x,1):-1:1;
    
    % Extensive Margin
    rankedX = x2(inverseIt);
    rankedY = y2(inverseIt);
    rankedSe = se2(inverseIt);
    
    reps = 10000;
    
    % Simulate estimated coefficients using standard error from asymptotic
    % distribution.
    simulatedData = [];
    for i = 1:reps
        simulatedData(:,i) = normrnd(rankedY,rankedSe);
    end
    
    % obtain weights using procedure outlined in Hanushek (1973)
    regCoeff = fitlm(rankedX,rankedY);
    NegGMat = eye(size(x2,1)).*repmat(rankedSe,1,size(x2,1));
    
    X = [ones(size(x2,1),1),rankedX];
    sigma_hat_square = (regCoeff.SSE - sum(rankedSe.^2) + trace((X'*X)\(X'*NegGMat*X)))/(size(x,1)-2);
    finalWeights = 1./(rankedSe.^2 + sigma_hat_square);
    
    % run weighted regression
    finalRegCoeff = fitlm(rankedX,rankedY,'Weights',finalWeights);
    regCoeff = table2array(finalRegCoeff.Coefficients(2,1));
    s1 = table2array(finalRegCoeff.Coefficients(2,4));
    standardErrorCoeff = table2array(finalRegCoeff.Coefficients(2,2));
    
    % MR test
    diffData = rankedY(1:end-1) - rankedY(2:end);
    diffSimulated = simulatedData(1:end-1,:) - simulatedData(2:end,:);
    recenteredDiffSimulated = diffSimulated - repmat(diffData,1,reps);
    
    JStat = min(diffData);
    JBStat = min(recenteredDiffSimulated);
    
    p1 = mean(JBStat > JStat);
    
    % Up and Down test
    
    JStatUp = sum(abs(diffData).*(diffData>0));
    JStatDown = sum(abs(diffData).*(diffData<0));
    
    JBStatUp = sum(abs(recenteredDiffSimulated).*(recenteredDiffSimulated > 0));
    JBStatDown = sum(abs(recenteredDiffSimulated).*(recenteredDiffSimulated < 0));
    
    p2 = mean(JBStatUp > JStatUp);
    p3 = mean(JBStatDown > JStatDown);
    
    J = {'Coefficients','p-value';regCoeff,s1;0,p1;0,p2;0,p3};
    
    effectSize(1,1) = regCoeff;
    effectSize(2,1) = standardErrorCoeff;
    
    if specification == 1
        forAppendixTableExt = [regCoeff;standardErrorCoeff;p1;p2;p3];
        save([directoryForTempFiles,'forAppendixTableExt.mat'],'forAppendixTableExt');
    else
        load([directoryForTempFiles,'forAppendixTableExt.mat'])
        forAppendixTableExt(:,specification) = [regCoeff;standardErrorCoeff;p1;p2;p3];
        save([directoryForTempFiles,'forAppendixTableExt.mat'],'forAppendixTableExt');
    end
    
    
    % write data onto txt file for tablefill program. Format for table 3 in
    % main text is different.
    if sum(specification == bothIntExtSpec) >= 1
        estimatesInTableExt = [regCoeff;standardErrorCoeff;p1;p2;p3];
    else
        fid = fopen(estimatesTable,'a');
        fprintf(fid,tableLabel{4});
        fclose(fid);
        
        estimatesInTable = [regCoeff,s1];
        dlmwrite(estimatesTable,estimatesInTable,'-append','delimiter','\t','roffset',1);
        estimatesInTable = [p1;p2;p3];
        dlmwrite(estimatesTable,estimatesInTable,'-append','delimiter','\t','roffset',1);
    end
    
    
    % This excel file is for easy access to readable tables. Generates readable
    % versions of Table 3 and similar tables. Check the STATA file for
    % destination directory of these tables.
    xlswrite([directoryForOutputFiles,'Tests For Monotonicity (Extensive)',int2str(specification)],J);
    
    % Same for total margin
    rankedX = x(inverseIt);
    rankedY = y(inverseIt);
    rankedSe = se(inverseIt);
    
    reps = 10000;
    
    for i = 1:reps
        simulatedData(:,i) = normrnd(rankedY,rankedSe);
    end
    
    regCoeff = fitlm(rankedX,rankedY);
    NegGMat = eye(size(x,1)).*repmat(rankedSe,1,size(x,1));
    
    X = [ones(size(x,1),1),rankedX];
    sigma_hat_square = (regCoeff.SSE - sum(rankedSe.^2) + trace((X'*X)\X'*NegGMat*X))/(size(x,1)-2);
    finalWeights = 1./sqrt(rankedSe.^2 + sigma_hat_square);
    
    finalRegCoeff = fitlm(rankedX,rankedY,'Weights',finalWeights);
    regCoeff = table2array(finalRegCoeff.Coefficients(2,1));
    s1 = table2array(finalRegCoeff.Coefficients(2,4));
    standardErrorCoeff = table2array(finalRegCoeff.Coefficients(2,2));
    
    % MR test
    diffData = rankedY(1:end-1) - rankedY(2:end);
    diffSimulated = simulatedData(1:end-1,:) - simulatedData(2:end,:);
    recenteredDiffSimulated = diffSimulated - repmat(diffData,1,reps);
    
    JStat = min(diffData);
    JBStat = min(recenteredDiffSimulated);
    
    p1 = mean(JBStat > JStat);
    
    % Up test
    
    JStatUp = sum(abs(diffData).*(diffData>0));
    JStatDown = sum(abs(diffData).*(diffData<0));
    
    JBStatUp = sum(abs(recenteredDiffSimulated).*(recenteredDiffSimulated > 0));
    JBStatDown = sum(abs(recenteredDiffSimulated).*(recenteredDiffSimulated < 0));
    
    p2 = mean(JBStatUp > JStatUp);
    p3 = mean(JBStatDown > JStatDown);
    
    J = {'Coefficients','p-value';regCoeff,s1;0,p1;0,p2;0,p3};
    effectSize(1,2) = regCoeff;
    effectSize(2,2) = standardErrorCoeff;
    
    if specification == 1
        forAppendixTable = [regCoeff;standardErrorCoeff;p1;p2;p3];
        save([directoryForTempFiles,'forAppendixTable.mat'],'forAppendixTable');
    else
        load([directoryForTempFiles,'forAppendixTable.mat'])
        forAppendixTable(:,specification) = [regCoeff;standardErrorCoeff;p1;p2;p3];
        save([directoryForTempFiles,'forAppendixTable.mat'],'forAppendixTable');
    end
    
    if sum(specification == bothIntExtSpec) >= 1
        estimatesInTableTot = [regCoeff;standardErrorCoeff;p1;p2;p3];
        estimatesInTable = [estimatesInTableTot,estimatesInTableExt];
        fid = fopen(estimatesTable,'a');
        fprintf(fid,tableLabel{3});
        fclose(fid);
        dlmwrite(estimatesTable,estimatesInTable,'-append','delimiter','\t','roffset',1);
    else
        fid = fopen(estimatesTable,'a');
        fprintf(fid,tableLabel{3});
        fclose(fid);
        
        estimatesInTable = [regCoeff,s1];
        dlmwrite(estimatesTable,estimatesInTable,'-append','delimiter','\t','roffset',1);
        estimatesInTable = [p1;p2;p3];
        dlmwrite(estimatesTable,estimatesInTable,'-append','delimiter','\t','roffset',1);
        
    end
    
    xlswrite([directoryForOutputFiles,'Tests For Monotonicity',int2str(specification)],J);

    
    if specification == 1
        magnitudeEffect = effectSize;
        save([directoryForTempFiles,'magnitudeEffect.mat'],'magnitudeEffect');
    else
        load([directoryForTempFiles,'magnitudeEffect.mat'])
        magnitudeEffect(:,:,specification) = effectSize;
        save([directoryForTempFiles,'magnitudeEffect.mat'],'magnitudeEffect');
    end
    
    % Produce table 5 in txt file for tablefill package.
    if specification == 31
        
        fid = fopen(estimatesTable,'a');
        tableLabel = "<tab:Forward-looking-behavior-across-1>";
        fprintf(fid,tableLabel);
        fclose(fid);
        relevantSpec = [13,26:31];
        
        for i = 1:length(relevantSpec)
            forTable5 = squeeze(allData(:,:,relevantSpec(i)));
            effectMagnitude = magnitudeEffect(:,:,relevantSpec(i));
            domainOfEEYOP = [1-max(forTable5(:,2)),1-min(forTable5(:,2))];

            averageN = mean(forTable5(:,8));
            
            % Get change in EEYOP from 100 euro increase in deductible
            b = regress(1-forTable5(:,2),[ones(size(x2,1),1),forTable5(:,11)]);
            changeInEEYOP = b(2)*100;
            
            meanExp = forTable5(forTable5(:,11) == 375,[end-2, end]);
            
            reductionInUseT = (changeInEEYOP * effectMagnitude(1,2) * 100)/meanExp(2);
            reductionInUseE = (changeInEEYOP * effectMagnitude(1,1) * 100)/meanExp(1);
            
            table5 = [effectMagnitude(1,[2,1]),domainOfEEYOP,meanExp([2,1]),averageN, ...
                changeInEEYOP*100,reductionInUseT,reductionInUseE];
            dlmwrite(estimatesTable,table5,'-append','delimiter','\t','roffset',1);
            
            table5 = effectMagnitude(2,[2,1]);
            dlmwrite(estimatesTable,table5,'-append','delimiter','\t','roffset',1);
        end        
        
    end
    
    if specification == 40
        
        fid = fopen(estimatesTable,'a');
        tableLabel = "<tab:Forward-looking-behavior-across-riskscore>";
        fprintf(fid,tableLabel);
        fclose(fid);
        relevantSpec = [13,12,11,38:40];
        
        for i = 1:length(relevantSpec)
            forTable5 = squeeze(allData(:,:,relevantSpec(i)));
            effectMagnitude = magnitudeEffect(:,:,relevantSpec(i));
            domainOfEEYOP = [1-max(forTable5(:,2)),1-min(forTable5(:,2))];

            averageN = mean(forTable5(:,8));
            
            % Get change in EEYOP from 100 euro increase in deductible
            b = regress(1-forTable5(:,2),[ones(size(x2,1),1),forTable5(:,11)]);
            changeInEEYOP = b(2)*100;
            
            meanExp = forTable5(forTable5(:,11) == 375,[end-2, end]);
            
            reductionInUseT = (changeInEEYOP * effectMagnitude(1,2) * 100)/meanExp(2);
            reductionInUseE = (changeInEEYOP * effectMagnitude(1,1) * 100)/meanExp(1);
            
            table5 = [effectMagnitude(1,[2,1]),domainOfEEYOP,meanExp([2,1]),averageN, ...
                changeInEEYOP*100,reductionInUseT,reductionInUseE];
            dlmwrite(estimatesTable,table5,'-append','delimiter','\t','roffset',1);
            
            table5 = effectMagnitude(2,[2,1]);
            dlmwrite(estimatesTable,table5,'-append','delimiter','\t','roffset',1);
        end        
        
    end
    
    
    if specification == removeLastYearRobustSpec
        fid = fopen(estimatesTable,'a');
        tableLabel = "<tab:robustness-tests-monotonicity>";
        fprintf(fid,tableLabel);
        fclose(fid);
        relevantSpec = [16,35,36,42,43,34,20,41,15];
        load([directoryForTempFiles,'forAppendixTable.mat']);
        
        for i = 1:length(relevantSpec)
            estimatesToWriteToTable = forAppendixTable(:,relevantSpec(i));
            A = estimatesToWriteToTable';
            dlmwrite(estimatesTable,A,'-append','delimiter','\t','roffset',1);
        end
        
        fid = fopen(estimatesTable,'a');
        tableLabel = "<tab:appendix-tests-monotonicity>";
        fprintf(fid,tableLabel);
        fclose(fid);
        relevantSpec = [17,18,37,42,43,33,32,47,23,21,22,15,removeLastYearRobustSpec];
        relevantSpecExt = [42,43,33,32,47,23,21,22,15,removeLastYearRobustSpec];
        load([directoryForTempFiles,'forAppendixTable.mat']);
        
        for i = 1:length(relevantSpec)
            estimatesToWriteToTable = forAppendixTable(:,relevantSpec(i));
            A = estimatesToWriteToTable';
            dlmwrite(estimatesTable,A,'-append','delimiter','\t','roffset',1);
            
            checkExt = relevantSpec(i);
            
            if sum(checkExt == relevantSpecExt) >= 1
                
                indExt = find(relevantSpecExt == checkExt);
                relSpecExt = relevantSpecExt(indExt);
                
                estimatesToWriteToTable = forAppendixTableExt(:,relSpecExt);
                dlmwrite(estimatesTable,estimatesToWriteToTable', '-append','delimiter','\t','roffset',1);
                
            end
            
        end
        
    end
    
end




