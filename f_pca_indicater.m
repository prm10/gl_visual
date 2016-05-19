function [output_y,spe,ts]=f_pca_indicater(input_x,P,E,L)
output_y=input_x*P(:,1:L);
ts=output_y.^2*(1./E(1:L));
spe=sum((input_x*(P(:,L+1:end)*P(:,L+1:end)')).^2,2);
end