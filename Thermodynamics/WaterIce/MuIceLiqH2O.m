function mu = MuIceLiqH2O(P_MPa,T_K)

%from Choukron and Grasset, 2010, Table I
global parms nsteps
nsteps = 40;
DEBUG = 0;
% columns: liquid, Ih, II, III, V, VI
parms = [
    0           0           0           0       0
    251.16  209.9   NaN     -21.58  -18.79
    252.32  300     NaN     NaN    -21.82
    256.16  350.1   -13.2   -18.01   -16.19
    256.16  350.1   -13.1   -18.30  -17.43
    273.31 632.4   -16.2   -19.34  -18.78
    ];
dmu = getDeltaMu(P_MPa,T_K);
lP = length(P_MPa);
lT = length(T_K);
phase = NaN*ones(lP,lT);
for iP = 1:lP
    for iT = 1:lT
        thisset = squeeze(dmu(:,iP,iT));
        phase(iP,iT) = find(thisset == min(thisset));
        if DEBUG
            thisset           
        end
        if dmu(phase(iP,iT),iP,iT)>0
           phase(iP,iT) = 0;
        end
    end
end
phase(phase==5) = 6;
phase(phase==4) = 5;
mu = dmu;

function deltaMu = getDeltaMu(P_MPa,T_K)
global parms nsteps
    Po = parms(:,2);
    To = parms(:,1);
    So = parms(:,5)./0.01815;
    for i=1:6
        Ho(i)=parms(i,1).*parms(i,5)./0.01815;
    end
    deltaMu = NaN*ones(length(P_MPa),length(T_K),5);
    
    nP = length(P_MPa);
    nT = length(T_K);
    intVspdP_S = zeros(nP,nT);
    intVspdP_L = intVspdP_S;
    intCpdT_S = intVspdP_S;
    intCpdT_L = intVspdP_S;
    intCpTdT_S = intVspdP_S;
    intCpTdT_L = intVspdP_S;    
    Vsp_S = intVspdP_S;
    Vsp_L = intVspdP_S;
    Cp_S = intVspdP_S;
    Cp_L = intVspdP_S;
    
for ind = 2:6
    for iP = 1:length(P_MPa)
        if Po(ind) ~= P_MPa(iP)
            P_int_MPa =linspace(Po(ind),P_MPa(iP),nsteps); % set up integrating range for pressure
        else
            P_int_MPa = linspace(Po(ind)-1E-6,P_MPa(iP),nsteps);
        end
        for iPi = 1:length(P_int_MPa) % get liquid and solid state specific volumes
            Vsp_S(iPi,:) = 1E3*getVspChoukroun2010(P_int_MPa(iPi),T_K,ind);    
            Vsp_L(iPi,:) = 1E3*getVspChoukroun2010(P_int_MPa(iPi),T_K,1);    
        end
        for iT = 1:length(T_K)
            if To(ind) ~= T_K(iT)
                T_int_K = linspace(To(ind),T_K(iT),nsteps);  % set up integrating range for temperature
            else
                T_int_K = linspace(To(ind)-1E-6,T_K(iT),nsteps);
            end
                for iTi = 1:length(T_int_K) % get liquid and solid state heat capacities for integration
                    Cp_S(:,iTi) = CpH2O_Choukroun(P_MPa,T_int_K(iTi),ind);
                    Cp_L(:,iTi) = getCpH2O_liquidChoukroun2010(T_int_K(iTi));
                end            
            intVspdP_S(iP,iT) = integrate(P_int_MPa,Vsp_S(:,iT),[Po(ind) P_MPa(iP)]);
            intVspdP_L(iP,iT) = integrate(P_int_MPa,Vsp_L(:,iT),[Po(ind) P_MPa(iP)]);
            intCpdT_S(iP,iT) = integrate(T_int_K,Cp_S,[To(ind) T_K(iT)]);
            intCpdT_L(iP,iT) = integrate(T_int_K,Cp_L,[To(ind) T_K(iT)]);
            intCpTdT_S(iP,iT) = integrate(T_int_K,Cp_S./T_int_K,[To(ind) T_K(iT)]);
            intCpTdT_L(iP,iT) = integrate(T_int_K,Cp_L./T_int_K,[To(ind) T_K(iT)]);
        end
    end
    muS(ind-1,:,:) = 0.5.*Ho(ind) + intCpdT_S -T_K.*(0.5.*So(ind) +intCpTdT_S)+intVspdP_S;
    muL(ind-1,:,:) = -0.5.*Ho(ind) + intCpdT_L -T_K.*(-0.5.*So(ind) +intCpTdT_L)+intVspdP_L;
end
deltaMu = muS - muL;


function integral = integrate(x,y,range)
    pp = spline(x,y);
    integral = diff(fnval(fnint(pp),range));
