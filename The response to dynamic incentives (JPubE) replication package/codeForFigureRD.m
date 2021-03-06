% This code produces figures from data generated by paper forward-looking
% reduced form. This program is called from within the do-file. Only the 
% working directories need to be changed (must be consistent with the ones
% declared in STATA).

% Please change the input and output folders in the lines
% where the directories are defined. 

if exist('T:\HealthCost','file') >= 2
   beginDirectory = ['T:\'];
else
    beginDirectory = ['P:\'];
end

% declare temp directory. This should be the same one as in the STATA file!
directoryForTempFiles = [beginDirectory,'HealthCost\analysis\temp\'];
directoryForOutputFiles = [beginDirectory,'HealthCost\analysis\output\forward looking reduced form\'];
directoryForOutputFigures = [beginDirectory,'HealthCost\analysis\output\forward looking reduced form\figures\'];

% First get the RD figures. These are called from STATA itself. Make sure
% the temp folder defined here is the same as defined in STATA. 
if exist([directoryForTempFiles,'figureForRD.xls'],'file') == 2
    x = xlsread([directoryForTempFiles,'figureForRD.xls']);
    rel_day = x(:,3);
    [~, lastRelDay] = max(rel_day);
    [~, firstRelDay] = min(rel_day); 
    spanOfObs = firstRelDay:lastRelDay;
    rel_day = rel_day(spanOfObs,:);
    
    mean_spending = x(spanOfObs,4);
    spending_fit = x(spanOfObs,5);
    
    isDonut = x(spanOfObs,end);
    daysInFirstYear = x(spanOfObs,end-1);
    day = x(spanOfObs,2);
    
    
    beforeDonutMeanSpending = mean_spending(rel_day < 0);
    afterDonutMeanSpending = mean_spending(rel_day >= 0);
    beforeDonutFit = spending_fit(rel_day < 0);
    afterDonutFit = spending_fit(rel_day >= 0);
    omittedMeanSpending = mean_spending(isnan(rel_day));
    
    if x(1,1) == 2008 || x(1,1) == 2012
        relDayBeforeDonut = day(rel_day < 0) - 366;
        relDayAfterDonut = day(rel_day >= 0) - 366;
        omittedDays = day(isnan(rel_day)) - 366;
    else
        relDayBeforeDonut = day(rel_day < 0) - 365;
        relDayAfterDonut = day(rel_day >= 0) - 365;
        omittedDays = day(isnan(rel_day)) - 365;
    end
    
    distanceToDonutFromT = relDayBeforeDonut(end);
    distanceToDonutFromTPlus1 = relDayAfterDonut(1);
    
    h(1) = plot([relDayBeforeDonut;relDayAfterDonut],[beforeDonutMeanSpending;afterDonutMeanSpending],'.','MarkerSize',15);
    hold on
    h(2) = plot([relDayBeforeDonut],[beforeDonutFit],'Color',[0.8500 0.3250 0.0980]);
    h(3) = plot(relDayAfterDonut,afterDonutFit,'Color',[0.8500 0.3250 0.0980]);
    ax = gca;
    ax.YLim = [0 max(mean_spending)*1.2];
    h(4) = plot([0 0],[0 max(mean_spending)*1.2],'--','Color',[0.3 0.3 0.3]);
    h(5) = plot([distanceToDonutFromT distanceToDonutFromT],[0 max(mean_spending)*1.2],'k');
    h(6) = plot([distanceToDonutFromTPlus1 distanceToDonutFromTPlus1],[0 max(mean_spending)*1.2],'k');
    ax.XLim = [-50 40];
    ylabel('Mean daily exp. (PC)')
    
    firstOct = ['1Oct',int2str(x(1,1))];
    firstNov = ['1Nov',int2str(x(1,1))];
    firstDec = ['1Dec',int2str(x(1,1))];
    firstDay = ['1Jan',int2str(x(end,1))];
    firstFeb = ['1Feb',int2str(x(end,1))];
    firstMar = ['1Mar',int2str(x(end,1))];
    firstApr = ['1Apr',int2str(x(end,1))];
    firstJan = ['1Jan',int2str(x(end,1))];
    
    xticks([ -31 distanceToDonutFromT 0 distanceToDonutFromTPlus1 32]);
    xticklabels({firstDec,'T',firstJan,'t = 1',firstFeb});
    
    legend([h(1) h(2)], {'daily exp (PC)','LLR'},'Location','northeast')
   
    ax.FontSize = 8;
    fig = gcf;
    fig.PaperOrientation = 'landscape';
    fig.PaperUnits = 'inches';
    fig.PaperPosition = [0 0 7 3.2];
    fig.PaperSize = [7 3.2];
    print([directoryForTempFiles,'RD Figure'],'-dpdf');
    
    h(7) = plot(omittedDays, omittedMeanSpending,'o','Color',[0.3 0.3 0.3]); 
    legend([h(1) h(2) h(7)], {'daily exp (PC)','LLR','omitted days'},'Location','northeast')
    print([directoryForTempFiles,'RD Figure (with omitted days)'], '-dpdf');
    
end

hold off

if exist([directoryForOutputFiles,'EEYOP.xlsx'],'file') == 2
    EEYOP = xlsread([directoryForOutputFiles,'EEYOP.xlsx']);
    EEYOPOrg = xlsread([directoryForOutputFiles,'EEYOPOrg.xlsx']);
    colorForHighDed = [0, 0.4470, 0.7410];
    colorForLowDed = [0.9290, 0.6940, 0.1250];
    h(1) = plot(EEYOP(:,1),'LineWidth',1.2,'Color',colorForHighDed,'Marker','d','MarkerIndices',1:25:365);
    hold on
    h(2) = plot(EEYOP(:,2),'LineWidth',1.2,'Color',colorForLowDed,'Marker','o','MarkerIndices',1:25:365);
    h(3) = plot(EEYOPOrg(:,1),'LineWidth',1.2,'Color',colorForHighDed,'Marker','d','LineStyle','--','MarkerIndices',1:25:365);
    h(4) = plot(EEYOPOrg(:,2),'LineWidth',1.2,'Color',colorForLowDed,'Marker','o','LineStyle','--','MarkerIndices',1:25:365);
    xlabel('days in a year (t)','Interpreter','latex')
    ylabel('$$ \bar{P}^e_{t,y''} $$','Interpreter','latex','FontSize',15)
    hold on
    legend([h(1) h(3) h(2) h(4)], {'below median riskscore (475 deductible)','below median riskscore (375 deductible)',...
        'above median riskscore (475 deductible)', 'above median riskscore (375 deductible)'},'Location','southeast','Interpreter','latex')
    xticks([1 91 182 274 365])
    xticklabels({'1Jan (t = 1)','1Apr','1Jul','1Oct','31Dec (t = T)'});
    yticks([0:0.2:1])
    ax = gca;
    set(ax, 'TickLabelInterpreter','latex')
    ax.FontSize = 10;
    ax.XLim = [0,365];
    ax.YLim = [0,1];
    fig = gcf;
    fig.PaperOrientation = 'landscape';
    fig.PaperUnits = 'inches';
    fig.PaperPosition = [0 0 7 5];
    fig.PaperSize = [7 5];
    print([directoryForOutputFigures,'changeInEEYOPFigure'],'-dpdf');
    
    hold off
    shareOfIndAbove = xlsread([directoryForOutputFiles,'shareOfIndAbove.xlsx']);
    shareOfIndAboveOrg = xlsread([directoryForOutputFiles,'shareOfIndAboveOrg.xlsx']);
    colorForHighDed = [0, 0.4470, 0.7410];
    colorForLowDed = [0.9290, 0.6940, 0.1250];
    h(1) = plot(1-shareOfIndAbove(:,1),'LineWidth',1.2,'Color',colorForHighDed,'Marker','d','MarkerIndices',1:25:365);
    hold on
    h(2) = plot(1-shareOfIndAbove(:,2),'LineWidth',1.2,'Color',colorForLowDed,'Marker','o','MarkerIndices',1:25:365);
    h(3) = plot(1-shareOfIndAboveOrg(:,1),'LineWidth',1.2,'Color',colorForHighDed,'Marker','d','LineStyle','--','MarkerIndices',1:25:365);
    h(4) = plot(1-shareOfIndAboveOrg(:,2),'LineWidth',1.2,'Color',colorForLowDed,'Marker','o','LineStyle','--','MarkerIndices',1:25:365);
    xlabel('days in a year (t)','Interpreter','latex')
    ylabel('$$ \bar{P}^c_{t,y''} $$','Interpreter','latex','FontSize',15)
    legend([h(1) h(3) h(2) h(4)], {'below median riskscore (475 deductible)','below median riskscore (375 deductible)',...
        'above median riskscore (475 deductible)', 'above median riskscore (375 deductible)'},'Location','southwest','Interpreter','latex')
    ax = gca;
    ax.FontSize = 10;
    ax.XLim = [0,365];
    ax.YLim = [0,1];
    xticks([1 91 182 274 365])
    xticklabels({'1Jan (t = 1)','1Apr','1Jul','1Oct','31Dec (t = T)'});
    set(ax, 'TickLabelInterpreter','latex')
    fig = gcf;
    fig.PaperOrientation = 'landscape';
    fig.PaperUnits = 'inches';
    fig.PaperPosition = [0 0 7 5];
    fig.PaperSize = [7 5];
    print([directoryForOutputFigures,'shareOfIndividualsFigure'],'-dpdf');
end

hold off 

%{
if exist([beginDirectory,'HealthCost\build\output\priceComparison.xls'],'file') == 2
    differentPrices = xlsread([beginDirectory,'HealthCost\build\output\priceComparison.xls']);
    % first column is the true P^E. t is months here. (delta is monthly) 
    % even columns are prices in our model, for different beta and delta
    % combinations. 2nd => delta = 0.85, beta = 1; 4th => delta = 0.995,
    % beta = 1; 6th => delta = 1, beta = 1; 8th => delta = 0.85, beta = 0.5
    % and so on.
    % odd columns (except the first) are prices in the Ellis model with the
    % same beta-delta pattern as above. 3rd => delta = 0.85, beta = 1; 5th
    % => delta = 0.995, beta = 1....
    
    figure (3)
    hold on
    ax = gca;
    ax.XLim = [0.2,0.8];
    ax.YLim = [0.2,0.9];
    deltaLegend = {'\beta = 1;\delta = 0.85';'\beta = 1;\delta = 0.995';'\beta = 1;\delta = 1';
        '\beta = 0.5;\delta = 0.85';'\beta = 0.5;\delta = 0.995';'\beta = 0.5;\delta = 1';'y = x'};
    lineStyles = {'-.d';'-.h';'--o';'--+';'--d';'--h'};
    
    for i = 1:6
        plot(differentPrices(:,1),differentPrices(:,i*2),cell2mat(lineStyles(i)))
    end
    h = refline(1,0);
    h.Color = [0.4;0.4;0.4];
    h.LineStyle = '--';
    legend(deltaLegend,'Location','southeast')
    xlabel('P^E_1')
    ylabel('Price in our model')
    
    fig = gcf;
    fig.PaperOrientation = 'landscape';
    fig.PaperUnits = 'inches';
    fig.PaperPosition = [0 0 5 7];
    fig.PaperSize = [5 7];
    print([beginDirectory,'HealthCost\analysis\output\forward looking reduced form\figures\priceComparison'],'-dpdf');
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % can do the same for the Ellis price
    
    figure (4)
    hold on
    ax = gca;
    ax.XLim = [0,0.4];
    ax.YLim = [0,0.4];
    
    deltaLegend = {'\beta = 1;\delta = 0.85';'\beta = 1;\delta = 0.995';'\beta = 1;\delta = 1';
        '\beta = 0.5;\delta = 0.85';'\beta = 0.5;\delta = 0.995';'\beta = 0.5;\delta = 1';'y = x'};
    lineStyles = {'-.d';'-.h';'--o';'--+';'--d';'--h'};
    
    for i = 1:6
        plot(differentPrices(:,1),differentPrices(:,i*2+1),cell2mat(lineStyles(i)))
    end
    
    h = refline(1,0);
    h.Color = [0.4;0.4;0.4];
    h.LineStyle = '--';
    legend(deltaLegend,'Location','northwest')
    xlabel('P^E_1')
    ylabel('Price in Ellis model')
    
    fig = gcf;
    fig.PaperOrientation = 'landscape';
    fig.PaperUnits = 'inches';
    fig.PaperPosition = [0 0 5 7];
    fig.PaperSize = [5 7];
    print([beginDirectory,'HealthCost\analysis\output\forward looking reduced form\figures\priceComparisonEllis'],'-dpdf');
end
%}