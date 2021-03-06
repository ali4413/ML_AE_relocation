close all
clear all
clc

%% perturbation to arrival picking
pt = 1; % microsecond
% NOTE: result may vary depends on the randomly generated purturbation. The overall trend should be the same.

%% ========================= load training data ===========================
load('AE_train.mat')

load('SVMmodels.mat')

face_clrs = {[.5 .5 .5],[43,131,186]./255,[215,25,28]./255};
edge_clrs = 'none';

L = 218;
H = 200;
mksz = 5;

if pt == 0
    t_arri_indx_data_repeat_peturb(2:11,:) = t_arri_indx_data_repeat(2:11,:);
    t_arri_indx_train_peturb(2:11,:) = t_arri_indx_train(2:11,:);
else
    pterb = randi(round(pt*40),10,8)-round(pt*40)/2;
    t_arri_indx_data_repeat_peturb =t_arri_indx_data_repeat;
    t_arri_indx_data_repeat_peturb(2:11,:) = pterb(1:10,:)+t_arri_indx_data_repeat_peturb(2:11,:);
    pterb = randi(round(pt*40),10,56)-round(pt*40)/2;
    t_arri_indx_train_peturb =t_arri_indx_train;
    t_arri_indx_train_peturb(2:11,:) = pterb(1:10,:)+t_arri_indx_train_peturb(2:11,:);
end

%% repeatability

output = [];
xpredict_repeat = xregressionSVMmodel.predictFcn(t_arri_indx_data_repeat_peturb);
output(1,:) = xpredict_repeat; % x
output(2,:) = L - output(1,:); % y
zpredict_repeat = zregressionSVMmodel.predictFcn(t_arri_indx_data_repeat_peturb);
output(3,:) = zpredict_repeat; % z
outAvg_repeat = [output(1,:);output(3,:)];
errs_repeat  = abs(outAvg_repeat-actual_coor_data_repeat);
x_err_repeat = errs_repeat(1,:);
z_err_repeat = errs_repeat(2,:);

disp('------------- Repeatability Errors --------------')
disp('       Mean       Max        Min')
disp(['x   ' num2str([mean(x_err_repeat),max(x_err_repeat),min(x_err_repeat)])])
disp(['z   ' num2str([mean(z_err_repeat),max(z_err_repeat),min(z_err_repeat)])])
disp('-------------------------------------------------')


%% get R^2

output = [];
zpredict = zregressionSVMmodel.predictFcn(t_arri_indx_train_peturb);
output(3,:) = zpredict; % z
xpredict = xregressionSVMmodel.predictFcn(t_arri_indx_train_peturb);
output(1,:) = xpredict; % x
output(2,:) = L - output(1,:); % y


%% plot fitting results
outAvg_all = [output(1,:);output(3,:)];
perfAvg_all_x = sqrt(sum((actual_coor_train(1,:)-outAvg_all(1,:)).^2)/length(t_arri_indx_train_peturb));
perfAvg_all_z = sqrt(sum((actual_coor_train(2,:)-outAvg_all(2,:)).^2)/length(t_arri_indx_train_peturb));

x_on_fault = (L+outAvg_all(1,:)-(L-outAvg_all(1,:)))/2;
dist_on_fault = sqrt(2)*(L-x_on_fault);

x_on_fault_train = (L+actual_coor_train(1,:)-(L-actual_coor_train(1,:)))/2;
dist_on_fault_train = sqrt(2)*(L-x_on_fault_train);

figure(11)
hold on
plot([0,300],[0,300],'k:','LineWidth',2)
plot(dist_on_fault_train,dist_on_fault,'ko','markerfacecolor',face_clrs{1},'markerEdgecolor',edge_clrs,'MarkerSize',mksz,'Linewidth',1.5)
box on
axis square
legend('Target:Output = 1:1','Training points','Testing output','Repeatability testing output','Location','SouthEast')
ylabel('Model output x (mm)');
xlabel('Training data x (mm)');

% confidance interval
xdata = dist_on_fault_train;
ydata = dist_on_fault;
[p,S] = polyfit(xdata,ydata,1);
xRS = 1 - (S.normr/norm(ydata - mean(ydata)))^2
% Compute the real roots and determine the extent of the data.
r = roots(p)'; % Roots as a row vector.
real_r = r(imag(r) == 0); 	% Real roots.
% Assure that the data are row vectors.
xdata = reshape(xdata,1,length(xdata));
ydata = reshape(ydata,1,length(ydata));
% Extent of the data.
mx = min([real_r,xdata]);
Mx = max([real_r,xdata]);
my = min([ydata,0]);
My = max([ydata,0]);
% Scale factors for plotting.
sx = 0.05*(Mx-mx);
sy = 0.05*(My-my);

% Plot the data, the fit, and the roots.
xfit = mx-sx:0.1:Mx+sx;
yfit = polyval(p,xfit);
% hfit = plot(xfit,yfit,'b-','LineWidth',2);
axis([0 300 0 300])
% Add prediction intervals to the plot.
[Y,DELTA] = polyconf(p,xfit,S,'alpha',0.5);
hconf = plot(xfit,Y+DELTA,'b-');
plot(xfit,Y-DELTA,'b-')

figure(12)
hold on
plot([0,200],[0,200],'k:','LineWidth',2)
plot(actual_coor_train(2,:),outAvg_all(2,:),'ko','markerfacecolor',face_clrs{1},'markerEdgecolor',edge_clrs,'MarkerSize',mksz,'Linewidth',1.5)
box on
axis square
ylabel('Model output z (mm)');
xlabel('Training data z (mm)');
legend('Target:Output = 1:1','Training points','Testing output','Repeatability testing output','Location','SouthEast')

% confidance interval
xdata = actual_coor_train(2,:);
ydata = outAvg_all(2,:);
[p,S] = polyfit(xdata,ydata,1);
zRS = 1 - (S.normr/norm(ydata - mean(ydata)))^2
% Compute the real roots and determine the extent of the data.
r = roots(p)'; % Roots as a row vector.
real_r = r(imag(r) == 0); 	% Real roots.
% Assure that the data are row vectors.
xdata = reshape(xdata,1,length(xdata));
ydata = reshape(ydata,1,length(ydata));
% Extent of the data.
mx = min([real_r,xdata]);
Mx = max([real_r,xdata]);
my = min([ydata,0]);
My = max([ydata,0]);
% Scale factors for plotting.
sx = 0.05*(Mx-mx);
sy = 0.05*(My-my);

% Plot the data, the fit, and the roots.
xfit = mx-sx:0.1:Mx+sx;
yfit = polyval(p,xfit);
% hfit = plot(xfit,yfit,'b-','LineWidth',2);
axis([0 200 0 200])
% Add prediction intervals to the plot.
[Y,DELTA] = polyconf(p,xfit,S,'alpha',0.5);
hconf = plot(xfit,Y+DELTA,'b-');
plot(xfit,Y-DELTA,'b-')

%% print
% print(figure(11),'-dpdf','-r300',['./training_SVM_x_perturb_' num2str(pt) '_us.pdf'])
% print(figure(12),'-dpdf','-r300',['./training_SVM_z_perturb_' num2str(pt) '_us.pdf'])