function [SPE,T2,t]=f_pca_indicater(y,P,te,m)
t=y*P(:,1:m);
T2=t.^2*(1./te(1:m));
SPE=sum((y*(P(:,m+1:end)*P(:,m+1:end)')).^2,2);
end