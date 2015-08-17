function ArduinoDataReader(hObject,eventdata, hFigure)
persistent state iTrial cue

handles = guidata(hFigure);

if isempty(state); state = 9; end;
if state==9; iTrial=1; end;

try
    while handles.arduino.BytesAvailable > 0
        str = fscanf(handles.arduino,'%s');
        set(handles.eventText,'String',str);
        str = strsplit(str);
        nStr = length(str);
        
        for iStr = 1:nStr
            if isstrprop(str{iStr}(1),'digit')
                s = sscanf(str{iStr},'%lu%c%d');
                time = s(1);
                event = char(s(2));
                eventData = s(3);

                switch event
                    case 'b' % state 0: baseline
                        state = 0;
                        iTrial = eventData;

                        handles.data.stateTime(iTrial,1) = time;
                        
                        if iTrial<10
                            yRange = 10;
                        else
                            yRange = iTrial;
                        end
                        set(handles.aRaster,'YLim',[yRange-10 yRange], ...
                            'YTick',(yRange-10):yRange,...
                            'YTickLabel',{(yRange-10),[],[],[],[],[],[],[],[],[],yRange});
                        set(handles.bar.s3,'Visible','off');
                        set(handles.bar.s0,'Visible','on');
                        set(handles.iTrial,'String',num2str(iTrial));
                        set(handles.cue0,'BackgroundColor','w');
                        set(handles.cue1,'BackgroundColor','w');
                        set(handles.cue2,'BackgroundColor','w');
                        set(handles.cue3,'BackgroundColor','w');
                        set(handles.reward0,'BackgroundColor','w');
                        set(handles.reward1,'BackgroundColor','w');
                        set(handles.reward2,'BackgroundColor','w');
                        set(handles.reward3,'BackgroundColor','w');
                        set(handles.omit0,'BackgroundColor','w');
                        set(handles.omit1,'BackgroundColor','w');
                        set(handles.omit2,'BackgroundColor','w');
                        set(handles.omit3,'BackgroundColor','w');
                        
                        % Plot iti end time
                        if iTrial > 1
                            endTime = (time - handles.data.stateTime(iTrial-1,1))/1000000;
                            plot(handles.aRaster,[endTime endTime],[iTrial-2 iTrial-1],'LineWidth',1,'Color',[0.8 0 0]);
                        end

                    case 'c' % state 1: cue and delay
                        state = 1;
                        cue = eventData;

                        handles.data.stateTime(iTrial,2) = time;
                        handles.data.cue(iTrial) = eventData;

                        set(handles.bar.s0,'Visible','off');
                        set(handles.bar.s1,'Visible','on');
                        
                        nCue0 = str2double(get(handles.cue0,'String'));
                        nCue1 = str2double(get(handles.cue1,'String'));
                        nCue2 = str2double(get(handles.cue2,'String'));
                        nCue3 = str2double(get(handles.cue3,'String'));
                        
                        if cue == 0 
                            nCue0 = nCue0 + 1;
                            set(handles.cue0,'String',num2str(nCue0));
                            set(handles.cue0,'BackgroundColor','y');
                        elseif cue == 1
                            nCue1 = nCue1 + 1;
                            set(handles.cue1,'String',num2str(nCue1));
                            set(handles.cue1,'BackgroundColor','y');
                        elseif cue == 2
                            nCue2 = nCue2 + 1;
                            set(handles.cue2,'String',num2str(nCue2));
                            set(handles.cue2,'BackgroundColor','y');
                        elseif cue == 3
                            nCue3 = nCue3 + 1;
                            set(handles.cue3,'String',num2str(nCue3));
                            set(handles.cue3,'BackgroundColor','y');
                        end
                        
                    case 'd' % state 2: delay
                        state = 2;
                        
                        handles.data.stateTime(iTrial,3) = time;
                        set(handles.bar.s1,'Visible','off');
                        set(handles.bar.s2,'Visible','on');

                    case 'r' % state 3: reward
                        state = 3;
                        reward = eventData;
                        
                        set(handles.bar.s2,'Visible','off');
                        set(handles.bar.s3,'Visible','on');
                        handles.data.stateTime(iTrial, 4) = time;
                        handles.data.reward(iTrial) = eventData;
                        
                        if reward == 1
                            nReward = str2double(get(handles.nReward,'String'));
                            set(handles.nReward,'String',num2str(nReward+1));
                            if cue == 0
                                nReward0 = str2double(get(handles.reward0,'String'));
                                set(handles.reward0,'String',num2str(nReward0+1));
                                set(handles.reward0,'BackgroundColor','c');
                            elseif cue == 1
                                nReward1 = str2double(get(handles.reward1,'String'));
                                set(handles.reward1,'String',num2str(nReward1+1));
                                set(handles.reward1,'BackgroundColor','c');
                            elseif cue == 2
                                nReward2 = str2double(get(handles.reward2,'String'));
                                set(handles.reward2,'String',num2str(nReward2+1));
                                set(handles.reward2,'BackgroundColor','c');
                            elseif cue == 3
                                nReward3 = str2double(get(handles.reward3,'String'));
                                set(handles.reward3,'String',num2str(nReward3+1));
                                set(handles.reward3,'BackgroundColor','c');
                            end
                            
                            % Plot valve output
                            valveTime = (time - handles.data.stateTime(iTrial,1))/1000000;
                            plot(handles.aRaster,[valveTime valveTime],[iTrial-1 iTrial],'LineWidth',2,'Color',[0 1 1]);
                        end
                        

                    case 'i' % state 4: iti
                        state = 4;
                        omit = eventData;

                        handles.data.stateTime(iTrial, 5) = time;
                        
                        nCue0 = str2double(get(handles.cue0,'String'));
                        nCue1 = str2double(get(handles.cue1,'String'));
                        nCue2 = str2double(get(handles.cue2,'String'));
                        nCue3 = str2double(get(handles.cue3,'String'));
                        nOmit0 = str2double(get(handles.omit0,'String'));
                        nOmit1 = str2double(get(handles.omit1,'String'));
                        nOmit2 = str2double(get(handles.omit2,'String'));
                        nOmit3 = str2double(get(handles.omit3,'String'));
                        if omit==0
                            if cue == 0
                                nOmit0 = nOmit0 + 1;
                                set(handles.omit0,'String',num2str(nOmit0));
                                set(handles.omit0,'BackgroundColor','m');
                            elseif cue == 1
                                nOmit1 = nOmit1 + 1;
                                set(handles.omit1,'String',num2str(nOmit1));
                                set(handles.omit1,'BackgroundColor','m');
                            elseif cue == 2
                                nOmit2 = nOmit2 + 1;
                                set(handles.omit2,'String',num2str(nOmit2));
                                set(handles.omit2,'BackgroundColor','m');
                            elseif cue == 3
                                nOmit3 = nOmit3 + 1;
                                set(handles.omit3,'String',num2str(nOmit3));
                                set(handles.omit3,'BackgroundColor','m');
                            end
                        end
                        if sum(nCue0+nCue2)>0 && sum(nCue1+nCue3)>0
                            pChi = chisq2(nOmit0+nOmit2,nOmit1+nOmit3,(nCue0+nCue2-nOmit0-nOmit2),(nCue1+nCue3-nOmit1-nOmit3));
                            set(handles.pChi,'String',num2str(pChi,'%.3f'));
                            if pChi <= 0.05
                                set(handles.pChi,'BackgroundColor','y');
                            else
                                set(handles.pChi,'BackgroundColor','w');
                            end                            
                        end

                        try
                            % Plot lick number histogram
                            lickNum = handles.data.lickNum(1:iTrial);
                            cueData = handles.data.cue(1:iTrial);
                            lickMean = zeros(1,4);
                            lickSem = zeros(1,4);

                            barColor = {[0 0 0.8],[0.8 0 0],[0 0.8 0],[0 0.5 0.5]};
                            cla(handles.aBar);
                            hold(handles.aBar,'on');
                            for iCue = 1:4
                                if isempty(cueData==(iCue-1)); continue; end;
                                lickMean(iCue) = mean(lickNum(cueData==(iCue-1)));
                                lickSem(iCue) = std(lickNum(cueData==(iCue-1)))/sqrt(sum(cueData==(iCue-1)));
                                bar(handles.aBar,iCue,lickMean(iCue),'LineStyle','none','FaceColor',barColor{iCue},'BarWidth',0.5);
                            end
                            yRange = ceil(max(lickMean+lickSem)*1.1);
                            if yRange==0; yRange = 1; end;
                            h = errorbar(handles.aBar,1:4,lickMean,lickSem,'Color','k','LineWidth',1);
                            h2 = get(h,'Children');
                            set(h2(1),'LineStyle','none');
                            set(handles.aBar,'TickDir','out','FontSize',8, ...
                                'XLim',[0.5 4+0.5],'XTick',1:4,'XTickLabel',{'A','B','C','D'}, ...
                                'YLim',[0 yRange],'YTick',[0 yRange]);
                            hold(handles.aBar,'off');

                            % T-test
                            if ~isempty(sum(cueData==0)) && ~isempty(sum(cueData==1))
                                [~,pTtest] = ttest2([lickNum(cueData==0);lickNum(cueData==2)],[lickNum(cueData==1);lickNum(cueData==3)]);
                                set(handles.pTtest,'String',num2str(pTtest,'%.3f'));
                            end
                            if pTtest <= 0.05
                                set(handles.pTtest,'BackgroundColor','y');
                            else
                                set(handles.pTtest,'BackgroundColor','w');
                            end
                        end
                        
                    case 'l'
                        handles.data.lickTime = [handles.data.lickTime; time iTrial state eventData];
                        if ~isempty(handles.data.stateTime(iTrial,1)) && handles.data.stateTime(iTrial,1)~=0
                            lickTime = (time - handles.data.stateTime(iTrial,1))/1000000;
                        else
                            lickTime = (time - 5000000)/1000000;
                        end
                        
                        if state == 2
                            handles.data.lickNum(iTrial) = handles.data.lickNum(iTrial) + 1;
                        end
                        
                        try
                            plot(handles.aRaster,[lickTime lickTime],[iTrial-1 iTrial],'LineWidth',1,'Color','k');
                        end

                    case 'e' % state 9: end trial
                        state = 9;
                        stop(handles.timer);

                        nTrial = iTrial;
                        nReward = str2double(get(handles.nReward,'String'));
                        stateTime = handles.data.stateTime(1:nTrial,:);
                        odorCue = handles.data.cue(1:nTrial);
                        waterReward = handles.data.reward(1:nTrial);
                        lickNum = handles.data.lickNum(1:nTrial);
                        lickTime = handles.data.lickTime;

                        save(handles.fileName,'nTrial','nReward','stateTime','odorCue','waterReward','lickNum','lickTime');
                        
                        set(handles.stopButton, 'Enable', 'off');
                        set(handles.mouseName, 'Enable', 'on');
                        set(handles.nTrial, 'Enable', 'on');
                        set(handles.trialType, 'Enable', 'on');
                        set(handles.startButton, 'Enable', 'on');
                        set(handles.valve, 'Enable', 'on');
                end
            end
        end
    end
    elapsedTime = toc;
    minute = floor(elapsedTime/60);
    second = mod(elapsedTime,60);
    set(handles.duration,'Str',[num2str(minute,'%d'),':',num2str(second,'%03.1f')]);
    guidata(hFigure,handles);
catch err
    disp(err.message);
end