// MIT License
// Copyright (c) 2021 IAMLIUBO
// https://github.com/imliubo

import gpio
import i2c
import mpu6886
import fixed_point show FixedPoint

main:
  // I2C init
  bus := i2c.Bus
    --sda=gpio.Pin 21
    --scl=gpio.Pin 22

  // MPU6886 init.
  device := bus.device mpu6886.I2C_ADDRESS
  driver := mpu6886.Driver device

  while true:
    // Read MPU6886.
    temp := driver.temperature
    acceleration := driver.acceleration
    gyro := driver.gyro
    // Print the read data.
    print "aX: $acceleration.x aY: $acceleration.y aZ: $acceleration.z gX: $gyro.x gY: $gyro.y gZ: $gyro.z T: $temp"
    sleep --ms=10
