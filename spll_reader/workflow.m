function retStruct = workflow( filename_prefix )

%% Clear all previous variables

% clear all;

%% Importing data from raw files

errorstr = strcat(filename_prefix,'_error')
sampleidstr = strcat(filename_prefix,'_sampleid')
taglocalstr = strcat(filename_prefix,'_taglocal')
tagrefstr = strcat(filename_prefix,'_tagref')
ystr = strcat(filename_prefix, '_y')

[errSeqid, errSrc, err] = importfile(errorstr);
[sampleSeqid,sampleSeqidSrc,sampleId] = importfile(sampleidstr);
[taglocSeqid,taglocSrc,tagloc] = importfile(taglocalstr);
[tagrefSeqid,tagrefSrc,tagref] = importfile(tagrefstr);
[ySeqid,ySrc,y] = importfile(ystr);

%% Sorting data from Helper and Main in different variables

retStruct.mainErr=err(errSrc==0);
retStruct.helperErr=err(errSrc==2);

retStruct.mainErrSeq=errSeqid(errSrc==0);
retStruct.helperErrSeq=errSeqid(errSrc==2);

clear err errSeqid errSrc;

retStruct.mainSampleId = sampleId(sampleSeqidSrc==0);
retStruct.helperSampleId = sampleId(sampleSeqidSrc==2);

retStruct.mainSampleIdSeq = sampleSeqid(sampleSeqidSrc==0);
retStruct.helperSampleIdSeq = sampleSeqid(sampleSeqidSrc==2);

clear sampleSeqid sampleSeqidSrc sampleId

retStruct.mainTagloc = tagloc(taglocSrc==0);
retStruct.helperTagloc = tagloc(taglocSrc==2);

retStruct.mainTaglocSeq = taglocSeqid(taglocSrc==0);
retStruct.helperTaglocSeq = taglocSeqid(taglocSrc==2);

clear taglocSeqid taglocSrc tagloc

retStruct.mainTagref = tagref(tagrefSrc==0);
retStruct.helperTagref = tagref(tagrefSrc==2);

retStruct.mainTagrefSeq=tagrefSeqid(tagrefSrc==0);
retStruct.helperTagrefSeq=tagrefSeqid(tagrefSrc==2);

clear tagrefSeqid tagrefSrc tagref

retStruct.mainY=y(ySrc==0);
retStruct.helperY=y(ySrc==2);

retStruct.mainYseq=ySeqid(ySrc==0);
retStruct.helperYseq=ySeqid(ySrc==2);

clear ySeqid ySrc y

%% Solving representation issues

 for (i=1:length(retStruct.helperErr))
     if (retStruct.helperErr(i)>2^24/2)
         retStruct.helperErr(i) = retStruct.helperErr(i)-2^24;
     end
 end

 for (i=1:length(retStruct.mainErr))
     if(retStruct.mainErr(i)>2^24/2)
        retStruct.mainErr(i) = retStruct.mainErr(i)-2^24;
     end
 end
 
 retStruct.mainY=max(0,retStruct.mainY);
 
 retStruct.mainY=min(65535,retStruct.mainY);
 
 retStruct.helperY=max(0,retStruct.helperY);
 retStruct.helperY=min(65535,retStruct.helperY);
 
 %% Removing glitches
 
 retStruct.cleanmainY=retStruct.mainY;
 
 upperThreshold = mean(retStruct.cleanmainY)+5*sqrt(var(retStruct.cleanmainY))
 lowerThreshold = mean(retStruct.cleanmainY)-5*sqrt(var(retStruct.cleanmainY))

 for(i=1:length(retStruct.cleanmainY))
    if(retStruct.cleanmainY(i)>upperThreshold)
        retStruct.cleanmainY(i) = retStruct.cleanmainY(i-1);
    end
    if(retStruct.cleanmainY(i)<lowerThreshold)
        retStruct.cleanmainY(i) = retStruct.cleanmainY(i-1);
    end
 end

 retStruct.mainErr(abs(retStruct.mainErr)>10000)=0;
 retStruct.helperErr(abs(retStruct.helperErr)>10000)=0;

% %% Allan variance 
% 
  retStruct.N=14;
  retStruct.fin=62.5e6;
  retStruct.fdmtd=(2^retStruct.N)/(2^retStruct.N+1)*retStruct.fin;
  retStruct.fs=retStruct.fin-retStruct.fdmtd;
 
  structmainY.phase=4*retStruct.cleanmainY;
  structmainY.rate=retStruct.fs;
 
  structmainErr.phase=retStruct.mainErr;
  structmainErr.rate=retStruct.fs;
 
  structhelperY.phase=4*retStruct.helperY;
  structhelperY.rate=retStruct.fs;
 
  structhelperErr.phase=retStruct.helperErr;
  structhelperErr.rate=retStruct.fs;
 
  retStruct.tau=[1 2 3 4 5 6 7 8 10 20 30 40 50 60 70 80 100 200 300 400 700 1e3 2e3 4e3 7e3 1e4 2e4 4e4 7e4 1e5 2e5 4e5 7e5 1e6 2e6 4e6 7e6 1e7 2e7 4e7 7e7 1e8 2e8 4e8 7e8].*(1/retStruct.fs);
 
%  [allanmainY s errorb tauO] =allan(structmainY,tau,'Main PLL output',2);
%  allanmainErr=allan(structmainErr,tau,'Main PLL error');
%  allanhelperY=allan(structhelperY,tau,'Helper PLL output');
%  allanhelperErr=allan(structhelperErr,tau,'Helper PLL error');
% 
%  figure;
%  
%  plot(tauO,allanmainY);
%  hold on;
%  plot(tauO,allanmainErr);
%  plot(tauO,allanhelperY);
%  plot(tauO,allanhelperErr);
%  legend('Main out','Main error','Helper out','Helper error');
%  set(gca, 'YScale', 'log');
%  set(gca, 'XScale', 'log');
%  xlabel('Tiempo \tau (s)');
%  ylabel('Allan var \sigma_{y}(\tau)');
%  grid on
%  grid minor
%  hold off;
%  
  
