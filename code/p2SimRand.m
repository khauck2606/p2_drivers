
%% global variables

income_levels = {'LLMIC','UMIC','HIC'};
strategies = {'No Closures','School Closures','Economic Closures','Elimination'};
vaccination_levels = [365, 100];
bpsv_levels = [0, 1];

nsamples  = 1;
n_income = numel(income_levels);

% synthetic_countries_base = cell(nsamples,length(income_levels));
synthetic_countries = cell(nsamples,length(income_levels));
synthetic_countries_dis = cell(nsamples,length(income_levels));
synthetic_countries_dis_basis = cell(nsamples,1);
synthetic_countries_p2 = cell(nsamples,length(income_levels),length(vaccination_levels),length(bpsv_levels));

%% country variables

[CD, country_parameter_distributions] = load_country_data();
data = data_start();
lx = data.lx;

%% disease variables

rng(0);
alldissamples = sample_disease_parameters(nsamples);

R0_to_beta = @(dis) [dis.R0, dis.R0/dis.CI];

% get basic disease profiles
names = fieldnames(alldissamples);
dis = struct;
for i = 1:nsamples
    rng(i);
    for fn = 1:numel(names)
        thisfield = names{fn};
        samples = alldissamples.(thisfield);
        dis.(thisfield) = samples(i,:);
    end
    synthetic_countries_dis_basis{i} = dis;
end

%% countries by disease

% 2: get all countries
% get covid doubling time
% 3: get beta and R0, where beta depends on R0
betas = zeros(nsamples,n_income);
R0s = zeros(nsamples,n_income);
for i = 1:nsamples
    dis = synthetic_countries_dis_basis{i};
    for il = 1:n_income
        rng(i);
        income_level = income_levels{il};
        
        % country data. random samples
        ldata1     = p2RandCountry(data,CD,income_level,country_parameter_distributions);
%         synthetic_countries_base{i,il} = ldata1;

        dis1 = population_disease_parameters(ldata1,dis,R0_to_beta);

        ldata1.rts = get_response_time(ldata1,dis1,ldata1.Hres);
        
        for vl = 1:length(vaccination_levels)
            for bl = 1:length(bpsv_levels)
                [ldata,dis2,p2] = p2Params(ldata1,dis1,vaccination_levels(vl),bpsv_levels(bl));
                synthetic_countries_p2{i,il,vl,bl} = p2;
            end
        end
        synthetic_countries_dis{i,il} = dis2;
        synthetic_countries{i,il}     = ldata;
    end
end
clear synthetic_countries_dis_basis

%% set up simulation
inputcolumnnames = {'VLY','VSY',...
    'School_contacts','School_age','Working_age','Elders',...
    'Unemployment_rate','GDP','Labour_share','Work_contacts',...
    'Hospitality_contacts',...
    'Hospital_capacity','Test_rate','Hospital_response','Response_time',...
    'Vaccination_rate','Vaccine_uptake',...
    'Social_distancing_max','Social_distancing_rate','Self_isolation_compliance','Candidate_infectees',...
    'Agriculture','Food_sector','International_tourism',...
    'Remote_teaching_effectiveness','Importation_time',...
    'Remote_quantile','Hospital_occupancy_at_response', 'Remaining_susceptible','Exit_wave',... 
    'Doubling_time','Generation_time',...
    'R0','beta','Mean_IHR',...
    'Mean_HFR','Mean_IFR','Probability_symptomatic','Latent_period',...
    'Asymptomatic_period','Symptomatic_period','Time_to_hospitalisation','Time_to_discharge',...
    'Time_to_death',...
    'End_mitigation','End_simulation'...
    'Elimination_R0','School_R0_1','School_R0_2','Econ_R0_1','Econ_R0_2'};
outputcolumnnames = {'Cost','dYLLs','School','GDP_loss','Deaths'};
columnnames = [inputcolumnnames outputcolumnnames ];
inputs    = zeros(nsamples,length(inputcolumnnames));
outputs   = zeros(nsamples,length(outputcolumnnames));

%% simulate

hts = zeros(nsamples,n_income);
endsusctcell = cell(n_income,length(strategies));
for il = 1:n_income
    income_level = income_levels{il};
    for ms = 1:length(strategies)
        strategy = strategies{ms};
        ht = zeros(1,nsamples);
        endsusct = zeros(length(vaccination_levels)*length(bpsv_levels),nsamples);
        for vl = 1:length(vaccination_levels)
            for bl = 1:length(bpsv_levels)
                endsusci = zeros(1,nsamples);
                parfor i = 1:nsamples
                    dis2 = synthetic_countries_dis{i,il};
                    ldata = synthetic_countries{i,il};                   
                    p2 = synthetic_countries_p2{i,il,vl,bl};
                    [rdata, xoptim] = get_strategy_design(ldata,strategy,p2);
                    int = 5;
                    try

                        [~,returned,iseq] = p2Run(rdata,dis2,strategy,int,xoptim,p2);
                        endsim = max(returned.Tout);
                        endmit = iseq(end,1);
                        [~,exitwave] = min(abs(returned.Tout-endmit));
                        exitwavefrac = 1-sum(returned.deathtot(exitwave))/sum(returned.deathtot(end));
        %                         figure('Position', [100 100 400 300]); plot(f(:,1),f(:,7:10))
                        endsusc = returned.Stotal(end)/returned.Stotal(1);
                        endsusci(i) = endsusc;  
                        ht(i) = returned.Htot(find(returned.Tout > p2.Tres,1));

                        [cost,~]    = p2Cost(ldata,dis2,p2,returned);
                        sec         = nan(1,4);
                        sec(1)      = sum(cost([3,6,7:10],:),'all');
                        sec(2)      = sum(cost([3],:),'all');
                        sec(3)      = sum(cost([6],:),'all');
                        sec(4)      = sum(cost([7:10],:),'all');  
                        total_deaths = returned.deathtot(end);
                        
                        gdp = sum(ldata.obj);
                        popsize = sum(ldata.Npop);
                        working_age = popsize - sum(ldata.NNs([46,47,49]));
                        unemployment_rate = ldata.NNs(48)/working_age;
                        contacts = ldata.contacts;
                        inputs(i,:)  = [ldata.vly ldata.vsy ...
                            contacts.schoolA2 ldata.NNs(47)/popsize working_age/popsize ldata.NNs(49)/popsize...
                            unemployment_rate ldata.gdp ldata.labsh contacts.workrel ...
                            contacts.hospitality_frac...
                            ldata.Hmax ldata.trate ldata.Hres p2.Tres...
                            ldata.vaccination_rate_pc ldata.vaccine_uptake ...
                            ldata.sdl ldata.sdb ldata.self_isolation_compliance dis2.CI ...
                            ldata.obj([1 32])'/gdp ldata.frac_tourism_international ...
                            ldata.remote_teaching_effectiveness ldata.t_import...
                            ldata.remote_quantile ht(i) endsusc exitwavefrac...
                            dis2.Td dis2.generation_time ...
                            dis2.R0 dis2.beta mean(dis2.ihr) ...
                            mean(dis2.hfr) mean(dis2.ifr) dis2.ps dis2.Tlat ...
                            dis2.Tay dis2.Tsr dis2.Tsh dis2.Threc ...
                            dis2.Thd ...
                            endmit endsim ...
                            dis2.R0s];
                        outputs(i,:) = [sec total_deaths];

                        if any(sec<0)
                            disp(strcat(string(strategy),'_',string(income_level),'_',string(vaccination_levels(vl)),'_',string(bpsv_levels(bl)),'_',string(i),' 0'))
                            disp(i)
                        end
                    catch
                        disp(strcat(string(income_level),'_',string(strategy),'_',string(vaccination_levels(vl)),'_',string(bpsv_levels(bl)),'_',string(i),' NA'))
                        disp([il ms vl bl i]);
                    end
                end   
                endsusct((vl-1)*length(bpsv_levels)+bl,:) = endsusci;
                disp([il ms vl bl])
                disp(outputs)
                T = array2table([inputs outputs]);
                T.Properties.VariableNames = columnnames;
                writetable(T,strcat('results/VOI_',string(strategy),'_',string(income_level),'_',string(vaccination_levels(vl)),'_',string(bpsv_levels(bl)),'.csv'));
            end
        end
        printendsusct = [(1:nsamples)/1000; endsusct];
%         disp(printendsusct(:,printendsusct(5,:)+2e-2<printendsusct(3,:)|printendsusct(4,:)+2e-2<printendsusct(2,:)));
    end
end

