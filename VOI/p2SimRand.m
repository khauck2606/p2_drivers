
addpath('../');

income_levels = {'LLMIC','MIC','HIC'};
strategies = {'No Closures','School Closures','Economic Closures','Elimination'};
diseases   = {'Influenza 2009','Influenza 1957','Influenza 1918',...
          'Covid Omicron','Covid Wildtype','Covid Delta',...
          'SARS'};

load('Argentina.mat','data');%loading Argentina, but only keeping country-independent parameters
fields    = fieldnames(data);
ikeep     = [6,7,8,13,14,16,17,18];
data      = rmfield(data,fields(~ismember(1:numel(fields),ikeep)));  
lx        = length(data.B);
data.tvec = [-75 365];
CD        = readtable('country_data.csv');
nsamples  = 4096;

synthetic_countries_base = cell(nsamples,length(income_levels));
synthetic_countries = cell(nsamples,length(income_levels),length(diseases));
synthetic_countries_dis = cell(nsamples,length(income_levels),length(diseases));
synthetic_countries_p2 = cell(nsamples,length(income_levels),length(diseases));

n_income = numel(income_levels);
n_diseases= numel(diseases);

parfor i = 1:nsamples
    rng(i);
    for il = 1:n_income
        income_level = income_levels{il};
        ldata1     = p2RandCountry(data,CD,income_level);
        synthetic_countries_base{i,il} = ldata1;
    end
end

parfor i = 1:nsamples
    for j = 1:n_diseases
        dis = get_dis_params(diseases{j}); 
        for il = 1:n_income
            ldata1     = synthetic_countries_base{i,il};
        
            [ldata0,~,~]    = p2Params(ldata1,'Covid Wildtype',dis);%to define wnorm and Td_CWT
            [ldata,dis2,p2] = p2Params(ldata0,diseases{j},dis);

            synthetic_countries_dis{i,il,j} = dis2;
            synthetic_countries_p2{i,il,j} = p2;
            synthetic_countries{i,il,j}     = ldata;
        end
    end
end



columnnames = {'School_age','Elders','Population_size','GDP','workp',...
    'Hospital_capacity','Test_rate','Test_start','Response_time',...
    'Social_distancing_min','Social_distancing_rate','R0','beta',...
    'Agriculture','Food_sector','International_tourism','Internet',...
    'Cost','Deaths','School','GDP_loss'};
inputs    = zeros(nsamples,length(columnnames)-4);
outputs   = zeros(nsamples,4);



for il = 1:n_income
    income_level = income_levels{il};
    for j = 1:n_diseases
        pathogen = diseases{j};
        for ms = 1:length(strategies)
            strategy = strategies{ms};
        
            parfor i = 1:nsamples
                dis2 = synthetic_countries_dis{i,il,j};
                p2 = synthetic_countries_p2{i,il,j};
                ldata = synthetic_countries{i,il,j};

                int = 5;
                xoptim = 0;
                if strcmp(strategy,'Elimination')
                    xoptim      = [ones(1*lx,1);ldata.x_econ(:,2);ldata.x_elim(:,1);ones(2*lx,1)];
                    ldata.hw    = [zeros(1,lx);ldata.wfh(2,:);ldata.wfh(1,:);zeros(2,lx)];
                    ldata.imand = [2];
                    ldata.inext = [2,2,3,2,5];
                elseif strcmp(strategy,'Economic Closures')
                    xoptim      = [ones(2*lx,1);ldata.x_econ(:,2);ldata.x_econ(:,1);ones(lx,1)];
                    ldata.hw    = [zeros(1,lx);ldata.wfh(1,:);ldata.wfh(2,:);ldata.wfh(1,:);zeros(1,lx)];
                    ldata.imand = [3];
                    ldata.inext = [2,3,3,4,5];
                elseif strcmp(strategy,'School Closures')
                    xoptim      = [ones(2*lx,1);ldata.x_schc(:,2);ldata.x_schc(:,1);ones(lx,1)];
                    ldata.hw    = [zeros(1,lx);ldata.wfh(1,:);ldata.wfh(2,:);ldata.wfh(1,:);zeros(1,lx)];
                    ldata.imand = [3];
                    ldata.inext = [2,3,3,4,5];
                elseif strcmp(strategy,'No Closures')
                    xoptim      = [ones(1*lx,1); repmat(ldata.unmit,4,1)];
                    ldata.hw    = [zeros(5,lx)];
                    ldata.imand = [10];
                    ldata.inext = [2,2,5];
                else
                    error('Unknown Mitigation Strategy!');
                end

                sec         = nan(1,4);

                try
                    [ldata,~,g] = p2Run(ldata,dis2,strategy,int,xoptim,p2);
                    [cost,~]    = p2Cost(ldata,dis2,p2,g);
                    sec(1)      = sum(cost([3,6,7:10],:),'all');
                    sec(2)      = sum(cost([3],:),'all');
                    sec(3)      = sum(cost([6],:),'all');
                    sec(4)      = sum(cost([7:10],:),'all');
                catch
                    disp(strcat('VOI_',string(pathogen),'_',string(strategy),'_',string(income_level),'.NA'))
                    disp(i);
            %             dis2
                end
                if any(sec<0)
                    disp(strcat('VOI_',string(pathogen),'_',string(strategy),'_',string(income_level),'.0'))
                    disp(i)
                end

            %         inputs(i,:)  = [i,NaN,NaN,ldata.Npop',ldata.NNs(1:45)',...
            %                         ldata.CM(:)',ldata.comm,ldata.travelA3,ldata.schoolA1,ldata.schoolA2,ldata.workp,...
            %                         ldata.obj',ldata.wfh(1,:),ldata.wfh(2,:),...
            %                         ldata.t_vax,ldata.arate,ldata.puptake,ldata.Hmax,ldata.t_tit,ldata.trate,ldata.Tres,ldata.sdl,ldata.sdb,...
            %                         NaN,ldata.la];
                outputs(i,:) = sec;

                gdp = sum(ldata.obj);
                popsize = sum(ldata.Npop);
                inputs(i,:)  = [ldata.NNs(47)/popsize ldata.NNs(49)/popsize popsize...
                    ldata.gdp ldata.workp ldata.Hmax ldata.trate ldata.t_tit ldata.Tres ...
                    ldata.sdl ldata.sdb dis2.R0sample dis2.beta ...
                    ldata.obj([1 32])'/gdp ldata.frac_tourism_international ldata.remote_quantile];
            %         sectorprops(i,:) = ldata.NNs([1:45,48])' ./ sum(ldata.NNs([1:45,48]));
            %         R0samples(i) = ;

            end

            T                          = array2table([inputs,outputs]);
            T.Properties.VariableNames = columnnames;

            %     'SEC','VLYL','VSYL','GDPL'};
            writetable(T,strcat('results/VOI_',string(pathogen),'_',string(strategy),'_',string(income_level),'.csv'));
            %plots = p2Plot(data,f,p2,g,cost,ccost_t,sec(1),inp1,inp2,inp3);
            
        end

    end
end

