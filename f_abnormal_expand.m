function normal_bool=f_abnormal_expand(data_st)
n=size(data_st,1);
processed=false(n,1);
normal_bool=true(n,1);
abnormal=find(data_st>3);
for i1=abnormal'
    if ~processed(i1)
        j1=i1;
        j2=i1;
        while j1>=1 && data_st(j1)>1
            j1=j1-1;
        end
        while j2<=n && data_st(j2)>1
            j2=j2+1;
        end
        normal_bool(j1+1:j2-1)=false;
        processed(j1+1:j2-1)=true;
    end
end


