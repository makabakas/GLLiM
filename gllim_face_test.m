function gllim_face_test(images,poses)
    [~,N]=size(images);
    images_mat=reshape(images,[64,64,N]);

    T=8; % Number of tests

    % Subsample images to 32x32
    images=reshape(images_mat(1:2:64,1:2:64,:),[32*32,N]);
    [D,N]=size(images);

    K=25; % K=25 affine components
    cstr.Sigma='d*'; % Isotropic equal constraints on Sigma

    t_all=poses;
    y_all=images;

    %%%%%%%%%%% Pick N-T training data %%%%%%%%%%%
    rand_idx = randperm(N); % Shuffle indexes
    t=t_all(:,rand_idx(1:N-T)); % LxN-T Select N-T training parameters
    y=y_all(:,rand_idx(1:N-T)); % DxN-T Select N-T training observations

    %%%%%%%%% Pick T remaining test data %%%%%%%%%
    tt=t_all(:,rand_idx(N-T+1:N)); % LxT Select T test parameters
    yt=y_all(:,rand_idx(N-T+1:N)); % DxT Select T test observations


    %%%% Training a GLLiM model using Lw=0 or Lw=1 %%%
    maxiter = 20;
    Lw=0;
    [gthetaLw0,~]=gllim(t,y, K,'Lw',Lw,'cstr',cstr,'maxiter',maxiter ,'verb',1);
    Lw=1;
    [gthetaLw1,~]=gllim(t,y,K,'Lw',Lw,'cstr',cstr,'maxiter',maxiter ,'verb',1);

%     %%%% Training a SLLiM model using Lw=0 or Lw=1 %%%
%     Lw=0;
%     [sthetaLw0,sphiLw0,~]=sllim(t,y, K,'Lw',Lw,'cstr',cstr,'maxiter',maxiter ,'verb',1);
%     Lw=2;
%     [sthetaLw1,sphiLw1,~]=sllim(t,y,K,'Lw',Lw,'cstr',cstr,'maxiter',maxiter ,'verb',1);

    % Pose Estimation:
    % GLLiM
    gpos_est_Lw0=gllim_inverse_map(yt,gthetaLw0,0); % Lw=0
    gerr_Lw0=sqrt(sum((gpos_est_Lw0(1:2,:)-tt).^2));
    gpos_est_Lw1=gllim_inverse_map(yt,gthetaLw1,0); % Lw=1
    gerr_Lw1=sqrt(sum((gpos_est_Lw1(1:2,:)-tt).^2));
    
    fprintf(1,'GLLiM: Mean pose estimation error using Lw=0: %g+/-%g\n',...
               mean(gerr_Lw0),std(gerr_Lw0));
    fprintf(1,'GLLiM: Mean pose estimation error using Lw=1: %g+/-%g\n',...
               mean(gerr_Lw1),std(gerr_Lw1));
    fprintf(1,'\n');
    
%     % SLLiM
%     spos_est_Lw0=sllim_inverse_map(yt,sthetaLw0,sphiLw0,0); % Lw=0
%     serr_Lw0=sqrt(sum((spos_est_Lw0(1:2,:)-tt).^2));
%     spos_est_Lw1=sllim_inverse_map(yt,sthetaLw1,sphiLw1,0); % Lw=1
%     serr_Lw1=sqrt(sum((spos_est_Lw1(1:2,:)-tt).^2));
% 
%     fprintf(1,'SLLiM: Mean pose estimation error using Lw=0: %g+/-%g\n',...
%                mean(serr_Lw0),std(serr_Lw0));
%     fprintf(1,'SLLiM: Mean pose estimation error using Lw=1: %g+/-%g\n',...
%                mean(serr_Lw1),std(serr_Lw1));
%     fprintf(1,'\n');
%     pause

    fig=figure;clf(fig);
    colormap('Gray');
    for t=1:T
        % Test
        subplot(T,3,3*t-2);
        imagesc(reshape(yt(:,t),32,32));
        % Face Reconstruction (Lw=0)
        face_est_Lw0=gllim_forward_map(gpos_est_Lw0(:,t),gthetaLw0,0);
        subplot(T,3,3*t-1);
        imagesc(reshape(face_est_Lw0,32,32));
        % Face Reconstruction (Lw=1)
        face_est_Lw1=gllim_forward_map(gpos_est_Lw1(:,t),gthetaLw1,0);
        subplot(T,3,3*t);
        imagesc(reshape(face_est_Lw1,32,32));
    end

    % Compute min and max values of the latent variable on the training set
    invmap=gllim_inverse_map(y,gthetaLw1,0);
    min_l=min(invmap(3,:));
    max_l=max(invmap(3,:));

    %%% Face reconstruction while varying latent variable value:
    % Number of latent variable values used for reconstruction:
    nlights=16;

    step_l=(max_l-min_l)/(nlights-1);
    fig=figure;clf(fig);
    colormap('Gray');
    for t=1:T
        for l=1:nlights
            li=min_l+(l-1)*step_l;
            face_est_Lw1=gllim_forward_map([tt(:,t);li],gthetaLw1,0);
            subplot(8,16,l+16*(t-1));
            imagesc(reshape(face_est_Lw1,32,32));
        end
    end

end
