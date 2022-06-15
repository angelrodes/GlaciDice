function [ ] = constants()
% This function generates the constants needed to run the accumulation
% models. Surface production rates for spallation and muons are both scaled
% to 1 for each isotope. The muon contributions are not calculated here.
% Angel Rodes, 2020

%% version
consts.ver='1.9';

%% Nuclides included in this version
consts.nuclides=[10;...
               26;...
               36;...
               14;...
               21;...
               3];
           
consts.nuclidesstring=[{'Be-10'};...
               {'Al-26'};...
               {'Cl-36'};...
               {'C-14'};...
               {'Ne-21'};...
               {'He-3'}];
           
%% Decay constants
earth_age=4.543e9;

consts.l=[-log(0.5)./1.387e6;...
        -log(0.5)./0.705e6;...
        -log(0.5)./301e3;...
        -log(0.5)./5700;...
        -log(0.5)./(100*earth_age);...
        -log(0.5)./(100*earth_age)];
% Be-10: Chmeleff et al. 2010 https://doi.org/10.1016/j.nimb.2009.09.012
% Al-26: Nishiizumi 2004 https://doi.org/10.1016/j.nimb.2004.04.075
% For stable nuclides: consider half lives 100 times the earth age (avoid 1/0 errors)


%% Attenuation lengths
% Spallation 
consts.Lsp=160; % g/cm^2
% 160 g/cm^2, consistent with Balco (2008) calculators

% Muons
% mu_fast_1 mu_fast_2 mu_neg
consts.Lmu=[850 5000 500]; % g/cm^2
% Production by fast muons has been splitted in two to fit the cross
%     sectiong generated by 
%     P_mu_total_alpha1.m from Balco 2017 https://doi.org/10.1016/j.quageo.2017.02.001
%     for the first 100 m under the surface:
%     P_fast(z)/P_fast(0)=0.75*exp(-z*density/850)+0.25*exp(-z*density/5000)
% P_neg was fitted to a single exponential:
%     P_neg(z)/P_neg(0)=exp(-z*density/500)

%% Prodution rates
% These approximations are based on the production at 1678 sites
% equally distributed on land areas according to
% ETOPO1_Bed_g_geotiff.tif (Eakins et al., 2012)
% and calculated using
% P_mu_total_alpha1.m and stone2000.m from CRONUS calculators v2.3
% (Balco, 2017 and Balco, 2008)

% Surface fast muon contribution to Be-10 muon production
C_fast_mu_10=0.32069;
% Surface fast muon contribution to Al-26 muon production
C_fast_mu_26=0.22282;
% Surface fast muon contribution to Cl-36 muon production according to Heisinger & Nolte (2000)
C_fast_mu_36=0.0620;
% Surface fast muon contribution to C-14 muon production according to Heisinger & Nolte (2000)
C_fast_mu_14=0.0672;
% Surface fast muon contribution to Ne-21 muon production according to Balco & Shuster (2009)
C_fast_mu_21=1;
% Surface fast muon contribution to He-3 muon production according to Blard et al. (2013)
C_fast_mu_3=C_fast_mu_10;


% make production matrices
consts.Psp=ones(size(consts.nuclides)); % Ones for spallation
consts.Pmu=zeros(numel(consts.nuclides),3);


% Be-10 production rates
% mu_fast_1, mu_fast_2, mu_neg
consts.Pmu(1,1:3)=[...
    C_fast_mu_10*0.75,...
    C_fast_mu_10*0.25,...
    (1-C_fast_mu_10)] ;
% Al-26 production rates
% mu_fast_1, mu_fast_2, mu_neg
consts.Pmu(2,1:3)=[...
    C_fast_mu_26*0.75,...
    C_fast_mu_26*0.25,...
    (1-C_fast_mu_26)] ;
% Cl-36 production rates
% mu_fast_1, mu_fast_2, mu_neg
consts.Pmu(3,1:3)=[...
    C_fast_mu_36*0.75,...
    C_fast_mu_36*0.25,...
    (1-C_fast_mu_36)] ;
% C-10 production rates
% mu_fast_1, mu_fast_2, mu_neg
consts.Pmu(4,1:3)=[...
    C_fast_mu_14*0.75,...
    C_fast_mu_14*0.25,...
    (1-C_fast_mu_14)] ;
% Ne-21 production rates
% mu_fast_1, mu_fast_2, mu_neg
consts.Pmu(5,1:3)=[...
    C_fast_mu_21*0.75,...
    C_fast_mu_21*0.25,...
    (1-C_fast_mu_21)] ;
% He-3 production rates
% mu_fast_1, mu_fast_2, mu_neg
consts.Pmu(6,1:3)=[...
    C_fast_mu_3*0.75,...
    C_fast_mu_3*0.25,...
    (1-C_fast_mu_3)] ;


%% Densities

% Average density of bedrock
consts.rho=2.65; % g/cm^3

% Ice density
% Harvey, Allan H. (2017). "Properties of Ice and Supercooled Water". 
% In Haynes, William M.; Lide, David R.; Bruno, Thomas J. (eds.). 
% CRC Handbook of Chemistry and Physics (97th ed.).
% Boca Raton, FL: CRC Press. ISBN 978-1-4987-5429-3.
consts.rhoice=0.917; % g/cm^3

%% Default limits for glacial modeling (NUNAIT)

% Periglacial weathering range
% Marrero et al., 2018 https://doi.org/10.1016/j.epsl.2018.08.018
% "Controls on subaerial erosion rates in Antarctica"
% Strunk, A. et al. (2017) https://doi.org/10.1038/ncomms14199
% "One million years of glaciation and denudation history in west Greenland"
consts.ice_free_erosion=[0.001 100]/1e4; % cm/a

% Glacial erosion range
% Cook et al., 2020
% The empirical basis for modelling glacial erosion rates
% https://doi.org/10.1038/s41467-020-14583-8
% Global minimum and maximum values
% 0.01-100 mm/a
consts.glacial_erosion=[0.01 100]/10; % cm/a

% Ice thinning
% minimum and maximum values for ice-thinning since maximum extension
consts.ice_thinning=[10 5000]; % m

% Uplift
% minimum and maximum values for Nunatak uplift rate
consts.uplift_rate=[0 10]; % m/Ma

% Present ice surface uncertainty
consts.present_ice_surface_uncert=[-25 25]; % m

% Minimum ages
% Aparent ages are considered minimum (true) or not (false)
consts.minimum_ages=false;

%% Fitting parameters (NUNAIT)
% Define number of models to run
consts.maxnmodels=50000; % maximum number of models to run. Increase this number for better results. (Minimum=10000)
consts.targetnmodelsonesigma=300; % desired fitting models when start converging (Minimum=100)

% Criteria for convergence
consts.minmodelstoconverge=3000; % learning models (Minimum=1000)
consts.convergencestep=100; % how often to check convergence and update (suggested: 100)

%% Parameters GlaciDice

consts.boulder_size=[150 200]; % side of the diced boulders in cm
consts.last_deglaciation=[11000 11500]; % years (range for last deglaciation)
consts.ice_depth=1000; % m (deph under ice during glaciations)
consts.nuclide=10; % the mass of the cosmonuclide
consts.number_of_models=500;

%% save consts consts
save('consts.mat','consts','-v7')
end

