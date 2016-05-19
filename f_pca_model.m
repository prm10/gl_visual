function [P,E,spe_limit,ts_limit]=f_pca_model(input_x,L,confidence)
[P,S,~] = svd(input_x'*input_x/(size(input_x,1)-1));
E=diag(S);

N=size(input_x,2);
F_a=finv(confidence,L,N-L);
ts_limit=(N-1)*(N+1)*L/N/(N-L)*F_a;
theta1=sum(E(L+1:end));
theta2=sum(E(L+1:end).^2);
theta3=sum(E(L+1:end).^3);
h0=1-2/3*theta1*theta3/theta2^2;
c_a=norminv(1-confidence/2,0,1);
spe_limit=theta1*(c_a*h0*sqrt(2*theta2)/theta1+1+theta2*h0*(h0-1)/theta1^2).^(1/h0);
end