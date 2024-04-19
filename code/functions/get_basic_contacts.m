% take population contact matrix and decompose into items that will be
% impacted differently by configurations
%
% data: struct of general model parameters
%
% contacts: struct of contact parameters

function contacts = get_basic_contacts(data, contacts)


NN = data.NNs;
CM_16       = contacts.CM;
s16 = size(CM_16,1);

Npop     = data.Npop;
Npop(s16) = sum(Npop(s16:end));
Npop     = Npop(1:s16);
ageindex = data.ageindex;
ageindex{4} = min(ageindex{4}):s16;
Npop4 = data.Npop4;
pop_props = Npop4/sum(Npop);


%% COMMUNITY-COMMUNITY MATRIX:

CM_164    = cell2mat(arrayfun(@(x) sum(CM_16(:,x{1}),2), ageindex, 'UniformOutput', false)); %sum of the columns
CM_4      = cell2mat(arrayfun(@(x) (Npop(x{1})'*CM_164(x{1},:)/sum(Npop(x{1})))', ageindex, 'UniformOutput', false))';        
CMav      = pop_props*sum(CM_4,2);
contact_props = CM_4(3,:)/sum(CM_4(3,:));
workage_total = sum(CM_4(3,:));

%% indices

adInd    = data.adInd; %Adult index
nSectors       = length(data.obj); %Number of sectors
nStrata       = length(NN);
workage_indices = [1:nSectors,nSectors+adInd];

NNrel = NN(workage_indices)/sum(NN(workage_indices)); %adult population proportion vector
% NNrepvecweighted = zeros(1,nStrata);
% NNrepvecweighted(workage_indices) = NNrel*contact_props(3);
% NNrepvecweighted(nSectors+[1,2,4]) = contact_props([1,2,4]);
% NNrep = repmat(NNrepvecweighted,nStrata,1); %total population proportion matrix
% NNrea = repmat(NN(1:nSectors)'/sum(NN(1:nSectors)),nSectors,1); %workforce population proportion matrix

%% WORKER-WORKER AND COMMUNITY-WORKER MATRICES:

% workerworker_contacts          = contacts.B;
% workerworker_contacts(nSectors+1:nStrata) = 0;
% workerworker_mat          = diag(workerworker_contacts');

sectoragedist = zeros(nSectors,nStrata);
sectoragedist(:,nSectors+[1,2]) = contacts.sectorcontactfracs.under18 * pop_props(1:2)/sum(pop_props(1:2));
sectoragedist(:,nSectors+4) = contacts.sectorcontactfracs.x65plus;
sectoragedist(:,workage_indices) = contacts.sectorcontactfracs.workingage * NNrel';

community_to_worker          = contacts.sectorcontacts;
community_to_worker_mat          = repmat(community_to_worker,1,nStrata).*sectoragedist;
community_to_worker_mat(nSectors+1:nStrata,:) = 0;

% move school contacts to students
% EdInd = data.EdInd;
% teacher_contacts = customer_to_worker(EdInd);
% frac_infant = NN(nSectors+1)/sum(NN(nSectors+[1:2]));
% customer_to_worker_mat(EdInd,:) = 0.1 * teacher_contacts .* NNrep(EdInd,:);
% customer_to_worker_mat(EdInd,nSectors+1) = customer_to_worker_mat(EdInd,nSectors+1) + 0.9*frac_infant * teacher_contacts;
% customer_to_worker_mat(EdInd,nSectors+2) = customer_to_worker_mat(EdInd,nSectors+2) + 0.9*(1-frac_infant) * teacher_contacts;

% get total contacts between customers and workers
% contacts_between_workers_and_customers = customer_to_worker_mat .* repmat(NN,1,nStrata);
% get reciprocal contacts
% worker_to_customer_mat = contacts_between_workers_and_customers' ./ repmat(NN,1,nStrata);

% normalise
% worker_total = dot(sum(workerworker_mat+customer_to_worker_mat,2),NN)/sum(NN(workage_indices));
worker_total = dot(sum(community_to_worker_mat,2),NN)/sum(NN(workage_indices));
target_work_contacts = contacts.work_frac*workage_total;
contacts.work_scalar = target_work_contacts / worker_total;

% workerworker_mat = contacts.work_scalar * workerworker_mat;
% av_worker_contacts = dot(sum(workerworker_mat,2),NN)/sum(NN(workage_indices));

community_to_worker_mat = contacts.work_scalar * community_to_worker_mat;
contacts.community_to_worker_mat = community_to_worker_mat;

% get marginal contacts by age for workers
rel_mat = NNrel' * community_to_worker_mat(workage_indices,:);
c_to_w_distributed = [rel_mat(:,nSectors+1), rel_mat(:,nSectors+2), sum(rel_mat(:,workage_indices)), rel_mat(:,nSectors+4)];

% worker_to_customer_mat = contacts.workrel * worker_to_customer_mat;
% C_back = [sum(worker_to_customer_mat(46,:)), ...
%     sum(worker_to_customer_mat(47,:)),...
%     sum(NNrel' * worker_to_customer_mat([1:45,48],:)),...
%     sum(worker_to_customer_mat(49,:))];

c_to_w_back = c_to_w_distributed*Npop4(3) ./ Npop4;
        
%% get new contact rates
contacts.school1 = CM_4(1,1) * contacts.school1_frac;
contacts.school2 = CM_4(2,2) * contacts.school2_frac;

% normalise France values: 18% travel is pt, and pt has 2.5% of contacts,
% which is 0.555
% contacts.travelA3 =  contacts.pt/0.18*0.025*CMav;


%% subtract contacts from C4

% school
CM_4(1,1) = CM_4(1,1) - contacts.school1;
CM_4(2,2) = CM_4(2,2) - contacts.school2;
% travel and work
% CM_4(3,3) = CM_4(3,3) - av_worker_contacts; %  - contacts.travelA3 * sum(NN(1:nSectors))/sum(NN(workage_indices))
% customer to worker
CM_4(3,:) = CM_4(3,:) - c_to_w_distributed;
% worker to customer
CM_4(:,3) = CM_4(:,3) - c_to_w_back';

% hospitality
% remaining_contacts = sum(C4,2);

% contacts.hospA2 = contacts.hospitality_frac * remaining_contacts(2);
% contacts.hospA3 = contacts.hospitality_frac * remaining_contacts(3);
% contacts.hospA4 = contacts.hospitality_frac * remaining_contacts(4);
% 
% C4(2,:) = C4(2,:) - contacts.hospA2 * contact_props;
% C4(3,:) = C4(3,:) - contacts.hospA3 * contact_props;
% C4(4,:) = C4(4,:) - contacts.hospA4 * contact_props;

%%!! too many work contacts to infants
hospitality_age = contacts.hospitality_age;
hospitality_age = [hospitality_age(1,:); hospitality_age];
total_contacts = sum(CM_4,2);
contacts.hospitality_contacts = repmat(total_contacts .* contacts.hospitality_frac,1,4) .* hospitality_age;
CM_4 = max(CM_4 - contacts.hospitality_contacts, 0);

%% save

contacts = rmfield(contacts,'sectorcontactfracs');
contacts.CM_4 = CM_4;
contacts.contact_props = contact_props;

end