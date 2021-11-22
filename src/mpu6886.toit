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

I2C_ADDRESS     ::= 0x68

/**
Driver for the InvenSense MPU-6886 High-Performance 6-Axis MEMS MotionTracking™ sensor, using either I2C.
*/
class Driver:
  // Registers
  static _SMPLRT_DIV      ::= (0x19)
  static _CONFIG          ::= (0x1a)
  static _GYRO_CONFIG     ::= (0x1b)
  static _ACCEL_CONFIG_1  ::= (0x1c)
  static _ACCEL_CONFIG_2  ::= (0x1d)

  static _FIFO_EN         ::= (0x23)

  static _INT_PIN_CFG     ::= (0x37)
  static _INT_ENABLE      ::= (0x38)

  static _ACCEL_XOUT_H    ::= (0x3b)
  static _ACCEL_XOUT_L    ::= (0x3c)
  static _ACCEL_YOUT_H    ::= (0x3d)
  static _ACCEL_YOUT_L    ::= (0x3e)
  static _ACCEL_ZOUT_H    ::= (0x3f)
  static _ACCEL_ZOUT_L    ::= (0x40)

  static _TEMP_OUT_H      ::= (0x41)
  static _TEMP_OUT_L      ::= (0x42)

  static _GYRO_XOUT_H     ::= (0x43)
  static _GYRO_XOUT_L     ::= (0x44)
  static _GYRO_YOUT_H     ::= (0x45)
  static _GYRO_YOUT_L     ::= (0x46)
  static _GYRO_ZOUT_H     ::= (0x47)
  static _GYRO_ZOUT_L     ::= (0x48)
 
  static _USER_CTRL       ::= (0x6A)
  static _PWR_MGMT_1      ::= (0x6b)
  static _PWR_MGMT_2      ::= (0x6c)
  static _WHO_AM_I        ::= (0x75)

  // Temperature
  static _TEMP_SO     ::= 326.8
  static _TEMP_OFFSET ::= 25.0

  reg_/serial.Registers ::= ?

  constructor dev/serial.Device:

    reg_ = dev.registers

    tries := 5
    while whoami != 0x19:
      tries--
      if tries == 0: throw "INVALID_CHIP"
      sleep --ms=1

    reset  // reset
    sleep --ms=100  // sleep 100ms for stable
    init   // init sequence

  /*
   Reset
  */
  reset:
    reg_.write_u8 _PWR_MGMT_1 0b10000000  // software reset

  /*
    WHO AM I
  */
  whoami -> int:
    """ Value of the whoami register. """
    return (reg_.read_u8 _WHO_AM_I)

  /*
   Init sequence.
  */
  init:
    reg_.write_u8 _PWR_MGMT_1     0x00
    sleep --ms=10
    reg_.write_u8 _PWR_MGMT_1     0x01 << 7
    sleep --ms=10
    reg_.write_u8 _PWR_MGMT_1     0x01
    sleep --ms=10
    reg_.write_u8 _ACCEL_CONFIG_1 0x10  // +- 8G
    sleep --ms=10
    reg_.write_u8 _GYRO_CONFIG    0x18  // +- 2000dps
    sleep --ms=10
    reg_.write_u8 _CONFIG         0x01
    sleep --ms=10
    reg_.write_u8 _SMPLRT_DIV     0x05
    sleep --ms=10
    reg_.write_u8 _INT_ENABLE     0x00
    sleep --ms=10
    reg_.write_u8 _ACCEL_CONFIG_2  0X00
    sleep --ms=10
    reg_.write_u8 _USER_CTRL      0x00
    sleep --ms=10
    reg_.write_u8 _FIFO_EN        0x00
    sleep --ms=10
    reg_.write_u8 _INT_PIN_CFG    0x22
    sleep --ms=10
    reg_.write_u8 _INT_ENABLE     0x01
    sleep --ms=100
  
  /*
    Acceleration
  */
  acceleration -> List:
    aRes/float := (8.0 / 32768.0)
    ax := (reg_.read_i16_be _ACCEL_XOUT_H) * aRes
    ay := (reg_.read_i16_be _ACCEL_YOUT_H) * aRes
    az := (reg_.read_i16_be _ACCEL_ZOUT_H) * aRes

    return [ax, ay, az]

  /*
    Gyro
  */
  gyro -> List:
    gRes/float := (2000.0 / 32768.0)
    gx := (reg_.read_i16_be _GYRO_XOUT_H) * gRes
    gy := (reg_.read_i16_be _GYRO_YOUT_H) * gRes
    gz := (reg_.read_i16_be _GYRO_ZOUT_H) * gRes

    return [gx, gy, gz]

  /*
   Temperature
  */
  temperature -> float:
    return (((reg_.read_u16_be _TEMP_OUT_H) / _TEMP_SO) + _TEMP_OFFSET)
