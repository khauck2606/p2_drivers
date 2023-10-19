function [data,f,g] = p2Run(data,dis,inp3,int,Xit,p2)

    adInd = data.adInd;
    lx    = data.lx;
    ln    = length(data.NNs);

    NNbar                = data.NNs;
    XitMat               = reshape(Xit,lx,int);
    WitMat               = XitMat.^(1/data.alp);
    WitMat(data.EdInd,:) = XitMat(data.EdInd,:);
    NNvec                = repmat(NNbar(1:lx),1,int).*WitMat;
    NNworkSum            = sum(NNvec,1);
    NNvec(lx+1:ln,:)     = repmat(NNbar(lx+1:ln),1,int);
    NNvec(lx+adInd,:)    = sum(NNbar([1:lx,lx+adInd]))-NNworkSum;
    data.NNvec           = NNvec;

    Dvec = zeros(ln,ln,int);
    for i = 1:int
        Dtemp   = p2MakeDs(data,NNvec(:,i),XitMat(:,i),data.hw(i,:));
        Dvec(:,:,i) = Dtemp;
    end
    
    rundata = struct;
    
    rundata.Dvec = Dvec;
    rundata.tvec = data.tvec;
    rundata.compindex = data.compindex; 
    rundata.NNs = data.NNs; 
    rundata.t_import = data.t_import; 
    rundata.hw = data.hw; 
    rundata.inext = data.inext; 
    rundata.imand = data.imand; 
    rundata.Npop = data.Npop; 
    rundata.NNvec = data.NNvec; 
    
    S0 = NNvec(:,1);
    
    [data,f,g] = p2SimVax(rundata,NNvec,Dvec,dis,S0,inp3,WitMat,p2);

end

%%

function [data,f,g] = p2SimVax(data,NNvec,Dvec,dis,S0,inp3,WitMat,p2)               
    %% PARAMETERS:
    compindex = data.compindex;
    ntot          = size(data.NNs,1);
    adInd         = 3;
    lx            = ntot-4;
    NNbar         = NNvec(:,1);
    sumWorkingAge = sum(NNbar([1:lx,lx+3]));

    nc = max(struct2array(data.compindex));

    zn = zeros(ntot,1);

    t0 = data.tvec(1);
    y0_mat = zeros(ntot,nc);
    y0_mat(:,compindex.S_index(1)) = S0;
    y0_mat(:,compindex.S_index(2)) = S0;
    
%     y0 = [S0;repmat(zn,6,1);NNbar-S0;repmat(zn,nc-9,1);S0];
    y0 = reshape(y0_mat,[],1);

    Tout       = t0;
    Iout       = zn';
    Isaout     = zn';
    Issout     = zn';
    Insout     = zn';
    Hout       = zn';
    Dout       = zn';
    Wout       = [];
    hwout      = [];
    poutout    = 0;
    betamodout = 1;
%     Vout       = zn';
    rout       = 0;

    %% LOOP:

    i = 1;

    tend = data.tvec(end);

    while Tout(end)<tend 

        Wit               = WitMat(:,i);    
        NNfeed            = NNvec(:,i);
        NNfeed(NNfeed==0) = 1;
        D                 = Dvec(:,:,i);

        %Vaccination Rollout by Sector
        NNnext              = NNvec(:,i);
        NNnext(lx+[1,2])    = 1;
        NNnext([1:lx,lx+3]) = NNnext([1:lx,lx+3])/sumWorkingAge;
        NNnext(end)         = 1;
        p2.NNnext = NNnext;

        [tout,Iclass,Isaclass,Issclass,Insclass,Hclass,Dclass,pout,betamod,y0,inext]=...
         integr8(data,NNfeed,D,i,t0,tend,dis,y0,inp3,p2);

        Tout       = [Tout;tout(2:end)];  
        Iout       = [Iout;Iclass(2:end,:)];
        Isaout     = [Isaout;Isaclass(2:end,:)];
        Issout     = [Issout;Issclass(2:end,:)];
        Insout     = [Insout;Insclass(2:end,:)];
        Hout       = [Hout;Hclass(2:end,:)];
        Dout       = [Dout;Dclass(2:end,:)]; 
        W   = Wit'.*ones(length(tout),lx);
        Wout       = [Wout;W(1:end-1,:)];    
        hw  = data.hw(i,:).*ones(length(tout),lx);
        hwout      = [hwout;hw(1:end-1,:)];
        poutout    = [poutout;pout(2:end)];
        betamodout = [betamodout;betamod(2:end)];
%         Vout       = [Vout;Vclass(2:end,:)];

        if Tout(end)<tend

            data.tvec = [data.tvec(1:end-1),Tout(end),tend];

            t0 = Tout(end);

            y_mat    = reshape(y0,[ntot,nc]);%IC
            
            Xh2w                   = NNvec(1:lx,inext)-NNvec(1:lx,i);%Addition to each wp next intervention step
            Xw2h                   = -Xh2w; 
            Xw2h(Xw2h<0)           = 0;
            Xw2h                   = Xw2h./NNvec(1:lx,i);
            Xw2h(NNvec(1:lx,i)==0) = 0;

            if NNvec(lx+adInd,i)>0 %when would this not be the case?
                Xh2w(Xh2w<0) = 0;
                Xh2w         = Xh2w/NNvec(lx+adInd,i);
            else
                Xh2w         = 0;
            end

            %Move all infection statuses:
            y0w2h = y_mat(1:lx,:).*repmat(Xw2h,1,nc);%IC%number of people to be put at home (+)
            y0w2h = [-y0w2h;sum(y0w2h,1)];

            y0h2w = y_mat(lx+adInd,:);
            y0h2w = kron(y0h2w,Xh2w);
            y0h2w = [y0h2w;-sum(y0h2w,1)];

            y_mat([1:lx,lx+adInd],:) = y_mat([1:lx,lx+adInd],:)+y0w2h+y0h2w;
                
            
%             disp([t0 i inext])
            
            y0                    = reshape(y_mat,ntot*nc,1);
            i                     = inext;
        end   

    end

    %% OUTPUTS:  

    Wout  = [Wout;Wout(end,:)];
    hwout = [hwout;hwout(end,:)];
    g     = [Tout,Wout,hwout,Isaout,Issout,Insout,Hout,Dout,betamodout];
    f     = [Tout,...
             sum(Iout,2),...
             sum(Hout,2),...
             sum(Dout,2),...
             poutout,...
             betamodout,...  
             sum(Dout(:,lx+1),2),...
             sum(Dout(:,lx+2),2),...
             sum(Dout(:,[1:lx,lx+3]),2),...
             sum(Dout(:,lx+4),2)];
  
end

%%

function [tout,Iclass,Isaclass,Issclass,Insclass,Hclass,Dclass,pout,betamod,y0new,inext]=...
          integr8(data,NN0,D,i,t0,tend,dis,y0,inp3,p2)
    %% CALL:

    ntot = size(data.NNs,1);
    fun  = @(t,y)ODEs(data,NN0,D,i,t,dis,y,p2);
    sumNN0 = sum(NN0);

    if strcmp(inp3,'Elimination')
        options = odeset('Events',@(t,y)elimination(t,y,data,sumNN0,ntot,dis,i,p2));
    elseif strcmp(inp3,'Economic Closures')
        options = odeset('Events',@(t,y)reactive_closures(t,y,data,ntot,dis,i,p2));
    elseif strcmp(inp3,'School Closures')
        options = odeset('Events',@(t,y)reactive_closures(t,y,data,ntot,dis,i,p2));
    elseif strcmp(inp3,'No Closures')
        options = odeset('Events',@(t,y)unmitigated(t,y,data,ntot,dis,i,p2));
    else
        error('Unknown Mitigation Strategy!');
    end

    % try 
        [tout,yout,~,~,ie] = ode45(fun,[t0 tend],y0,options);
    % catch
    %     options.RelTol     = 1e-5;
    %     options.AbsTol     = 1e-8;
    %     [tout,yout,~,~,ie] = ode45(fun,[t0 tend],y0,options);
    % end

    y0new     = yout(end,:)'; 
    compindex = data.compindex;
%     disp(ie)
    if tout(end)<tend
        if ie <= length(data.inext)
            inext = data.inext(ie(end));
        else
            inext = i;
            y_mat    = reshape(y0new,ntot,[]);
            current_S = y_mat(:,compindex.S_index(1));
            imported = 5/sum(current_S)*current_S;
            new_I = y_mat(:,compindex.I_index(1)) + imported;
            new_s = current_S - imported;
            y_mat(:,compindex.S_index(1)) = new_s;
            y_mat(:,compindex.I_index(1)) = new_I;
            y0new = reshape(y_mat,[],1);
        end
    else
        inext = NaN;
    end

    %% OUTPUT VARIABLES:

    indices = 1:ntot;
    compindex = data.compindex;
    Ia   = yout(:,(compindex.I_index(1)-1)*ntot + indices);
    Is   = yout(:,(compindex.I_index(2)-1)*ntot + indices);
    Iav1   = yout(:,(compindex.I_index(3)-1)*ntot + indices);
    Isv1   = yout(:,(compindex.I_index(4)-1)*ntot + indices);
    Iav2   = yout(:,(compindex.I_index(5)-1)*ntot + indices);
    Isv2   = yout(:,(compindex.I_index(6)-1)*ntot + indices);
    H     = yout(:,(compindex.H_index(1)-1)*ntot + indices);
    Hv1     = yout(:,(compindex.H_index(2)-1)*ntot + indices);
    Hv2     = yout(:,(compindex.H_index(3)-1)*ntot + indices);
    D     = yout(:,(compindex.D_index(1)-1)*ntot + indices);
%     V     = yout(:,(compindex.V_index(1)-1)*ntot + indices);


    Iclass   = Ia + Is + Iav1 + Isv1 + Iav2 + Isv2; 
    Hclass   = H + Hv1 + Hv2; 
    Dclass   = D;
%     Vclass   = V;

    %% TIME-DEPENDENT PARAMETERS:

    occ   = max(1,sum(Hclass,2));
    Hmax  = p2.Hmax;
    SHmax = p2.SHmax;
    th0   = max(1,1+1.87*((occ-Hmax)/(SHmax-Hmax)));

    pd  = min(th0.*dis.pd',1);
    Th  = ((1-pd).*dis.Threc)+(pd.*dis.Thd);
    mu  = pd./Th;
    ddk = 10^5*sum(mu.*Hclass,2)/sum(NN0);

    sd_fun = @(l,b,x) (l-b)+(1-l+b)*(1+((l-1)/(1-l+b))).^(x./10);

    if i==1
        betamod = ones(size(occ));
    elseif any(i==data.imand)
        betamod = min(max(p2.sdl,sd_fun(p2.sdl,p2.sdb,ddk)), max(p2.sdl,sd_fun(p2.sdl,p2.sdb,2)));
    else
        betamod = max(p2.sdl,sd_fun(p2.sdl,p2.sdb,ddk));
    end
    
    Ip    = 10^5*sum(Iclass,2)/sum(NN0);
    if i~=5
        p4 = get_case_ID_rate(p2, Ip);
        pout = p4.*(tout>p2.t_tit).*(tout<max(p2.tpoints)); 
    else
        pout = zeros(size(tout));
    end
    
    Isaclass = pout .* (Ia + Iav1 + Iav2); 
    Issclass = pout .* (Is + Isv1 + Isv2); 
    Insclass = (1-pout) .* (Is + Isv1 + Isv2); 

end

%%

function [f] = ODEs(data,NN0,D,i,t,dis,y,p2)

    ntot = size(data.NNs,1);

    y_mat = reshape(y,ntot,[]); 


    %% IC:
    compindex = data.compindex;

    S =      y_mat(:,compindex.S_index(1));
    E =      y_mat(:,compindex.E_index(1));
    Ia =    y_mat(:,compindex.I_index(1));
    Is =    y_mat(:,compindex.I_index(2));
%     Ina =    y_mat(:,compindex.I_index(1));
%     Isa =    y_mat(:,compindex.I_index(2));
%     Ins =    y_mat(:,compindex.I_index(3));
%     Iss =    y_mat(:,compindex.I_index(4));
    H =      y_mat(:,compindex.H_index(1));
    R =      y_mat(:,compindex.R_index(1));
    Sn =     y_mat(:,compindex.S_index(2));
    Shv1 =   y_mat(:,compindex.S_index(3));
    Sv1 =    y_mat(:,compindex.S_index(4));
    Sv2 =    y_mat(:,compindex.S_index(5));
    Ev1 =    y_mat(:,compindex.E_index(2));
    Iav1 =    y_mat(:,compindex.I_index(3));
    Isv1 =    y_mat(:,compindex.I_index(4));
%     Inav1 =  y_mat(:,compindex.I_index(5));
%     Isav1 =  y_mat(:,compindex.I_index(6));
%     Insv1 =  y_mat(:,compindex.I_index(7));
%     Issv1 =  y_mat(:,compindex.I_index(8));
    Hv1 =    y_mat(:,compindex.H_index(2));
    Rv1 =    y_mat(:,compindex.R_index(2));
    Ev2 =    y_mat(:,compindex.E_index(3));
    Iav2 =    y_mat(:,compindex.I_index(5));
    Isv2 =    y_mat(:,compindex.I_index(6));
%     Inav2 =  y_mat(:,compindex.I_index(9));
%     Isav2 =  y_mat(:,compindex.I_index(10));
%     Insv2 =  y_mat(:,compindex.I_index(11));
%     Issv2 =  y_mat(:,compindex.I_index(12));
    Hv2 =    y_mat(:,compindex.H_index(3));
    Rv2 =    y_mat(:,compindex.R_index(3));
    V =    y_mat(:,compindex.V_index(1));
    B =    y_mat(:,compindex.V_index(2));
    DE =    y_mat(:,compindex.D_index(1));
    
    vaccinated_people = Sv1 + Ev1 + Iav1 + Isv1 + Hv1 + Rv1 + 1e-16;
    boosted_people = Sv2 + Ev2 + Iav2 + Isv2 + Hv2 + Rv2 + 1e-16;
    vaccine_pp = V./vaccinated_people;
    booster_pp = B./boosted_people;

    %% HOSPITAL OCCUPANCY:

    occ   = max(1,sum(H + Hv1 + Hv2)); 
    Hmax  = p2.Hmax;
    SHmax = p2.SHmax;

    %% TIME-DEPENDENT DISEASE PARAMETERS:

    %Amplitudes
    amp = (Sn+(1-dis.hv2).*(S-Sn))./S;
    th0 = max(1,1+1.87*((occ-Hmax)/(SHmax-Hmax)));

    %Probabilities
    ph = dis.ph;
    naive_adjusted_ph = amp.*ph;
    pd = min(th0*dis.pd,1);

    %Calculations
    Tsr = dis.Tsr;
    Tsh = dis.Tsh;
    Threc = dis.Threc;
    Thd = dis.Thd;
    Ts = ((1-naive_adjusted_ph).*Tsr) + (naive_adjusted_ph.*Tsh);
    Th = ((1-pd).*Threc) + (pd.*Thd);

    sig1 = dis.sig1;
    sig2 = dis.sig2;
    g1   = dis.g1;
    g2   = (1-naive_adjusted_ph)./Ts;
    g3   = (1-pd)./Th;
    h    = naive_adjusted_ph./Ts;
    mu   = pd./Th;
    nu   = dis.nu;

    %Transmission
    red  = dis.red;
    beta = dis.beta;

    %Preparedness
%     dur    = p2.dur;

    %% SELF-ISOLATION:

    if t<max(p2.tpoints) && i~=5 && t>=p2.t_tit 
        Ip = 10^5*sum(Ia+Is + Iav1+Isv1 + Iav2+Isv2)/sum(NN0);
        p4 = get_case_ID_rate(p2, Ip);
        p3 = p4;
    else       
        p3 = 0;
        p4 = 0;
    end
    
    % those not self isolating
    Ina = (1-p3) .* Ia;
    Inav1 = (1-p3) .* Iav1;
    Inav2 = (1-p3) .* Iav2;
    Ins = (1-p4) .* Is;
    Insv1 = (1-p4) .* Isv1;
    Insv2 = (1-p4) .* Isv2;

    %% FOI:

    phi = 1 .* dis.rr_infection;  %+data.amp*cos((t-32-data.phi)/(365/2*pi));

    ddk    = 10^5*sum(mu.*(H + Hv1 + Hv2))/sum(NN0);
    sd_fun = @(l,b,x) (l-b)+(1-l+b)*(1+((l-1)/(1-l+b))).^(x./10);

    if i==1
        betamod = 1;
    elseif any(i==data.imand)
        betamod = min(max(p2.sdl,sd_fun(p2.sdl,p2.sdb,ddk)), max(p2.sdl,sd_fun(p2.sdl,p2.sdb,2)));
    else
        betamod = max(p2.sdl,sd_fun(p2.sdl,p2.sdb,ddk));
    end
    
    trv1 = vaccine_pp * dis.trv1;
    trv2 = booster_pp * dis.trv2;
    
    I       = red*Ina+Ins +(1-trv1).*(red*Inav1+Insv1) + (1-trv2).*(red*Inav2+Insv2) ;    %Only non-self-isolating compartments
    foi     = phi.*beta.*betamod.*(D*(I./NN0));

%     seedvec = 10^-15*sum(data.Npop)*ones(ntot,1);
%     seed    = phi.*beta.*betamod.*(D*(seedvec./NN0));

    %% VACCINATION:

    %S (and R) ./nonVax accounts for the (inefficient) administration of vaccines to exposed, infectious and hospitalised people
    %nonVax approximates S+E+I+H+R (unvaccinated) and D (partially)
    %S (or R) ./nonVax is approximately 1 (or 0) when prevalence is low but is closer to 0 (or 1) when prevalence is high
    %nonVax is non-zero as long as uptake is less than 100%
    
    v1rates = zeros(ntot,1);
    v1rater = zeros(ntot,1);
    v2rates = zeros(ntot,1);
    v2rater = zeros(ntot,1);
    v12rates = zeros(ntot,1);
    v12rater = zeros(ntot,1);
        
    tpoints = p2.tpoints;
    if t >= tpoints(1) && t <= max(tpoints) 
        current_time = find(t>tpoints,1,'last');
        current_group = p2.group_order(current_time);
        arate = p2.arate;
        NNnext = p2.NNnext;
        targets = zeros(size(NNnext));
        if current_group == 3
            adInd = [1:(ntot-4),(ntot-4) + 3];
            targets(adInd) = 1;
        elseif current_group ~= 0 % current_group=0 in the gap between BPSV and specific/booster vaccine
            targets((ntot-4) + current_group) = 1;
        end
        
        total_to_vax = targets.*NNnext.*arate;
        if t > p2.t_vax2
            if current_group == 4
                % populate v2rate and v12rate from S, Sv1, R, Rv1
                denom2 = R+S+DE+1e-15;
                denom12 = Rv1+Sv1+1e-15;
                vrate =  total_to_vax ./ (denom12 + denom2);
                v12rates = vrate.*Sv1;
                v12rater = vrate.*Rv1;
                v2rates = vrate.*S;
                v2rater = vrate.*R;
            else
                % populate v2rate from S, R
                denom2 = R+S+DE+1e-15;
                v2rate =  total_to_vax ./ denom2;
                v2rates = v2rate.*S;
                v2rater = v2rate.*R;
            end
            
        else
            % populate v1 from S, R
            denom = R+S+DE+1e-15;
            v1rate = total_to_vax ./ denom;
            v1rates = v1rate.*S;
            v1rater = v1rate.*R;
            
        end
    end
%     Vdot =   v1rates + v1rater + v2rates + v2rater;

    Sndot=      -Sn.*foi    -(v1rates+v2rates).*Sn./S;  
    
    hrv1 = dis.hrv1;
    scv1 = dis.scv1 .* vaccine_pp;
    scv2 = dis.scv2 .* booster_pp;
    hv1 = dis.hv1 .* vaccine_pp;
    hv2 = dis.hv2 .* booster_pp;
    Ts_v1 = ((1-(1-hv1).*ph).*Tsr)  +((1-hv1).*ph.*Tsh);
    Ts_v2 = ((1-(1-hv2).*ph).*Tsr)  +((1-hv2).*ph.*Tsh);
    g2_v1 = (1-(1-hv1).*ph)./Ts_v1;
    g2_v2 = (1-(1-hv2).*ph)./Ts_v2;
    h_v1  = (1-hv1).*ph./Ts_v1;
    h_v2 = (1-hv2).*ph./Ts_v2;

    %% EQUATIONS:

    Sdot=      -v1rates - v2rates      -S.*foi  +nu.*R   ; 
    Shv1dot=    v1rates               - hrv1*Shv1   -Shv1.*foi;
    Sv1dot=    -v12rates +              hrv1*Shv1   -Sv1.*(1-scv1).*foi  + nu.*Rv1;  
    Sv2dot=     v12rates + v2rates     -Sv2.*(1-scv2).*foi  + nu.*Rv2;  

    Edot=        S.*foi   -(sig1+sig2).*E + Shv1.*foi;%
    Ev1dot=                                  Sv1.*(1-scv1).*foi  -(sig1+sig2).*Ev1;
    Ev2dot=                                  Sv2.*(1-scv2).*foi  -(sig1+sig2).*Ev2;

    Iadot=     sig1.*E     -g1.*Ina;
    Isdot=     sig2.*E     -(g2+h).*Ins;
    Iav1dot=   sig1.*Ev1   -g1.*Inav1;
    Isv1dot=   sig2.*Ev1   -(g2_v1+h_v1).*Insv1;
    Iav2dot=   sig1.*Ev2   -g1.*Inav2;
    Isv2dot=   sig2.*Ev2   -(g2_v2+h_v2).*Insv2;

    Hdot=       h.*Is         -(g3+mu).*H;
    Hv1dot=     h_v1.*Isv1    -(g3+mu).*Hv1;
    Hv2dot=     h_v2.*Isv2    -(g3+mu).*Hv2;

    Rdot=       g1.*Ia       +g2.*Is          +g3.*H      - v1rater  - v2rater  - nu.*R;
    Rv1dot=     g1.*Iav1     +g2_v1.*Isv1     +g3.*Hv1    + v1rater  - v12rater - nu.*Rv1;   
    Rv2dot=     g1.*Iav2     +g2_v2.*Isv2     +g3.*Hv2    + v2rater  + v12rater - nu.*Rv2;   

    DEdot=      mu.*H     + mu.*Hv1    + mu.*Hv2   ;  
    
    Vdot =  - dis.nuv1*V - (mu.*Hv1 + v12rater + v12rates).*vaccine_pp + v1rater + hrv1*Shv1;
    Bdot =  - dis.nuv2*B - mu.*Hv2.*booster_pp + v2rater + v2rates + v12rater + v12rates;

    %% OUTPUT:
    
    f_mat = zeros(size(y_mat));
    f_mat(:,compindex.S_index(1)) = Sdot;
    f_mat(:,compindex.E_index(1)) = Edot;
    f_mat(:,compindex.I_index(1)) = Iadot;
    f_mat(:,compindex.I_index(2)) = Isdot;
    f_mat(:,compindex.H_index(1)) = Hdot;
    f_mat(:,compindex.R_index(1)) = Rdot;
    f_mat(:,compindex.S_index(2)) = Sndot;
    f_mat(:,compindex.S_index(3)) = Shv1dot;
    f_mat(:,compindex.S_index(4)) = Sv1dot;
    f_mat(:,compindex.S_index(5)) = Sv2dot;
    f_mat(:,compindex.E_index(2)) = Ev1dot;
    f_mat(:,compindex.I_index(3)) = Iav1dot;
    f_mat(:,compindex.I_index(4)) = Isv1dot;
    f_mat(:,compindex.H_index(2)) = Hv1dot;
    f_mat(:,compindex.R_index(2)) = Rv1dot;
    f_mat(:,compindex.E_index(3)) = Ev2dot;
    f_mat(:,compindex.I_index(5)) = Iav2dot;
    f_mat(:,compindex.I_index(6)) = Isv2dot;
    f_mat(:,compindex.H_index(3)) = Hv2dot;
    f_mat(:,compindex.R_index(3)) = Rv2dot;
    f_mat(:,compindex.D_index(1)) = DEdot;
    f_mat(:,compindex.V_index(1)) = Vdot;
    f_mat(:,compindex.V_index(2)) = Bdot;
    
    f = reshape(f_mat,[],1);
    
    f(y<eps) = max(0,f(y<eps)); 

%     g = h.*Ins + qh.*Iss + h_v1.*Insv1 + qh_v1.*Issv1 + h_v2.*Insv2 + qh_v2.*Issv2;

end

%%

function [value,isterminal,direction] = elimination(t,y,data,sumN,ntot,dis,i,p2)
    
    y_mat = reshape(y,ntot,[]);
    compindex = data.compindex;
    
    S    = y_mat(:,compindex.S_index(1));
    H    = y_mat(:,compindex.H_index(1));
    Hv1    = y_mat(:,compindex.H_index(2));
    Hv2    = y_mat(:,compindex.H_index(3));
    Sn   = y_mat(:,compindex.S_index(2));
    Shv1   = y_mat(:,compindex.S_index(3));
    Sv1   = y_mat(:,compindex.S_index(4));
    Sv2   = y_mat(:,compindex.S_index(5));
    
    Ia   = y_mat(:,compindex.I_index(1));
    Is   = y_mat(:,compindex.I_index(2));
    Iav1   = y_mat(:,compindex.I_index(3));
    Isv1   = y_mat(:,compindex.I_index(4));
    Iav2   = y_mat(:,compindex.I_index(5));
    Isv2   = y_mat(:,compindex.I_index(6));
    occ   = max(1,sum(H+Hv1+Hv2)); 
    
    %% correct ph for previous infection
    
    ph = dis.ph;
    Tsr = dis.Tsr;
    Tsh = dis.Tsh;
    amp   = (Sn+(1-dis.hv2).*(S-Sn))./S;
    naive_adjusted_ph    = amp.*ph;
    Ts    = ((1-naive_adjusted_ph).*dis.Tsr) + (naive_adjusted_ph.*dis.Tsh);
    g2    = (1-naive_adjusted_ph)./Ts;
    h     = naive_adjusted_ph./Ts;
    
    %% compute fraction self isolating
    
    if t<p2.t_tit
        p3 = 0;
        p4 = 0;
    else
        Ip    = 10^5*sum(Ia+Is + Iav1+Isv1 + Iav2+Isv2)/sumN; 
        p4 = get_case_ID_rate(p2, Ip);
        p3    = p4;
    end
    
    %% if we need R values: get waning
    
    Ev1    = y_mat(:,compindex.E_index(2));
    Ev2    = y_mat(:,compindex.E_index(3));
    Rv1    = y_mat(:,compindex.R_index(2));
    Rv2    = y_mat(:,compindex.R_index(3));
    V =    y_mat(:,compindex.V_index(1));
    B =    y_mat(:,compindex.V_index(2));
    
    vaccinated_people = Sv1 + Ev1 + Iav1 + Isv1 + Hv1 + Rv1 + 1e-16;
    boosted_people = Sv2 + Ev2 + Iav2 + Isv2 + Hv2 + Rv2 + 1e-16;
    vaccine_pp = V./vaccinated_people;
    booster_pp = B./boosted_people;
    
    dis2 = dis;
    
    dis2.trv1 = dis.trv1 .* vaccine_pp;
    dis2.trv2 = dis.trv2 .* booster_pp;
    dis2.scv1 = dis.scv1 .* vaccine_pp;
    dis2.scv2 = dis.scv2 .* booster_pp;
    hv1 = dis.hv1 .* vaccine_pp;
    hv2 = dis.hv2 .* booster_pp;
    Ts_v1 = ((1-(1-hv1).*ph).*Tsr)  +((1-hv1).*ph.*Tsh);
    Ts_v2 = ((1-(1-hv2).*ph).*Tsr)  +((1-hv2).*ph.*Tsh);
    dis2.g2_v1 = (1-(1-hv1).*ph)./Ts_v1;
    dis2.g2_v2 = (1-(1-hv2).*ph)./Ts_v2;
    dis2.h_v1  = (1-hv1).*ph./Ts_v1;
    dis2.h_v2 = (1-hv2).*ph./Ts_v2;
    
    R1flag3 = -1;
    R1flag4 = -1;
    minttvec3 = min(t-(data.tvec(end-1)+0.1),0);%%!! used to be +7. why?
    minttvec4 = min(t-(data.tvec(end-1)+0.1),0);
    if ((i==2 && minttvec3==0) || (i==3  && minttvec4==0))
        Rt1 = get_R(ntot,dis2,h,g2,S+Shv1,Sv1,Sv2,...
            data.NNvec(:,3),data.Dvec(:,:,3),dis.beta,1,p3,p4);
        R1flag3 = min(1.00-Rt1,0);
        R1flag4 = min(Rt1-1.2000,0);
    end
    
    
    %% Event 1: Early Lockdown
    
    value(1)      = - abs(i-1) + min(t-p2.Tres,0);
    direction(1)  = 1;
    isterminal(1) = 1;
    
    %% Event 2: Late Lockdown
    
    value(2)      = - abs(i-1) + min(occ-0.95*p2.Hmax,0);
    direction(2)  = 1;
    isterminal(2) = 1;
    
    %% Event 3: Reopening
    
    value(3)      = - abs(i-2) + minttvec3 + R1flag3;
    direction(3)  = 0;
    isterminal(3) = 1;
    
    %% Event 4: Relockdown
    
    value(4)      = - abs(i-3) + minttvec4 + R1flag4;
    direction(4)  = 0;
    isterminal(4) = 1;
    
    %% Event 5: End
    % i is in 1:4: ival = 0
    ival = i>=5;
    % t is greater than the penultimate timepoint: tval = 0
    tval = min(t-(data.tvec(end-1)+0.1),0);
    % t is greater than the end of the vaccine rollout: otherval = 0
    otherval = min(t-max(p2.tpoints),0);
    R2flag = otherval + ival + tval;
    if ival==0 && tval==0
        if otherval~=0
            Rt2 = get_R(ntot,dis2,h,g2,S+Shv1,Sv1,Sv2,...
                data.NNvec(:,5),data.Dvec(:,:,5),dis.beta,1,0,0);
            R2flag = min(1.00-Rt2,0);
        end
    end
    
    value(5)      = R2flag; % min(t-max(p2.tpoints),0)*min(1.00-Rt2,0); 
    %measures can be removed at any stage if (Rt<1) or (after end of vaccination campaign)
    direction(5)  = 0;
    isterminal(5) = 1;
    
    %% Event 6: importation
    value(6)      =  min(t-data.t_import,0);
    direction(6)  = 1;
    isterminal(6) = 1;
    
end 

function [value,isterminal,direction] = reactive_closures(t,y,data,ntot,dis,i,p2)
    
    y_mat = reshape(y,ntot,[]);
    compindex = data.compindex;

    
    S    = y_mat(:,compindex.S_index(1));
    H    = y_mat(:,compindex.H_index(1));
    Hv1    = y_mat(:,compindex.H_index(2));
    Hv2    = y_mat(:,compindex.H_index(3));
    Sn   = y_mat(:,compindex.S_index(2));
    Shv1   = y_mat(:,compindex.S_index(3));
    Sv1   = y_mat(:,compindex.S_index(4));
    Sv2   = y_mat(:,compindex.S_index(5));
    
    Is   = y_mat(:,compindex.I_index(2));
    Isv1   = y_mat(:,compindex.I_index(4));
    Isv2   = y_mat(:,compindex.I_index(6));
    occ   = max(1,sum(H+Hv1+Hv2)); 
    
    Hmax  = p2.Hmax;
    SHmax = p2.SHmax;
    amp   = (Sn+(1-dis.hv2).*(S-Sn))./S;
    th0   = max(1,1+1.87*((occ-Hmax)/(SHmax-Hmax)));
    ph = dis.ph;
    Tsr = dis.Tsr;
    Tsh = dis.Tsh;
    Threc = dis.Threc;
    Thd = dis.Thd;
    naive_adjusted_ph    = amp.*ph;
    pd    = min(th0*dis.pd,1);
    Ts    = ((1-naive_adjusted_ph).*Tsr) + (naive_adjusted_ph.*Tsh);
    Th    = ((1-pd).*Threc)+(pd.*Thd);
    g2    = (1-naive_adjusted_ph)./Ts;
    g3    = (1-pd)./Th;
    h     = naive_adjusted_ph./Ts;
    mu    = pd./Th;
%     h_v1  = dis.h_v1;
%     dur   = p2.dur;
%     qh    = ph./(Ts-dur);

    %% get waning for R values and H derivatives
    
    Ev1    = y_mat(:,compindex.E_index(2));
    Ev2    = y_mat(:,compindex.E_index(3));
    Iav1   = y_mat(:,compindex.I_index(3));
    Iav2   = y_mat(:,compindex.I_index(5));
    Rv1    = y_mat(:,compindex.R_index(2));
    Rv2    = y_mat(:,compindex.R_index(3));
    V =    y_mat(:,compindex.V_index(1));
    B =    y_mat(:,compindex.V_index(2));
    
    vaccinated_people = Sv1 + Ev1 + Iav1 + Isv1 + Hv1 + Rv1 + 1e-16;
    boosted_people = Sv2 + Ev2 + Iav2 + Isv2 + Hv2 + Rv2 + 1e-16;
    vaccine_pp = V./vaccinated_people;
    booster_pp = B./boosted_people;
    
    dis2 = dis;
    
    dis2.trv1 = dis.trv1 .* vaccine_pp;
    dis2.trv2 = dis.trv2 .* booster_pp;
    dis2.scv1 = dis.scv1 .* vaccine_pp;
    dis2.scv2 = dis.scv2 .* booster_pp;
    hv1 = dis.hv1 .* vaccine_pp;
    hv2 = dis.hv2 .* booster_pp;
    Ts_v1 = ((1-(1-hv1).*ph).*Tsr)  +((1-hv1).*ph.*Tsh);
    Ts_v2 = ((1-(1-hv2).*ph).*Tsr)  +((1-hv2).*ph.*Tsh);
    dis2.g2_v1 = (1-(1-hv1).*ph)./Ts_v1;
    dis2.g2_v2 = (1-(1-hv2).*ph)./Ts_v2;
    dis2.h_v1  = (1-hv1).*ph./Ts_v1;
    dis2.h_v2 = (1-hv2).*ph./Ts_v2;

    Hdot   =         h.*Is   -(g3+mu).*H;
    Hv1dot = dis2.h_v1.*Isv1 -(g3+mu).*Hv1;
    Hv2dot = dis2.h_v2.*Isv2 -(g3+mu).*Hv2;
    
    occdot = sum(Hdot+Hv1dot+Hv2dot);
    r      = occdot/occ;
    Tcap   = t + log(p2.Hmax/occ)/r;
    Tcap   = Tcap-4;
    
    
    %% Event 1: Response Time
    
    value(1)      = - abs(i-1) + min(t-p2.Tres,0) ;
    direction(1)  = 1;
    isterminal(1) = 1;
    
    %% Event 2: Early Lockdown
    
    value(2)     = - abs((i-2)*(i-4)) + min(t-(data.tvec(end-1)+0.1),0) + min(t-Tcap,0);
    direction(2) = 1;
    if r>0.025
        isterminal(2) = 1;
    else
        isterminal(2) = 0;
    end
    
    %% Event 3: Late Lockdown
    
    value(3)      = - abs((i-1)*(i-2)*(i-4)) + min(t-(data.tvec(end-1)+0.1),0) + min(occ-0.95*p2.Hmax,0);
    direction(3)  = 1;
    isterminal(3) = 1;
    
    %% Event 4: Reopening
    
    value(4)      = abs(i-3) + abs(min(t-(data.tvec(end-1)+7),0)) + max(0,occ-p2.thl);
    direction(4)  = -1;
    isterminal(4) = 1;
    
    %% Event 5: End
    
    % not in hard lockdown: i = 1, 2 or 4; ivals = 0
    ivals = -abs((i-1)*(i-2)*(i-4));
    % have passed penultimate timepoint: tval = 0
    tval = min(t-(data.tvec(end-1)+0.1),0);
    % (low growth rate OR occupancy is low) AND have reached end of vaccine
    % rollout: otherval = 0
    otherval = -abs(min(0.025-r,0)*max(0,occ-p2.thl)) + min(t-max(p2.tpoints),0);
    R2flag = otherval + ivals + tval;
    if ivals==0 && tval==0
        if otherval~=0
        % only compute R if R2flag is not already 0 and ivals and tval
        % conditions are both met
            Rt2    = get_R(ntot,dis2,h,g2,S+Shv1,Sv1,Sv2,data.NNvec(:,5),data.Dvec(:,:,5),dis.beta,1,0,0);
            R2flag = min(1.00-Rt2,0);
        end
    end
    
    value(5)      = R2flag; 
    %measures can be removed if (not in hard lockdown) and ((Rt<1) or (after end of vaccination campaign and below 25% occupancy or low growth rate))
    direction(5)  = 0;
    isterminal(5) = 1;
    
    %% Event 6: importation
    value(6)      =  min(t-data.t_import,0);
    direction(6)  = 1;
    isterminal(6) = 1;
    
end

function [value,isterminal,direction] = unmitigated(t,y,data,ntot,dis,i,p2)
    

    y_mat = reshape(y,ntot,[]);
    compindex = data.compindex;

    S    = y_mat(:,compindex.S_index(1));
    H    = y_mat(:,compindex.H_index(1));
    Hv1    = y_mat(:,compindex.H_index(2));
    Hv2    = y_mat(:,compindex.H_index(3));
    Sn   = y_mat(:,compindex.S_index(2));
    Shv1   = y_mat(:,compindex.S_index(3));
    Sv1   = y_mat(:,compindex.S_index(4));
    Sv2   = y_mat(:,compindex.S_index(5));
    
    occ  = max(1,sum(H+Hv1+Hv2)); 
        
    amp  = (Sn+(1-dis.hv2).*(S-Sn))./S;
    ph = dis.ph;
    Tsr = dis.Tsr;
    Tsh = dis.Tsh;
    naive_adjusted_ph   = amp.*ph;
    Ts   = ((1-naive_adjusted_ph).*Tsr) + (naive_adjusted_ph.*Tsh);
    g2   = (1-naive_adjusted_ph)./Ts;
    h    = naive_adjusted_ph./Ts;
    
    %% get waning for R
    
    Ev1    = y_mat(:,compindex.E_index(2));
    Ev2    = y_mat(:,compindex.E_index(3));
    Iav1   = y_mat(:,compindex.I_index(3));
    Isv1   = y_mat(:,compindex.I_index(4));
    Iav2   = y_mat(:,compindex.I_index(5));
    Isv2   = y_mat(:,compindex.I_index(6));
    Rv1    = y_mat(:,compindex.R_index(2));
    Rv2    = y_mat(:,compindex.R_index(3));
    V =    y_mat(:,compindex.V_index(1));
    B =    y_mat(:,compindex.V_index(2));
    
    vaccinated_people = Sv1 + Ev1 + Iav1 + Isv1 + Hv1 + Rv1 + 1e-16;
    boosted_people = Sv2 + Ev2 + Iav2 + Isv2 + Hv2 + Rv2 + 1e-16;
    vaccine_pp = V./vaccinated_people;
    booster_pp = B./boosted_people;
    
    dis2 = dis;
    
    dis2.trv1 = dis.trv1 .* vaccine_pp;
    dis2.trv2 = dis.trv2 .* booster_pp;
    dis2.scv1 = dis.scv1 .* vaccine_pp;
    dis2.scv2 = dis.scv2 .* booster_pp;
    hv1 = dis.hv1 .* vaccine_pp;
    hv2 = dis.hv2 .* booster_pp;
    Ts_v1 = ((1-(1-hv1).*ph).*Tsr)  +((1-hv1).*ph.*Tsh);
    Ts_v2 = ((1-(1-hv2).*ph).*Tsr)  +((1-hv2).*ph.*Tsh);
    dis2.g2_v1 = (1-(1-hv1).*ph)./Ts_v1;
    dis2.g2_v2 = (1-(1-hv2).*ph)./Ts_v2;
    dis2.h_v1  = (1-hv1).*ph./Ts_v1;
    dis2.h_v2 = (1-hv2).*ph./Ts_v2;

    %% Event 1: Response Time
    
    value(1)      = - abs(i-1) + min(t-p2.Tres,0);
    direction(1)  = 1;
    isterminal(1) = 1;
    
    %% Event 2: Late Lockdown
    
    value(2)      = - abs(i-1) + min(occ-0.95*p2.Hmax,0);
    direction(2)  = 1;
    isterminal(2) = 1;

    %% Event 3: End
    
    % not in i>=5; ivals = 0
    ivals = -floor(i/5);
    % have passed penultimate timepoint: tval = 0
    tval = min(t-(data.tvec(end-1)+0.1),0);
    % have reached end of vaccine rollout: otherval = 0
    otherval = min(t-max(p2.tpoints),0);
    R2flag = otherval + ivals + tval;
    if ivals==0 && tval==0 
        if otherval~=0
        % only compute R if R2flag is not already 0 and ivals and tval
        % conditions are both met
            Rt2    = get_R(ntot,dis2,h,g2,S+Shv1,Sv1,Sv2,data.NNvec(:,5),data.Dvec(:,:,5),dis.beta,1,0,0);
            R2flag = min(1.00-Rt2,0);
        end
    end
    
    value(3)      = R2flag; 
    %measures can be removed at any stage if (Rt<1) or (after end of vaccination campaign)
    direction(3)  = 0;
    isterminal(3) = 1;
    
    %% Event 6: importation
    value(4)      =  min(t-data.t_import,0);
    direction(4)  = 1;
    isterminal(4) = 1;
    
end

