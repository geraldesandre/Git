function [estimationError measurementError filterError] = needleSteeringFilter_AUKF_Offline_Planar_EstimatedK(datasetFile, initialState, initialUncertainty, noise)

%% Load the simulation dataset

load(datasetFile);
nStep = length(U1);
startStep = 1;


%% Load the main parameters

posXInitial = initialState(1);
posYInitial = initialState(2);
thetaInitial = initialState(3);
kInitial = initialState(4);

posXUncertainty = initialUncertainty(1);
posYUncertainty = initialUncertainty(2);
thetaUncertainty = initialUncertainty(3);
kUncertainty = initialUncertainty(4);

kNoise = noise(1);
uNoise = noise(2);
pXNoise = noise(3);
pYNoise = noise(4);

%% Initialize variables for storing the estimated values

posXEstimate = zeros(1,nStep);
posYEstimate = zeros(1,nStep);
thetaEstimate = zeros(1,nStep);

for iStep = 1:nStep
    if(iStep > 1)
        augmentedState = [posXEstimate(iStep-1) ; posYEstimate(iStep-1); thetaEstimate(iStep-1); avgK; zeros(4,1)];
    else
        augmentedState = [zeros(3,1); avgK; zeros(4,1)];
    end
    nextState = processFunction(augmentedState, U1(iStep));
    
    posXEstimate(iStep) = nextState(1);
    posYEstimate(iStep) = nextState(2);
    thetaEstimate(iStep) = nextState(3);
end
estimationError = ((posXEstimate - pX).^2 + (posYEstimate - pY).^2).^(0.5);

%% Initialize variables for storing the measurements

posXMeasure = mX;
posYMeasure = mY;
measurementError = ((posXMeasure - pX).^2 + (posYMeasure - pY).^2).^(0.5);

%% Initialize variables for storing the filtered values

posXFiltered = zeros(1,nStep);
posYFiltered = zeros(1,nStep);
thetaFiltered = zeros(1,nStep);
kFiltered = zeros(1,nStep);

posXCovariance = zeros(1,nStep);
posYCovariance = zeros(1,nStep);
thetaCovariance = zeros(1,nStep);
kCovariance = zeros(1,nStep);

% Fill the initial values of all variables
posXFiltered(startStep) = posXInitial;
posYFiltered(startStep) = posYInitial;
thetaFiltered(startStep) = thetaInitial;
kFiltered(startStep) = kInitial;

posXCovariance(startStep) = posXUncertainty;
posYCovariance(startStep) = posYUncertainty;
thetaCovariance(startStep) = thetaUncertainty;
kCovariance(startStep) = kUncertainty;


%% Initialize UKF

Q = [kNoise 0; 0 uNoise];
R = [pXNoise 0; 0 pYNoise];
dimX = 4;
dimZ = 2;
ukf = HomMinSymAUKF(@processFunction, [], @measurementFunction, [], Q, R, dimX, dimZ);
ukf.x = [posXFiltered(startStep) ; posYFiltered(startStep) ; thetaFiltered(startStep); kFiltered(startStep)];
ukf.P = diag([posXCovariance(startStep) posYCovariance(startStep) thetaCovariance(startStep) kCovariance(startStep)]);       

%% Initialize all windows

pathFigure = figure;
set(pathFigure, 'Position', [-1590 -60 898 658]);
hold on;

debugFigure = figure;
set(debugFigure, 'Position', [-560  45 550 350]);
hold on;

kFigure = figure;
set(kFigure, 'Position', [-560  520 550 350]);
hold on;

%% Main Loop

for iStep = 1:nStep
    
    % Apply one control input
    u = U1(iStep);
    
    % Perform one measurement
    z = [posXMeasure(iStep) ; posYMeasure(iStep)];
    
    % Update the filter feeding it with one control input and one
    % measurement
    ukf = ukf.update(u, z);
    
    % Store the current state for plotting
    posXFiltered(iStep) = ukf.x(1);
    posYFiltered(iStep) = ukf.x(2);
    thetaFiltered(iStep) = ukf.x(3);
    kFiltered(iStep) = ukf.x(4);
    
    posXCovariance(iStep) = ukf.P(1,1);
    posYCovariance(iStep) = ukf.P(2,2);
    thetaCovariance(iStep) = ukf.P(3,3);    
    kCovariance(iStep) = ukf.P(4,4);    
end
filterError = ((posXFiltered - pX).^2 + (posYFiltered - pY).^2).^(0.5);

%% Display debug information

figure(pathFigure);
plot(pX(startStep:iStep), pY(startStep:iStep), 'kd');
plot(posXEstimate(startStep:iStep), posYEstimate(startStep:iStep), 'g-');
plot(posXMeasure(startStep:iStep), posYMeasure(startStep:iStep), 'bo');
plot(posXFiltered(startStep:iStep), posYFiltered(startStep:iStep), 'r*-');
legend('Ground truth', 'Estimation', 'Measurements', 'Filtered');

figure(debugFigure);
plot(estimationError(startStep:iStep), 'g-');
plot(measurementError(startStep:iStep), 'b-');
plot(filterError(startStep:iStep), 'r-');
legend('Estimation', 'Measurements', 'Filtered');

figure(kFigure);
plot(k, 'r');
plot(kFiltered, 'b');

error1 = round(1000 * estimationError(nStep));
error2 = round(1000 * mean(measurementError(nStep-20:nStep)));
error3 = round(1000 * filterError(nStep));
error4 = round(1000 * max(filterError));
error5 = round(1000 * mean(filterError));
error6 = round(1000 * mean(filterError(nStep-199:nStep)));
fprintf('Final Errors (mm): \tEst = %d, \tMes = %d, \tFil = %d\n', error1, error2, error3);
fprintf('Estimation Error (mm): \tEnd = %d, \tMax = %d, \tAvg = %d, \tAvg200 = %d\n', error3, error4, error5, error6);

function processSigmaPoint = processFunction(sigmaPoint, parameter)

px    = sigmaPoint(1,:);
py    = sigmaPoint(2,:);
theta = sigmaPoint(3,:);
kState = sigmaPoint(4,:);

k     = kState + sigmaPoint(5,:);
u     = parameter(1) + sigmaPoint(6,:);

processSigmaPoint(1,:) = px + (2 * (1 - cos(k .* u)) ./ (k.^2)).^(0.5) .* cos(theta + 0.5 .* u .* k);
processSigmaPoint(2,:) = py + (2 * (1 - cos(k .* u)) ./ (k.^2)).^(0.5) .* sin(theta + 0.5 .* u .* k);
processSigmaPoint(3,:) = theta + k .* u;
processSigmaPoint(4,:) = k;
processSigmaPoint(5:6,:) = sigmaPoint(7:8,:);

function measurementSigmaPoint = measurementFunction(sigmaPoint, ~)

px    = sigmaPoint(1,:);
py    = sigmaPoint(2,:);
theta = sigmaPoint(3,:);
kState = sigmaPoint(4,:);

measurementSigmaPoint(1,:) = px + sigmaPoint(5,:);
measurementSigmaPoint(2,:) = py + sigmaPoint(6,:);