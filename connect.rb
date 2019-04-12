require 'rubyserial'
require 'rpi_gpio'


class Modem
  # some constants
  USER_BUTTON = 24
  USER_LED = 27
  BG96_ENABLE = 26
  RELAY = 17
  BG96_POWERKEY = 11 
  STATUS = 20
  AP_READY = 6
  RING_INDICATOR = 13
  OPTO1 = 10
  OPTO2 = 18
  LUX_CHANNEL = 3

  # LTE Bands
  LTE_B1 = "1"
  LTE_B2 = "2"
  LTE_B3 = "4"
  LTE_B4 = "8"
  LTE_B5 = "10"
  LTE_B8 = "80"
  LTE_B12 = "800"
  LTE_B13 = "1000"
  LTE_B18 = "20000"
  LTE_B19 = "40000"
  LTE_B20 = "80000"
  LTE_B26 = "2000000"
  LTE_B28 = "8000000"
  LTE_B39 = "4000000000" # catm1 only
  LTE_CATM1_ANY = "400A0E189F"
  LTE_CATNB1_ANY = "A0E189F"
  LTE_NO_CHANGE = "0"
  
  def initialize
    @modem = Serial.new '/dev/ttyS0', 115200
  end

  def setupGPIO
    RPi::GPIO.set_numbering :bcm
    RPi::GPIO.setup BG96_ENABLE, :as => :output
    RPi::GPIO.setup BG96_POWERKEY, :as => :output
    RPi::GPIO.setup STATUS, :as => :input
    RPi::GPIO.setup USER_BUTTON, :as => :input
    RPi::GPIO.setup USER_LED, :as => :output
  end

  # Function for printing debug message 
  def debug_print(message)
    print(message)
  end

  # Function for delay as miliseconds
  def delay(ms)
    sleep(ms/1000.0)
  end

  # Function for enable BG96 module
  def enable(self)
    GPIO.output(self.BG96_ENABLE,0)
    debug_print("BG96 module enabled!")
  end

  # Function for powering down BG96 module and all peripherals from voltage regulator 
  def disable(self)
    GPIO.output(self.BG96_ENABLE,1)
    debug_print("BG96 module disabled!")
  end

  # Function for powering up or down BG96 module
  def powerUp(self)
    GPIO.output(self.BG96_POWERKEY,1)
    while self.getModemStatus()
      pass
    debug_print("BG96 module powered up!")
    GPIO.output(self.BG96_POWERKEY,0)
  end

  # Function for getting modem power status
  def getModemStatus(self)
    return GPIO.input(self.STATUS)
  end

end

setupGPIO()

modem.write('AT\r\n')
puts modem.read(1000)