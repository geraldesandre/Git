/*
 * UStepDevice.h
 *
 *  Created on: May 18, 2015
 *      Author: andre
 */

#ifndef USTEPDEVICE_H_
#define USTEPDEVICE_H_

#include "StepperMotor.h"
#include <pigpio.h>

class UStepDevice
{
 private:

  // Sensors
  unsigned emergency_button_;
  unsigned front_switch_;
  unsigned back_switch_;

  // Actuators
  StepperMotor insertion_;
  StepperMotor rotation_;
  StepperMotor front_gripper_;
  StepperMotor back_gripper_;

  // State variables
  bool configured_;
  bool initialized_;

  // Waves
  int wave_insertion_with_rotation_;
  int wave_pure_insertion_;

  // Wave flags
  bool has_wave_pure_insertion_;
  bool has_wave_insertion_with_rotation_;
  bool has_wave_remaining_;


  // Duty cycle wave parameters
  unsigned num_dc_periods_;
  unsigned insertion_step_half_period_;
  unsigned rotation_step_half_period_;
  unsigned micros_rotation_;
  unsigned micros_pure_insertion_;
  unsigned micros_remaining_;
  unsigned seconds_rotation_;
  unsigned seconds_pure_insertion_;




  // Duty cycle thresholds
  double dc_max_threshold_;
  double dc_min_threshold_;





  // Auxiliary functions
  void clearWaves();
  int checkExistingWaves();
  int calculateDutyCycleMotionParameters(double insert_depth,  double insert_speed, double rot_speed, double duty_cycle);
  int calculateRotationSpeed(unsigned rot_insert_time_us);
  int generateWaveInsertionWithRotation();
  int generateWavePureInsertion();
  gpioPulse_t* generatePulsesConstantSpeed(unsigned port_number, unsigned half_period, unsigned num_steps);
  gpioPulse_t* generatePulsesRampUpDown(unsigned port_number, double frequency_initial, double frequency_final, double step_acceleration, unsigned num_steps, unsigned total_time);
  unsigned generatePulsesRampUp(unsigned port_number, double frequency_initial, double frequency_final, double step_acceleration, gpioPulse_t* pulses, unsigned max_steps);

 public:

  // Empty constructor
  UStepDevice();

  // Configuration functions
  void configureMotorParameters();
  int initGPIO();
  void terminateGPIO();

  // Motion functions
  int setInsertionWithDutyCycle(double insertion_depth_rev,  double insertion_speed, double rotation_speed, double duty_cycle);
  int startInsertion();

  /*void openFrontGripper();
  void closeFrontGripper();
  void openBackGripper();
  void closeBackGripper();
  void insert();
  void retreat();
  void spin();*/

};

#endif /* USTEPDEVICE_H_ */