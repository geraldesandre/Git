close all;
clear all;
clc;

%% Global parameters


% sensor_angle_inside_needle = 49.0;
sensor_angle_inside_needle = 29.0;


% Needle initial orientation
needle_V0 = [0 0 1];
needle_N0 = [-sind(sensor_angle_inside_needle) cosd(sensor_angle_inside_needle) 0];

preparation_step_size = 20;
preparation_insertion_speed = 3.0;
preparation_rotation_speed = 0.1;

% Insertion trajectory
n_step = 25;
step_size = 6;
insertion_speed = 1.0;
rotation_speed = 2.0;

duty_cycle = 0.5;

%% Configure the TCP/IP client for communicating with the Raspberry Pi

ustep_device = UStepDeviceHandler(n_step);

%% Configure the Aurora sensor object

aurora_device = AuroraDriver('/dev/ttyUSB0');
aurora_device.openSerialPort();
aurora_device.init();
aurora_device.detectAndAssignPortHandles();
aurora_device.initPortHandleAll();
aurora_device.enablePortHandleDynamicAll();
aurora_device.startTracking();

%% Set file name for storing the results

fprintf('Duty Cycle Experiment - DC = %.2f\n', duty_cycle);
output_file_name = input('Type the name of the file for saving the results\n','s');

%% Adjust the needle starting position

fprintf('Place the needle inside the device \nMake sure to align the needle tip to the end of the device\n');
input('When you are done, hit ENTER to close the front gripper\n\n');

% Moving the needle forward until it gets detected by the Aurora system
fprintf('Adjusting the needle initial orientation\n');
n_preparation_step = 0;
while(aurora_error.isSensorAvailable() == 0)
    
    fprintf('Cant read the needle EM sensor. Moving the needle %.2f mm forward \n', preparation_step_size);
    ustep_device.moveForward(preparation_step_size, preparation_insertion_speed);
    n_preparation_step = n_preparation_step + 1;
end

% Adjusting the needle orientation
aurora_device.updateSensorDataAll();
needle_quaternion = quatinv(aurora_device.port_handles(1,1).rot);
correction_angle = measureNeedleCorrectionAngle(needle_quaternion, needle_N0);

fprintf('Needle found! Correction angle = %.2f degrees \n', correction_angle);
ustep_device.rotateNeedleDegrees(correction_angle, preparation_rotation_speed);

% Moving the needle backward
for i_preparation_step = 1:n_preparation_step
    ustep_device.moveBackward(preparation_step_size, preparation_insertion_speed);
end

%% Perform forward steps

fprintf('\nPreparing to start the experiment. Place the gelatin\n');
input('Hit ENTER when you are ready\n');

for i_step = 1:n_step
    fprintf('\nPerforming step %d/%d: S = %.2f, V = %.2f, W = %.2f, DC = %.2f\n', i_step, n_step, step_size, insertion_speed, rotation_speed, duty_cycle);
    
    % Measure needle pose before moving
    ustep_device.savePoseForward(aurora_device, i_step);
    
    % Move needle
    ustep_device.moveDC(step_size, insertion_speed, rotation_speed, duty_cycle);
    ustep_device.saveCommandsDC(i_step, step_size, insertion_speed, rotation_speed, duty_cycle);
end

% Measure the final needle pose
ustep_device.savePoseForward(aurora_device, n_step+1);

%% Perform backward steps

fprintf('\nNeedle insertion complete!\n');
input('Hit ENTER to start retreating the needle\n');

% Measure the final needle pose
ustep_device.savePoseBackward(aurora_device, n_step+1);

for i_step = n_step:-1:1
    fprintf('\nPerforming backward step %d/%d\n', i_step, n_step);
    
    % Move needle
    ustep_device.moveBackward(step_size, insertion_speed);
    
    % Measure needle pose before retreating
    ustep_device.savePoseBackward(aurora_device, i_step);

end

%% Save the results and close the program

% Close the aurora system
aurora_device.stopTracking();
delete(aurora_device);

% Save experiment results
save(sprintf('%s.mat',output_file_name));