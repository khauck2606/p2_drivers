% simulate a random country by drawing from distributions and data
%
% data: struct of general model parameters
% CD: table of country data values
% income_level: string indicating income level (e.g. HIC)
% country_parameter_distributions: pre-specified, named distributions and
% parameters
% social_dist_coefs: table of parameters for social distancing function
%
% data: struct of general model parameters

function data = p2RandCountry(data,CD,income_level,country_parameter_distributions, social_dist_coefs)

%% start
nSectors = data.nSectors;

contacts = data.contacts;


%% values from distributions
pindices = find(strcmp(country_parameter_distributions.igroup,income_level) | ...
    strcmp(country_parameter_distributions.igroup,'all') & ...
    ~strcmp(country_parameter_distributions.distribution,'NA'));
cpd = country_parameter_distributions(pindices,:);
for i = 1:size(cpd,1)
    qname = strcat(cpd.parameter_name{i},'_quantile');
    qexp = strcat(' = unifrnd(0,1);');
    eval([qname, qexp]);
    varname = cpd.parameter_name{i};
    expression = strcat('=',cpd.distribution{i},'(',...
        cpd.parameter_name{i},'_quantile,',...
        num2str(cpd.Parameter_1(i)),',',...
        num2str(cpd.Parameter_2(i)),');');
    eval([varname, expression]);
end

%% store values
international_tourism_quant = unifrnd(0,1);

data.gdp_to_gnippp = gdp_to_gnippp;
data.remote_quantile = internet_coverage_quantile;
data.response_time_quantile = unifrnd(0,1);
data.remote_teaching_effectiveness = unifrnd(0,1);
data.self_isolation_compliance = betarnd(5,5);
data.seedsize = unifrnd(4,8);

% social distancing parameters taken from table of saved samples
sdtab_ncol = size(social_dist_coefs,1);
randrow = randi([1 sdtab_ncol],1,1);
data.sd_baseline = social_dist_coefs.baseline(randrow);
data.sd_death_coef = exp(social_dist_coefs.deathcoef(randrow));
data.sd_mandate_coef = exp(social_dist_coefs.mandatecoef(randrow));

% contacts.pt = pt;
contacts.school1_frac = school1_frac;
contacts.school2_frac = school2_frac;
contacts.hospitality_frac = [hospitality1_frac; hospitality2_frac; hospitality3_frac; hospitality4_frac];

dindices = strmatch('hospitality_age',country_parameter_distributions.parameter_name);
cpd = country_parameter_distributions(dindices,:);
contacts.hospitality_age = zeros(3,size(cpd,1));
for i = 1:size(cpd,1)
    p3 = cpd.Parameter_1(i);
    p4 = cpd.Parameter_2(i);
    contacts.hospitality_age(:,i) = drchrnd([1-p3-p4 p3 p4]*10,1);
end


data.Hmax = Hmax; 
data.labsh = labsh;

%% values by sampling

if strcmp(income_level,'LLMIC')
    country_indices = strcmp(CD.igroup,'LIC') | strcmp(CD.igroup,'LMIC');
elseif strcmp(income_level,'UMIC')
    country_indices = strcmp(CD.igroup,'UMIC');
elseif strcmp(income_level,'HIC')
    country_indices = strcmp(CD.igroup,'HIC');
end

%% bmi
bmi = min(max(25.9,bmi), 29.9);
% three outcomes (infection, hospitalisation, death)
% two age groups (20 to 64, 65 plus)
bmi_gradients = [0.0166 0.0518 0.0534; 0.0045 0.026 0.0111];
bmi_intercepts= [0.524 -0.484 -0.531; 0.872 0.254 0.68];
bmi_sigma= [0.00185 0.00501 0.0168; 0.00155 0.0059 0.0121];

bmi_rr_quantile = repmat(unifrnd(0,1,1,3), 2, 1);
bmi_rr = norminv(bmi_rr_quantile, bmi.*bmi_gradients + bmi_intercepts, bmi_sigma);
% data.bmi_rr = bmi_rr;
% data.bmi = bmi;
% data.bmi_rr_quantile = bmi_rr_quantile(1,:);


%% population
% population by age
nonempind = find(~isnan(CD.CMaa) & ~isnan(CD.Npop1) & country_indices);
[~,idx] = sort(CD.average_contacts(nonempind));
nonempind = nonempind(idx);
demoindex = nonempind(randi(numel(nonempind)));
cols = strmatch('Npop', CD.Properties.VariableNames);
randvalue = table2array(CD(demoindex,cols));
Npop = 50*10^6*randvalue'/sum(randvalue);
data.Npop = Npop;
Npop4 = arrayfun(@(x) sum(Npop(x{1})), data.ageindex);
data.Npop4 = Npop4;

% population by stratum
% sample workforce
nonempind = find(~isnan(CD.NNs1) & country_indices);
randindex = nonempind(randi(numel(nonempind)));
colNNs = strmatch('NNs', CD.Properties.VariableNames);
sectorworkers = table2array(CD(randindex,colNNs));%number of workers by sector in real country
% normalise by number working age in sample country
workagecolnames = strcat("Npop",arrayfun(@num2str, data.ageindex{3}, 'UniformOutput', false));
workagecols = cell2mat(cellfun(@(a) strmatch(a, CD.Properties.VariableNames),...
    workagecolnames,'uniform',false));
sectorworkerfrac = sectorworkers/sum(table2array(CD(randindex,workagecols)));%proportion of adult population by sector in real country
workers_by_sector = Npop4(3)*sectorworkerfrac;%number of workers by sector in artificial country
% put into daedalus order: workers by sector, then infants, adolescents,
% non-workers, and retired
NNs = [workers_by_sector,Npop4(1),Npop4(2),Npop4(3)-sum(workers_by_sector),Npop4(4)]';

% work contact fraction should not exceed worker fraction
contacts.work_frac = min(work_frac, sum(workers_by_sector)/Npop4(3));

%% contacts
% workplace
sectorcontacts = contacts.sectorcontacts.n_cnt;
sB = size(sectorcontacts);
s1 = sB(1);
s2 = sB(2);
% contacts.B = max((contacts.B+1) .* 2.^unifrnd(-1,1,s1,s2) - 1, 0); %unifrnd(max(contacts.B/2-1,0),contacts.B*2+1);
contacts.sectorcontacts = max((sectorcontacts+1) .* 2.^unifrnd(-1,1,s1,s2) - 1, 0);
uk_ptr = 15.87574;
contacts.sectorcontacts(data.EdInd) = pupil_teacher_ratio / uk_ptr * contacts.sectorcontacts(data.EdInd);

% matrix
randvalue = table2array(CD(demoindex,strmatch("CM", CD.Properties.VariableNames)'));
defivalue = reshape(randvalue,16,16);
contacts.CM   = defivalue;

%workp = number of contacts in workplace
% contacts.workp = sample_uniform("workp",CD,country_indices);


%%
%wfh = work from home

nonempind = find(~isnan(CD.wfhl1) & country_indices);
mins = min(table2array(CD(nonempind,strmatch('wfhl', CD.Properties.VariableNames))));
maxs = max(table2array(CD(nonempind,strmatch('wfhu', CD.Properties.VariableNames))));
newprop = unifinv(internet_coverage_quantile,mins,maxs);
data.wfh  = [newprop; newprop];

% date of importation
data.t_import = unifrnd(0,20,1,1);

%Hres = hospital occupancy at response time in origin country
data.Hres = unifinv(data.response_time_quantile, 1,20);

%trate = testing rate
data.trate = sample_uniform("trate",CD,country_indices);

%sdl
% data.sdl = sample_uniform("sdl",CD,country_indices);

%sdb
% data.sdb = sample_uniform("sdb",CD,country_indices);

%t_vax = time to start vaccine administration
data.t_vax = 1000; 

%arate = vaccine administration rate
data.vaccination_rate_pc = 0.005;%unifrnd(0.5,1.5,1,1)/100;

%puptake = population uptake
data.vaccine_uptake = 0.8; %unifrnd(.4,.8,1,1);

%la = life expectancy
nonempind = find(~isnan(CD.la1) & country_indices);
cols = strmatch('la', CD.Properties.VariableNames);
randindex = nonempind(randi(numel(nonempind)));
randvalue = table2array(CD(randindex,cols));
data.la   = randvalue;


%% change sizes of sectors
% resample larger sectors
adultindices = [1:nSectors,nSectors+data.adInd];

% omit small sectors
adult_props = NNs(adultindices)./Npop4(3);
small_sectors = find(adult_props<1e-3);
resample_sectors = setdiff(adultindices, adultindices(small_sectors));

workingagepop2 = sum(NNs(resample_sectors));
adult_props = NNs(resample_sectors)./workingagepop2;

pointiness = 1000;
newvals = gamrnd(adult_props*pointiness,1);
adult_props2 = newvals ./ sum(newvals);

% rescale food and accommodation services

FAAind = 32;
if sum(resample_sectors==FAAind)>0
    origFAA = adult_props2(resample_sectors==FAAind);
    newFAA = 2^unifrnd(-1,1,1,1) * origFAA;

    adult_props2 = adult_props2*(1 - newFAA)/(1 - origFAA);
    adult_props2(resample_sectors==FAAind) = newFAA;
    
    NNs(resample_sectors) = adult_props2*workingagepop2;
end

data.NNs = NNs;

%% finish workers by sector

data.NNs  = NNs;
data.NNs(data.NNs==0) = 1;
data.nStrata     = size(data.NNs,1);


%% obj: income per worker
nonempind                   = find(~isnan(CD.obj1)&~isnan(CD.NNs1) & country_indices);
randindex                   = nonempind(randi(numel(nonempind)));
% weights = CD.popsum(nonempind)/sum(CD.popsum(nonempind));
% randindex = randsample(nonempind,1,true,weights);
cols1 = strmatch('obj', CD.Properties.VariableNames);
randvalue                   = table2array(CD(randindex,cols1));%gva by sector in real country
defivalue                   = randvalue./table2array(CD(randindex,colNNs));%gva per worker by sector in real country
defivalue(isnan(defivalue)) = 0;
defivalue(isinf(defivalue)) = 0;
defivalue                   = data.NNs(1:nSectors).*defivalue';%gva by sector in artificial country
%%!! need to check food and accomm gva as % of gdp
data.obj                    = defivalue;

%% valuations

discount_rate = 0.03;
gdp = 365*sum(data.obj);
data.gdp = gdp;
data.gdppc = gdp/sum(data.Npop);

%vly = value of a life year
% map life expectancy to our age groups
life_expectancy  = data.la;
lle = length(life_expectancy);
pop_sizes   = [data.Npop(1:(lle-1))',sum(data.Npop(lle:end))];%length is 18 to match life table
pop_sizes_4 = Npop4;

age_map = data.ageindex;
age_map{4} = min(age_map{4}):length(pop_sizes);
life_expectancy_4 = zeros(size(age_map));
for k = 1:length(life_expectancy_4)
    index = age_map{k};
    life_expectancy_4(k) = dot(life_expectancy(index),pop_sizes(index))/sum(pop_sizes(index));
end
% get discounted values
discounted_life_expectancy = zeros(size(life_expectancy_4));
for k = 1:length(life_expectancy_4)
    discounted_life_expectancy(k) = sum(1./((1+discount_rate).^(1:life_expectancy_4(k))));
end 

vsl_usa = 10.9; % global fund % everything is in millions
gdp_usa = 21.38e6; % everything is in millions
usa_pop = sum(table2array(CD(strcmp(CD.country,'United States'),find(strcmp(CD.Properties.VariableNames,'Npop1')):find(strcmp(CD.Properties.VariableNames,'Npop21')))));
gdp_pc_usa = gdp_usa/usa_pop;
vsl_gdp_elasticity = unifrnd(.8,1.2); % 1.5: global fund. 1.6: stephen rash %0.8:12: erik lamontagne
vsl_method = randi([1 4]);
if vsl_method > 2
    gdp_to_gnippp = 1;
end
gni_pc_ppp = gdp_to_gnippp*gdp/sum(Npop);
if vsl_method > 2
    if gni_pc_ppp < 8809/1e6
        vsl_gdp_elasticity = 1;
    else
        vsl_gdp_elasticity = unifrnd(0.85,1);
    end
end
if vsl_method < 3
    if strcmp('LLMIC',income_level) | strcmp('UMIC',income_level)
        vsl_gdp_elasticity = unifrnd(0.9,1.2);
    else
        vsl_gdp_elasticity = 0.8;
    end
end
        
vsl       = max(vsl_usa * (gni_pc_ppp/gdp_pc_usa)^vsl_gdp_elasticity, 20*gni_pc_ppp); %robinson 2019
value_of_a_life_year = vsl/(dot(life_expectancy_4,pop_sizes_4)/sum(pop_sizes_4));
data.vly  = value_of_a_life_year;

%% vsy = value of a school year
rate_of_return_one_year = 0.08;
agefracs = data.Npop(data.ageindex{2})/Npop4(2);
midages = [7 12 17];
working_years = 45;
workstarts = 20 - midages;
workends = working_years + workstarts;

% present value
PV = ((1-(1+discount_rate).^(-workends))/discount_rate - (1-(1+discount_rate).^(-workstarts))/discount_rate)*agefracs;

mean_annual_income = labsh*gdp/Npop4(3);
educationloss_all_students = ...
    PV*mean_annual_income*rate_of_return_one_year*Npop4(2);
educationloss_per_student = ...
    PV*mean_annual_income*rate_of_return_one_year;

data.vsy  = educationloss_per_student;
data.educationloss_all_students  = educationloss_all_students;


%% international tourism 

pindex = find(strcmp(country_parameter_distributions.parameter_name,'tourism_pointiness'));
pindex2 = find(strcmp(country_parameter_distributions.parameter_name,'sec_to_international'));

pointiness = country_parameter_distributions.Parameter_1(pindex); % for beta distribution
sec_to_international = country_parameter_distributions.Parameter_1(pindex2); % scales fraction to fraction
international_const = country_parameter_distributions.Parameter_2(pindex2); % constant

GDP = sum(data.obj);
FAAfrac = data.obj(FAAind)/GDP;
alpha = pointiness * min(sec_to_international * FAAfrac + international_const,1);
beta = pointiness - alpha;
frac_tourism_international = betainv(international_tourism_quant,alpha+1e-2,beta+1e-2);
FAAmax = 1 - frac_tourism_international + frac_tourism_international*remaining_international_tourism;
data.frac_tourism_international = frac_tourism_international;

data.x_unmit = ones(size(data.x_elim));
%%!! set min to one for now until we can allow for increased tourism
data.x_unmit(FAAind) = min(FAAmax,1);
data.x_elim(FAAind) = min(FAAmax,data.x_elim(FAAind));
data.x_econ(FAAind,:) = min(FAAmax,data.x_econ(FAAind,:));
data.x_schc(FAAind,:) = min(FAAmax,data.x_schc(FAAind,:));


%% generate basic contact components

%Contact Matrix
data.contacts = get_basic_contacts(data, contacts);
basic_contact_matrix = p2MakeDs(data,data.NNs,ones(data.nSectors,1),zeros(1,data.nSectors));
data.contacts.basic_contact_matrix = basic_contact_matrix;


end


% function to sample dirichlet random variables
% r: parameter vector
% n: number of samples
function r = drchrnd(a,n)
    p = length(a);
    r = gamrnd(repmat(a,n,1),1,n,p);
    r = r ./ repmat(sum(r,2),1,p);
end