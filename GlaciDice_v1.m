% init
clear
close all hidden

%% TO DO
% create dialog



%% load constants
if exist('consts.mat', 'file') ~= 2 % create if needed
    constants
end
load('consts.mat')
density=consts.rho; % rock density
densityice=consts.rhoice; % ice density

%% Input parameters
    
% Allow user to change model parameters
reset_default_values=1;
while reset_default_values==1
    Questions = {...
        'Boulder size minimum (cm):',...
        'Boulder size maximum (cm):'...
        'Last deglaciation minimum (years):',...
        'Last deglaciation maximum (years):',...
        'Ice depth during glaciations (m):',...
        'Nuclide mass (3, 10, 14, 21, 26, 36):',...
        'Number of dices to roll (# of models):',...
        'Reset default values? (0=false, 1=true)'...
        };
    numinput=[consts.boulder_size,...
        consts.last_deglaciation,...
        consts.ice_depth,...
        consts.nuclide,...
        consts.number_of_models,...
        0];
    dlgtitle = 'Model parameters';
    dims = 1;
    definput =cellstr(num2str(numinput(:)));
    answers = inputdlg(Questions,dlgtitle,dims,definput);
    if ~isempty(answers)
        % convert to numbers
        numanswers=cellfun(@str2num,answers)';
        consts.boulder_size=numanswers(1:2);
        consts.last_deglaciation=numanswers(3:4);
        consts.ice_depth=numanswers(5);
        consts.nuclide=numanswers(6);
        consts.number_of_models=numanswers(7);
        reset_default_values=numanswers(8);
        if reset_default_values~=0
            constants
            load('consts.mat')
        end
    end
end
save('consts.mat','consts','-v7')

boulder_size=consts.boulder_size; % side of the diced boulders in cm
last_deglaciation=consts.last_deglaciation; % years (range for last deglaciation)
ice_depth=consts.ice_depth; % m (deph under ice during glaciations)
nuclide=consts.nuclide; % the mass of the cosmonuclide
number_of_models=consts.number_of_models;


%% shielding functions
side_shielding = @(z,L) 0.5+0.5*exp(-z.*consts.rho./(2*L*0.8));
bottom_shielding= @(z,L) exp(-z.*consts.rho./(L*1.16));

%% dice position functions
is_side = @ (top_side,this_side) (top_side+this_side~=7 & top_side~=this_side);
is_bottom = @ (top_side,this_side) (top_side+this_side==7);

%% load climatecurves
make_climatecurves % NGRIP+ data (see NUNAIT paper)
close all hidden % close plot generated by make_climatecurves.m
load climatecurves.mat
% get last deglaciation 
climatecurves.lastdeg=0.*climatecurves.age;
for step=1:numel(climatecurves.age)
    climatecurves.lastdeg(step)=min(climatecurves.age(climatecurves.d18O>=climatecurves.d18O(step)));
end


%% Calculate d18O thresholds
selection= climatecurves.lastdeg<max(last_deglaciation) &...
    climatecurves.lastdeg>min(last_deglaciation);
if sum(selection)>0
    d18O_thresholds=[min(climatecurves.d18O(selection)) max(climatecurves.d18O(selection))];
else % if no results, get the closest d18O value
    distance=abs(climatecurves.lastdeg-mean(last_deglaciation));
    selection=find(distance==min(distance),1,'first');
    d18O_thresholds=[1 1]*climatecurves.d18O(selection);
end
d18O_values=climatecurves.d18O(selection);


%% Get prodution rate parameters
mucont= muon_contribution(NaN,NaN,nuclide); % use global average for muon contributions
P=[consts.Psp(consts.nuclides==nuclide)*(1-mucont.value),consts.Pmu(consts.nuclides==nuclide,:)*mucont.value];
L=[consts.Lsp,consts.Lmu];
l=consts.l(consts.nuclides==nuclide);
l=l+log(2)/(1000*4543e6); % add a small decay (1000 times earth age) to simplify math with stable isotopes
apparent_age=@(concentration) log(1-min(max(concentration,0)*l,1))/(-l); % a

%% Define models to run
d18O_model=d18O_values(ceil(rand(1,number_of_models)*numel(d18O_values)));
nmodels=numel(d18O_model);

%% Make input matrices 
Production_rates=repmat(P,nmodels,1);
Attenuation_lengths=repmat(L,nmodels,1);
decay_constant=repmat(l,nmodels,1);

[sample_index,p_index,climate_index]=ndgrid(1:numel(d18O_model),1:size(Production_rates,2),1:numel(climatecurves.age));

% Dimensions:
% 1 samples: d18O_model
% 2 production rates
% 3 climate curves

T=climatecurves.age(climate_index); 
D=d18O_model(sample_index); % thresholds
MC=D.*0+mucont.value;
dMC=D.*0+mucont.uncert;
lmatrix=D.*0+l;
E=0; % glacial erosion
W=0; % interglacial weathering
P=repmat(Production_rates,[1,1,numel(climatecurves.age)]);
L=repmat(Attenuation_lengths,[1,1,numel(climatecurves.age)]);

% Define step lengths (years)
climatecurves.dage=diff([climatecurves.age,4543e6]);
dT=climatecurves.dage(climate_index);

% glaciated times
G=(climatecurves.d18O(climate_index)>D);

% dice positions and BOULDER SIZES
DICEPOS=0.*G;
BOULDERSIZE=0.*G;
% randomize dice
random_dicepos=ceil(rand(size(G(:,1,:)))*6);
for model=1:nmodels
    BOULDERSIZE(model,:,:)=min(boulder_size)+range(boulder_size)*rand;
    % reditribute final positions #1 (1/3) #2-#5 (1/3/4) #6 (1/3)
    % this forces reducing #1 in side position than a random dice throw
    posibilities=[1 1 1 1 2 3 4 5 6 6 6 6];
    random_dicepos(model,1,1)=posibilities(ceil(rand*numel(posibilities)));
    % do not move if ~G
    for step=2:size(G,3)
       random_dicepos(model,1,step)=...
           (G(model,1,step)==0)*random_dicepos(model,1,step-1)+...
           (G(model,1,step)==1)*random_dicepos(model,1,step);
       % there must be a faster way of doing this by using diff in the third dimension...
    end
    
    DICEPOS(model,:,:)=repmat(random_dicepos(model,:,:),[1,size(G,2),1]);
end

% all respect #1
ISSIDE=is_side(DICEPOS(:,:,:),1);
ISBOTTOM=is_bottom(DICEPOS(:,:,:),1);
ISTOP=(~ISSIDE & ~ISBOTTOM);

% shielding of side #1
SHIELDING=1*ISTOP+...
    side_shielding(BOULDERSIZE,L).*ISSIDE+...
    bottom_shielding(BOULDERSIZE,L).*ISBOTTOM;

% check if it makes sense (testing only)
% hold on
% hist(DICEPOS(:),[1:6])
% plot([0.5,6.5],[1,1]*numel(DICEPOS)/6,'-r')
% title('All ages')
% xlabel('Dice top position')
% ylabel('N models * N production paths * N ages')
% 
% figure 
% hold on
% hist(DICEPOS(:,1,1),[1:6])
% plot([0.5,6.5],[1,1]*numel(DICEPOS(:,1,1))/3,'-r')
% plot([0.5,6.5],[1,1]*numel(DICEPOS(:,1,1))/3/4,'-r')
% title('Today')
% xlabel('Dice top position')
% ylabel('N models')

% erosion during each step (from NUNAIT)
Zi=E.*dT.*G+W.*dT.*~G;

% depths (from NUNAIT)
Z=cumsum(Zi,numel(size(Zi)))-Zi;

% depths under ice
ZICE=G.*ice_depth*100; % cm

%% Accumulation model
Cii=...
    P.*SHIELDING./(lmatrix+W.*density./L).*...
    exp(-(Z.*density+ZICE.*densityice)./L).*...
    (1-exp(-(lmatrix+W.*density./L).*dT)).*...
    exp(-lmatrix.*T);

% Sum for all production rates
Ci=sum(Cii,numel(size(Cii))-1);

% Cumulative sum for each exhumation age
C=cumsum(Ci,numel(size(Ci)));
istop=ISTOP(:,1,1);
isbottom=ISBOTTOM(:,1,1);
isside=ISSIDE(:,1,1);


% Apparent Surface Exposure Age of the models
ASEA_models=apparent_age(permute(C,[1,3,2])); % a
ASEA_models_top=apparent_age(permute(C(istop,:,:),[1,3,2])); % a
ASEA_models_side=apparent_age(permute(C(isside,:,:),[1,3,2])); % a
ASEA_models_bottom=apparent_age(permute(C(isbottom,:,:),[1,3,2])); % a

% Exhumation ages
EX_models=[climatecurves.age(2:end),4543e6];

% %% Calcualte exhumation ages for the ASEAs
% max_ref=ASEA_models_max+[1:numel(ASEA_models_max)]/numel(ASEA_models_max);
% min_ref=ASEA_models_min-[1:numel(ASEA_models_min)]/numel(ASEA_models_min);
% for sample=1:numel(ASEA)
%     ASEAi=ASEA(sample);
%     max_ex_age(sample)=interp1(max_ref,EX_models,ASEAi);
%     min_ex_age(sample)=interp1(min_ref,EX_models,ASEAi);
% end

%% Text output
disp(' ')
disp('---------------------------------------')
disp('GlaciDice')
disp('Glaciers do play dice with the boulders')
disp('Angel Rodes, 2022')
disp('---------------------------------------')
% disp(['ASEA' char(9)...
%     'Exhumation age range'])
% disp(['(' consts.nuclidesstring{consts.nuclides==nuclide} ' a)' char(9)...
%     '(a)'])
% for sample=1:numel(ASEA)
%     disp([num2str(round(ASEA(sample))) char(9)...
%         num2str(round(min_ex_age(sample))) '-' num2str(round(max_ex_age(sample)))])
% end
% disp(' ')

%% Plots

x_limits=[1e3 1e7];

% Plot model
figure('Units','normalized','Position',[0 0 0.5 1])
subplot(5,1,[1 4])
hold on
plot([1 2],[1 1]*d18O_thresholds(1),'-b','LineWidth',2) % for legend
plot([1 2],[1 1]*d18O_thresholds(1),'-g','LineWidth',2) % for legend
plot(climatecurves.age,climatecurves.d18O,'-','Color','k','LineWidth',2) % plot d18O curve
legend(['Glaciated (' num2str(ice_depth) ' m of ice)'],...
    ['Exposed'],...
    climatecurves.ver,...
    'Location','southeast')
legend('AutoUpdate','off')
for h=d18O_model
    glaciated=climatecurves.age(climatecurves.d18O>=h);
    plot(glaciated,glaciated.*0+h,'.b')
    deglaciated=climatecurves.age(climatecurves.d18O<=h);
    plot(deglaciated,deglaciated.*0+h,'.g')
    last_exp=[1 climatecurves.age(find(climatecurves.d18O>h,1,'first')-1)];
    plot(last_exp,last_exp.*0+h,'-g','LineWidth',2)
end
plot(climatecurves.age,climatecurves.d18O,'-','Color','k','LineWidth',2) % plot d18O curve again
ylabel('\delta^{18}O')
set(gca, 'Xdir', 'reverse')
% xlabel('Age (a)')
set(gca, 'XScale', 'log')
xlim(x_limits)
box on 
grid on
title('GlaciDice model')

subplot(5,1,5)
hold on
COLOR=[0 0 1;
    0.2 0.2 0.8;
    0.4 0.4 0.6;
    0.6 0.6 0.4;
    0.8 0.8 0.2;
    1 0 0];
% for side=1:6
%     select=(DICEPOS==side);
%     plot(T(select),sample_index(select),'.','MarkerSize', 0.01,'Color',COLOR(side,:))
% end
dice_roll=diff(DICEPOS,1,3)>0;
x=T(:,:,2:end);
y=sample_index(:,:,2:end);
plot(x(dice_roll),y(dice_roll),'.k','MarkerSize', 0.1)


set(gca, 'Xdir', 'reverse')
xlabel('Age (a)')
set(gca, 'XScale', 'log')
xlim(x_limits)
ylim([1 size(T,1)])
box on 
% grid on
% title('Dice position (blue=top red=bottom)')
title(['Dice rolls (dice side: ' num2str(min(boulder_size/100)) ' - ' num2str(max(boulder_size/100)) ' m)'])
ylabel('model#')



% plot apparent age vs. exhumation age (model)
figure('Units','normalized','Position',[0.5 0 0.5 1])
hold on
plot(EX_models(1,:,:),EX_models(1,:,:),'--g') % 1:1 line
text(1e6,1e6,'   1:1','Color','g')

plot(EX_models(1,:,:),EX_models(1,:,:)./10,':g') % 10:1 line
text(1e6,1e6/10,'   10:1','Color','g')

plot(EX_models(1,:,:),EX_models(1,:,:)./100,':g') % 100:1 line
text(1e6,1e6/100,'   100:1','Color','g')

plot(EX_models(1,:,:),EX_models(1,:,:)./1000,':g') % 100:1 line
text(1e6,1e6/1000,'   1000:1','Color','g')

% ratio_ages=EX_models./ASEA_models;
% AR=ceil(median(ratio_ages(:))); % average age ratio
% plot(EX_models*AR,EX_models,'--g') % AR:1 line
% text(1e6*AR,1e6,[num2str(AR) ':1'],'Color','g')
% for sample=1:numel(ASEA) 
%     plot([1 1]*ASEA(sample),[min_ex_age(sample) max_ex_age(sample)],'-r') % sample range
% end
% plot(EX_models,ASEA_models_bottom,'.r','MarkerSize', 0.1) % bottom models
% plot(EX_models,ASEA_models_side,'.m','MarkerSize', 0.1) % side models
% plot(EX_models,ASEA_models_top,'.b','MarkerSize', 0.1) % top models
for model=1:size(ASEA_models,1)
    if ISSIDE(model,1,1)
        plot(EX_models,ASEA_models(model,:),'.m','MarkerSize', 0.1) % side models
    elseif ISBOTTOM(model,1,1)
        plot(EX_models,ASEA_models(model,:),'.r','MarkerSize', 0.1) % bottom models
    else
        plot(EX_models,ASEA_models(model,:),'.b','MarkerSize', 0.1) % top models
    end
end
plot(EX_models,max(ASEA_models_bottom),'-r','LineWidth',2) % bottom models
plot(EX_models,max(ASEA_models_side),'-m') % side models
plot(EX_models,max(ASEA_models_top),'-b','LineWidth',2) % top models
plot(EX_models,min(ASEA_models_bottom),'-r','LineWidth',2) % bottom models
plot(EX_models,min(ASEA_models_side),'-m') % side models
plot(EX_models,min(ASEA_models_top),'-b','LineWidth',2) % top models
plot(EX_models,max(ASEA_models_bottom),'--r','LineWidth',1) % bottom models
plot(EX_models,min(ASEA_models_bottom),'--r','LineWidth',1) % bottom models
set(gca, 'Xdir', 'reverse')
set(gca, 'XScale', 'log')
xlim(x_limits)
set(gca, 'YScale', 'log')
ylim([1e2 1e8])
grid on
box on
xlabel('Exhumation age (years)')
% xlabel([consts.nuclidesstring{consts.nuclides==nuclide} ' ASEA'])
ylabel([consts.nuclidesstring{consts.nuclides==nuclide} ' Apparent Surface Exposure Age'])
title('GlaciDice ages (blue=top red=bottom)')
