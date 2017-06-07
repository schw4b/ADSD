%% by simon schwab, 2017
PATH = '~/Data/ADSD-nbook/';

%% select all craddock rois that overlap >10% with AAL target regions
niiaal  = load_nii([PATH 'nii/aal.nii']);
niicrad = load_nii([PATH 'nii/rtcorr05_2level_200.nii']);

labels_crad = 1:200;
labels_aal  = unique(sort(niiaal.img(:)));
labels_aal = labels_aal(2:end)';
p = 0.06;

aalsize=nan(1, length(labels_aal));
myrois = [];
n = 1;
for i = labels_aal
    
    x = niiaal.img==i;
    aalsize(i)=sum(x(:));
    
    x = niicrad.img(niiaal.img==i);
    mycrad = unique(sort(x(:)))';
    
    for c = mycrad
        if sum(x == c) > p*aalsize(i)
            myrois(n) = c;
            n = n + 1;
        end        
    end 
end

myrois = unique(sort(myrois));
myrois = myrois(myrois > 0);
length(myrois)

% to remove ROIS in brainstem,  increase
% in p from 5% to 6%.
% myrois(myrois == 199) = [];
% myrois(myrois == 53) = [];

length(myrois)

%% write craddock atlas selection
for i = labels_crad    
    if ~ismember(i, myrois) % remove region
        niicrad.img(niicrad.img==i) = 0;
    end        
end

save_nii(niicrad,[PATH 'nii/sel_rtcorr05_2level_200.nii'])

%% Masks ROIS with GM mask for two subjects as example, and mean GM mask
% using same threshold of >70% as used in BOLD signal extraction from ROIs
% ADSD_01: SD with strong athrophy in left temp lope
% ADSD_01: AD with atrophy in hippocampus

nii = load_nii([PATH 'nii/sel_rtcorr05_2level_200.nii']);
gmSD = load_nii([PATH 'nii/rwrp1ADSD_01_t1_mpr_ns_sag_1mm_iso.nii']);
nii.img(gmSD.img < 0.7) = 0;
save_nii(nii,[PATH 'nii/rois_ADSD_01.nii'])

nii = load_nii([PATH 'nii/sel_rtcorr05_2level_200.nii']);
gmAD = load_nii([PATH 'nii/rwrp1ADSD_07_t1_mpr_ns_sag_1mm_iso.nii']);
nii.img(gmAD.img < 0.7) = 0;
save_nii(nii,[PATH 'nii/rois_ADSD_07.nii'])

nii = load_nii([PATH 'nii/sel_rtcorr05_2level_200.nii']);
gm = load_nii([PATH 'nii/rmean_t1_wrp1_N62.nii']);
nii.img(gm.img < 0.7) = 0;
save_nii(nii,[PATH 'nii/rois_meanGM.nii'])

%% write selection of cradd rois
dlmwrite([PATH 'Cradd_tmp_labels.txt'],myrois, 'delimiter',' ')

%% slices for mricron
x=54:2:72;
length(x)
sprintf('%d,', x)

%% assign AAL labels to craddock
niicrad = load_nii([PATH 'nii/sel_rtcorr05_2level_200.nii']);
niiaal  = load_nii([PATH 'nii/aal.nii']);

legend = nan(length(myrois), 2);
c = 1;
for i=myrois
    legend(c, 1) = i;
    x = niiaal.img(niicrad.img == i);
    legend(c,2) = mode(x(x>0));
    c=c+1;
end
dlmwrite([PATH 'Cradd_AAL_mapping.txt'],legend, 'delimiter',' ')

%% select rois with edges, mask with mean gm mask
cradd = load_nii([PATH 'nii/sel_rtcorr05_2level_200.nii']);
gm =  load_nii([PATH 'nii/rmean_t1_wrp1_N62.nii']);

SD = cradd;
AD = cradd;

cd(PATH)
sd = textread('SDedges_perm.txt')';
sd = reshape(textread('SDedges_perm.txt')', [length(sd)/2, 2]);
ad = textread('ADedges_perm.txt')';
ad = reshape(textread('ADedges_perm.txt')', [length(ad)/2, 2]);

del = myrois(~ismember(myrois, sd));
for r = del
    SD.img(cradd.img==r) = 0;
    SD.img(gm.img<0.7) = 0;
end

del = myrois(~ismember(myrois, ad));
for r = del   
    AD.img(cradd.img==r) = 0;
    AD.img(gm.img<0.7) = 0;
end

save_nii(SD, 'nii/SDedges_perm.nii')
save_nii(AD, 'nii/ADedges_perm.nii')