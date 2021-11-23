// MIT License

// Copyright (c) 2021 IAMLIUBO https://github.com/imliubo

// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import binary
import serial.device as serial
import serial.registers as serial
import math

I2C_ADDRESS ::= 0x68

/**
Driver for the InvenSense MPU-6886 High-Performance 6-Axis MEMS MotionTracking™ sensor.
*/
class Driver:
  // Registers.
  static SMPLRT_DIV_      ::= 0x19
  static CONFIG_          ::= 0x1a
  static GYRO_CONFIG_     ::= 0x1b
  static ACCEL_CONFIG_1_  ::= 0x1c
  static ACCEL_CONFIG_2_  ::= 0x1d

  static FIFO_EN_         ::= 0x23

  static INT_PIN_CFG_     ::= 0x37
  static INT_ENABLE_      ::= 0x38

  static ACCEL_XOUT_H_    ::= 0x3b
  static ACCEL_XOUT_L_    ::= 0x3c
  static ACCEL_YOUT_H_    ::= 0x3d
  static ACCEL_YOUT_L_    ::= 0x3e
  static ACCEL_ZOUT_H_    ::= 0x3f
  static ACCEL_ZOUT_L_    ::= 0x40

  static TEMP_OUT_H_      ::= 0x41
  static TEMP_OUT_L_      ::= 0x42

  static GYRO_XOUT_H_     ::= 0x43
  static GYRO_XOUT_L_     ::= 0x44
  static GYRO_YOUT_H_     ::= 0x45
  static GYRO_YOUT_L_     ::= 0x46
  static GYRO_ZOUT_H_     ::= 0x47
  static GYRO_ZOUT_L_     ::= 0x48

  static USER_CTRL_       ::= 0x6A
  static PWR_MGMT_1_      ::= 0x6b
  static PWR_MGMT_2_      ::= 0x6c
  static WHO_AM_I_        ::= 0x75

  // Temperature.
  static TEMP_SO_     ::= 326.8
  static TEMP_OFFSET_ ::= 25.0

  reg_/serial.Registers ::= ?

  constructor dev/serial.Device:

    reg_ = dev.registers

    tries := 5
    while whoami != 0x19:
      tries--
      if tries == 0: throw "INVALID_CHIP"
      sleep --ms=1

    reset
    sleep --ms=100  // Sleep 100ms to stabilize.
    init

  /**
  Resets the chip.
  */
  reset:
    reg_.write_u8 PWR_MGMT_1_ 0b10000000  // Software reset.

  /**
  Returns the value of the WHO_AM_I register.
  The MPU-6886 should return 0x19.
  */
  whoami -> int:
    return reg_.read_u8 WHO_AM_I_

  /**
  Initializes the chip.
  */
  init:
    reg_.write_u8 PWR_MGMT_1_     0x00
    sleep --ms=10
    reg_.write_u8 PWR_MGMT_1_     0x01 << 7
    sleep --ms=10
    reg_.write_u8 PWR_MGMT_1_     0x01
    sleep --ms=10
    reg_.write_u8 ACCEL_CONFIG_1_ 0x10  // +- 8G
    sleep --ms=10
    reg_.write_u8 GYRO_CONFIG_    0x18  // +- 2000dps
    sleep --ms=10
    reg_.write_u8 CONFIG_         0x01
    sleep --ms=10
    reg_.write_u8 SMPLRT_DIV_     0x05
    sleep --ms=10
    reg_.write_u8 INT_ENABLE_     0x00
    sleep --ms=10
    reg_.write_u8 ACCEL_CONFIG_2_  0X00
    sleep --ms=10
    reg_.write_u8 USER_CTRL_      0x00
    sleep --ms=10
    reg_.write_u8 FIFO_EN_        0x00
    sleep --ms=10
    reg_.write_u8 INT_PIN_CFG_    0x22
    sleep --ms=10
    reg_.write_u8 INT_ENABLE_     0x01
    sleep --ms=100

  /**
  Reads the acceleration.
  */
  acceleration -> math.Point3f:
    aRes/float := (8.0 / 32768.0)
    ax := (reg_.read_i16_be ACCEL_XOUT_H_) * aRes
    ay := (reg_.read_i16_be ACCEL_YOUT_H_) * aRes
    az := (reg_.read_i16_be ACCEL_ZOUT_H_) * aRes

    return math.Point3f ax ay az

  /**
  Reads the gyro values.
  */
  gyro -> math.Point3f:
    gRes/float := (2000.0 / 32768.0)
    gx := (reg_.read_i16_be GYRO_XOUT_H_) * gRes
    gy := (reg_.read_i16_be GYRO_YOUT_H_) * gRes
    gz := (reg_.read_i16_be GYRO_ZOUT_H_) * gRes

    return math.Point3f gx gy gz

  /**
  Reads the temperature.
  */
  temperature -> float:
    return (((reg_.read_u16_be TEMP_OUT_H_) / TEMP_SO_) + TEMP_OFFSET_)
