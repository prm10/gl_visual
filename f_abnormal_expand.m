function normal_bool=f_abnormal_expand(data_st,yu1,yu2,expand)
n=size(data_st,1);
processed=false(n,1);
normal_bool=true(n,1);
abnormal=find(data_st>yu1);
for i1=abnormal'
    if ~processed(i1)
        j1=i1;
        j2=i1;
        while j1>=1 && data_st(j1)>yu2
            j1=j1-1;
        end
        while j2<=n && data_st(j2)>yu2
            j2=j2+1;
        end
        j1=max(1,j1-expand);
        j2=min(n,j2+expand);
        normal_bool(j1+1:j2-1)=false;
        processed(j1+1:j2-1)=true;
    end
end


