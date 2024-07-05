% function to combine population and disease parameters to get
% within-country pathogen parameters
%
% data: struct of general model parameters
% dis: struct of pathogen parameters
% R0betafun: the function that computes beta from R0
% R0_dist: distribution of values from which values for R0 are drawn
%
% dis: struct of pathogen parameters

function [dis, data] = population_disease_parameters(data,dis,R0betafun, R0_dist)

    %% COUNTRY PARAMETERS

    %% INITIAL DISEASE PARAMETERS
    %Population by Age
    nSectors = data.nSectors;
    adInd = data.adInd;
    subs0   = 1:4;
    lihr = length(dis.ihr);
    Npop     = data.Npop';
    Npop     = [Npop(1:(lihr-1)),sum(Npop(lihr:end))];%last age range for disease is 80+
    ageindex = data.ageindex;
    ageindex{4} = min(ageindex{4}):lihr;

    ranges = arrayfun(@(x) length(x{1}), ageindex);
    Npop4rep  = repelem(data.Npop4,ranges);
    nnprop = Npop./Npop4rep;
    subs   = repelem(subs0,ranges);

    %Probabilities
    probHgivenSym    = dis.ihr./dis.ps;
    probDgivenH    = dis.ifr./dis.ihr;
    dis.hfr = probDgivenH;
    probHgivenSym    = accumarray(subs',probHgivenSym.*nnprop);
    dis.ph  = [repmat(probHgivenSym(adInd),nSectors,1);probHgivenSym];
    nnh     = Npop.*dis.ihr;
    nnhtot  = arrayfun(@(x) sum(nnh(x{1})), ageindex); 
    nnhtot  = repelem(nnhtot,ranges);
    nnhprop = nnh./nnhtot;
    probDgivenH    = accumarray(subs',probDgivenH.*nnhprop);
    dis.pd  = [repmat(probDgivenH(adInd),nSectors,1);probDgivenH];

    dis.rr_infection = 1; % [repmat(data.bmi_rr(1,1),nSectors,1); 1; 1; data.bmi_rr(1,1); data.bmi_rr(2,1)];

    %Durations
    dis.Ts = ((1-dis.ph).*dis.Tsr)   + (dis.ph.*dis.Tsh);
    dis.Th = ((1-dis.pd).*dis.Threc) + (dis.pd.*dis.Thd);

    %Rates
    dis.sig1 = (1-dis.ps)/dis.Tlat;
    dis.sig2 = dis.ps/dis.Tlat;
    dis.g1   = 1/dis.Tay;
    dis.g2   = (1-dis.ph)./dis.Ts;
    dis.g3   = (1-dis.pd)./dis.Th;
    dis.h    = dis.ph./dis.Ts;
    dis.mu   = dis.pd./dis.Th;
    dis.nu   = 1/dis.Ti;

    %% vaccines

    %Vaccine: Broadly protective sarbecovirus vaccine (BPSV)
    dis.hrv1 = 1/21;                       %time to develop v-acquired immunity
    dis.scv1 = 0.35;                       %infection-blocking effectiveness
    heff1 = 0.80;                       %severe-disease-blocking effectiveness
    dis.hv1  = 1-((1-heff1)/(1-dis.scv1)); 
    dis.trv1 = 0;%.52;                       %transmission-blocking effectiveness
    dis.nuv1 = 1/365000000; %365/5;                      %duration of v-acquired immunity

    Ts_v1 = ((1-(1-dis.hv1)*dis.ph).*dis.Tsr)  +((1-dis.hv1)*dis.ph.*dis.Tsh);
    dis.g2_v1 = (1-(1-dis.hv1)*dis.ph)./Ts_v1;
    dis.h_v1  = (1-dis.hv1)*dis.ph./Ts_v1;

    % SARS-X specific
    dis.hrv2 = 1/21;                       %time to develop v-acquired immunity
    dis.scv2 = 0.55;                       %infection-blocking effectiveness
    heff2 = 0.90;                       %severe-disease-blocking effectiveness
    dis.hv2  = 1-((1-heff2)/(1-dis.scv2)); 
    dis.trv2 = 0;                       %transmission-blocking effectiveness
    dis.nuv2 = 1/365000000;                     %duration of v-acquired immunity

    Ts_v2 = ((1-(1-dis.hv2)*dis.ph).*dis.Tsr) + ((1-dis.hv2)*dis.ph.*dis.Tsh);
    dis.g2_v2 = (1-(1-dis.hv2)*dis.ph)./Ts_v2;
    dis.h_v2  = (1-dis.hv2)*dis.ph./Ts_v2;



    NNs = data.NNs;
    zs = zeros(size(NNs));
    dis.CI = get_candidate_infectees(length(NNs), dis, NNs,zs, zs, 0, 0, NNs, data.contacts.basic_contact_matrix);

    R0beta = R0betafun(dis);
    dis.R0 = R0beta(1);
    dis.beta = R0beta(2);

    dis.Td = get_doubling_time(data,dis);

    dis.generation_time = log(dis.R0) / (log(2) / dis.Td);
    
    
    %% sample a response time
    data.response_time = get_response_time(data,dis,data.Hres);
    
    %% self isolation compliance depends on R0
    % get R0 quantile
    input_quant = cdf(R0_dist,dis.R0);
    % generate correlated variable
    output_quant = correlate_random_var(input_quant, 0.7);
    % convert to beta random variable
    data.self_isolation_compliance = betainv(output_quant, 5,5);

end

% correlate_random_var: function to generate random quantiles correlated to
% a pre-existing vector via a multivariate normal with specified
% correlation
% 
% input_quant: column vector of input quantiles
% correlation: value between 0 and 1
%
% output_quant: column vector of correlated output quantiles

function output_quant = correlate_random_var(input_quant, correlation)


    n     = length(input_quant);                    % length of vector
    rho   = correlation;                   % desired correlation = cos(angle)
    theta = acos(rho);             % corresponding angle
    % map input quant to normal var
    x1    = norminv(input_quant, 0, 1);        % fixed given data
    x2    = normrnd(0, 1, n, 1);      % new random data
    Xctr     = [x1, x2];         % matrix

    Id   = eye(n);                               % identity matrix
    [Q, ~] = qr(Xctr(: , 1));
    P    = Q * Q';       % projection onto space defined by x1
    x2o  = (Id-P) * Xctr(: , 2);                 % x2ctr made orthogonal to x1ctr
    Xc2  = [Xctr(: , 1), x2o];               % bind to matrix
    Y    = Xc2 * diag(1./sqrt(sum(Xc2.^2)));  % scale columns to length 1

    x = Y(: , 2) + (1 / tan(theta)) * Y(: , 1);     % final new vector
    corr(x1, x);                                    % check correlation = rho
    output_quant = normcdf(x,0,1);

end



