require 'rubyserial'
require 'rpi_gpio'

# global variables
TIMEOUT = 3 # seconds

# Print debug message
def debug_print(message)
  puts(message)
end

# Getting time as miliseconds
def now_in_ms
  Time.now.to_i
end

class Modem
  response = '' # variable for modem responses
  compose = '' # variable for command composes

  USER_BUTTON = 22
  USER_LED = 27
  BG96_ENABLE = 17
  BG96_POWERKEY = 24 
  STATUS = 23

  SCRAMBLE_ON = '0'
  SCRAMBLE_OFF = '1'

  # Special Characters
  CTRL_Z = '\x1A'

  MODE = [
    'AUTO', 'GSM', 'CATM1', 'NB'
  ]

  LTE_BAND = {
    'B1' => '1',
    'B2' => '2',
    'B3' => '4',
    'B4' => '8',
    'B5' => '10',
    'B8' => '80',
    'B12' => '800',
    'B13' => '1000',
    'B18' => '20000',
    'B19' => '40000',
    'B20' => '80000',
    'B26' => '2000000',
    'B28' => '8000000',
    'B39' => '4000000000', # catm1 only
    'CATM1_ANY' => '400A0E189F',
    'NB_ANY' => 'A0E189F',
    'NO_CHANGE' => '0'
  }
  
  GSM_BAND = {
    'NO_CHANGE' => '0',
    'B900' => '1',
    'B1800' => '2',
    'B850' => '4',
    'B1900' => '8',
    'ANY' => 'F'
  }

  # Initializer function
  def initialize
    @modem = Serial.new '/dev/ttyS0', 115200
    @timeout = TIMEOUT # default timeout for function and methods on this library.
    debug_print('Initialized')
  end

  def setupGPIO
    RPi::GPIO.set_numbering :bcm
    RPi::GPIO.setup BG96_ENABLE, as: :output
    RPi::GPIO.setup BG96_POWERKEY, as: :output
    RPi::GPIO.setup STATUS, as: :input
    RPi::GPIO.setup USER_BUTTON, as: :input
    RPi::GPIO.setup USER_LED, as: :output
  end

  # Function for clearing global compose variable
  def clear_compose
    compose = ''
  end

  # Function for clearing GPIO's setup
  def clearGPIOs
    RPi::GPIO.clean_up
  end

  # Function for enable BG96 module
  def enable
    RPi::GPIO.set_high BG96_ENABLE
    debug_print('BG96 module enabled!')
  end

  # Function for powering down BG96 module and all peripherals from voltage regulator
  def disable
    RPi::GPIO.set_low BG96_ENABLE
    debug_print('BG96 module disabled!')
  end

  # Function for powering up BG96 module
  def powerUp
    RPi::GPIO.set_low BG96_POWERKEY
    sleep(0.1)
    debug_print('BG96 module powered up!')
    RPi::GPIO.set_high BG96_POWERKEY
    sleep(0.1)
  end

  # Function for powering down BG96 module
  def powerOff
    RPi::GPIO.set_low BG96_POWERKEY
    debug_print('BG96 module powered up!')
  end

  # Function for getting modem power status
  def getModemStatus
    puts "Powered up" if (RPi::GPIO.high? BG96_POWERKEY)
    puts "Modem Active" if (RPi::GPIO.high? STATUS)
  end

  # Function for getting modem response
  def getResponse(desired_response)
    @modem.open if @modem.closed? == true
    response = ''
    loop do
      response += @modem.read(120)
      if response.end_with?(desired_response)
        response = response.chomp(desired_response).delete_prefix(command).strip
        return response
      end
    end
  end

  # Function for sending data to module
  def sendDataCommOnce(command)
    @modem.write(command)
    debug_print(command)
  end

  # Function for sending at comamand to module
  def sendATCommOnce(command)
    compose = ''
    compose = command + "\r"
    @modem.write(compose)
    debug_print(compose)
  end

  # Function for sending data to BG96_AT.
  def sendDataComm(command:, desired_response: "OK\r\n", timeout: nil)
    timeout = @timeout if timeout.nil?
    response = ''
    sendDataCommOnce(command)


    timer = now_in_ms
    loop do
      if now_in_ms - timer > timeout
        sendDataCommOnce(command)
        timer = now_in_ms
      end

      
      if response.end_with?(desired_response, "OK\r\n")
        response = response.chomp(desired_response).delete_prefix(command).strip
        return response
      end
    end
  end

  # Function for sending at command to BG96_AT.
  def sendATComm(command:, desired_response: "\r\nOK", timeout: nil)
    timeout = @timeout if timeout.nil?

    sendATCommOnce(command)
    sleep(0.1)
    timer = now_in_ms
    response = ''
    loop do
      
      # puts "checking if \n#{response}\n==\n#{desired_response}"

      if now_in_ms - timer > timeout
        sendDataCommOnce(command)
        timer = now_in_ms
      end
      begin
        response += @modem.read(240).rstrip
        # puts "raw read ='#{response}'"
        sleep(0.2)
      rescue StandardError => e
        debug_print(e.message)
        break
      end
      if response.end_with?(desired_response)
        response = response.chomp(desired_response).delete_prefix(command).strip
        puts response
        return response
      elsif response.end_with?("POWERED DOWN", "ERROR")
        repower
        break
      elsif response.end_with?("NO CARRIER")
        puts response
        break
      elsif response.end_with?("\r\nOK")
        response = response.chomp(desired_response).delete_prefix(command).strip
        puts response
      end   
    end
  end

  def repower
    sleep(1)
    resetModule
    sleep(1)
  end


  # Function for saving conf. and reset BG96_AT module
  def resetModule
    disable
    sleep(0.2)
    enable
    powerUp
  end

  # Function for save configurations that be done in current session.
  def saveConfigurations
    sendATComm(command: 'AT&W')
  end

  # Function for getting IMEI number
  def getIMEI
    sendATComm(command: 'AT+CGSN')
  end

  # Function for getting firmware info
  def getFirmwareInfo
    sendATComm(command: 'AT+CGMR')
  end

  # Function for getting hardware info
  def getHardwareInfo
    sendATComm(command: 'AT+CGMM')
  end

  # Function for setting GSM Band
  def setGSMBand(gsm_band)
    compose = 'AT+QCFG="band",'
    compose += GSM_BAND[gsm_band]
    compose += ',0,0'

    sendATComm(command: compose)
    clear_compose
  end

  # Function for setting Cat.M1 Band
  def setCATM1Band(catm1_band)
    compose = 'AT+QCFG="band",0,'
    compose += LTE_BAND[catm1_band]
    compose += ',0'

    sendATComm(compose)
    clear_compose
  end

  # Function for setting NB-IoT Band
  def setNBIoTBand(nbiot_band)
    compose = 'AT+QCFG="band",0,0,'
    compose += LTE_BAND[nbiot_band]

    sendATComm(command: compose)
    clear_compose
  end

  # Function for getting current band settings
  def getBandConfiguration
    sendATComm(command: 'AT+QCFG="band"')
  end

  # Function for setting scramble feature configuration
  def setScrambleConf(scramble)
    compose = 'AT+QCFG="nbsibscramble",'
    compose += scramble

    sendATComm(compose)
    clear_compose
  end

  # Function for setting running mode.
  def setMode(mode)
    if mode == 'AUTO'
      sendATComm(command: 'AT+QCFG="nwscanseq",00,1')
      sendATComm(command: 'AT+QCFG="nwscanmode",0,1')
      sendATComm(command: 'AT+QCFG="iotopmode",2,1')
      debug_print('Modem configuration: AUTO')
      debug_print('*Priority Table (Cat.M1 -> Cat.NB1 -> GSM)')
    elsif mode == 'GSM'
      sendATComm(command: 'AT+QCFG="nwscanseq",01,1')
      sendATComm(command: 'AT+QCFG="nwscanmode",1,1')
      sendATComm(command: 'AT+QCFG="iotopmode",2,1')
      debug_print('Modem configuration : GSM')
    elsif mode == 'CATM1'
      sendATComm(command: 'AT+QCFG="nwscanseq",02,1')
      sendATComm(command: 'AT+QCFG="nwscanmode",3,1')
      sendATComm(command: 'AT+QCFG="iotopmode",0,1')
      debug_print('Modem configuration : CATM1')
    elsif mode == 'NB'
      sendATComm(command: 'AT+QCFG="nwscanseq",03,1')
      sendATComm(command: 'AT+QCFG="nwscanmode",3,1')
      sendATComm(command: 'AT+QCFG="iotopmode",1,1')
      debug_print('Modem configuration : NB ( NB-IoT )')
    end
  end

  # Function for getting timout in ms
  def getTimeout
    timeout
  end

  # Function for setting timeout in ms
  def setTimeout(new_timeout)
    timeout = new_timeout
  end

  # *** Network Service Functions ***

  # Fuction for getting signal quality
  def getSignalQuality
    sendATComm(command: 'AT+CSQ')
  end

  # Function for getting network information
  def getQueryNetworkInfo
    sendATComm(command: 'AT+QNWINFO')
  end

  # Function for connecting to base station of operator
  def connectToOperator
    debug_print('Trying to connect base station of operator...')
    sendATComm(command: 'AT+CGATT?', desired_response: "+CGATT: 1\r\n")
    getSignalQuality
  end

  # *** SMS Functions ****

  # Function for sending SMS
  def sendSMS(number, text)
    sendATComm(command: 'AT+CMGF=1') # text mode
    sleep(0.5)

    compose = 'AT+CMGS="'
    compose += number
    compose += '"'

    sendATComm(compose, desired_response: '>')
    sleep(1)
    clear_compose
    sleep(1)
    sendATCommOnce(text)
    sendATComm(command: CTRL_Z, desired_response: 'OK', timeout: 8)
  end

  # *** GNSS Functions ***

  # Function for turning on GNSS
  def turnOnGNSS
    sendATComm(command: 'AT+QGPS=1')
  end

  # Function for turning of GNSS
  def turnOffGNSS
    sendATComm(command: 'AT+QGPSEND')
  end

  # Function for getting fixed location
  def getFixedLocation
    sendATComm(command: 'AT+QGPSLOC?', desired_response: '+QGPSLOC:')
  end

  # *** TCP & UDP Protocols Functions ***

  # Function for configurating and activating TCP context
  def activateContext
    sendATComm(command: 'AT+QICSGP=1')
    sleep(1)
    sendATComm(command: 'AT+QIACT=1', desired_response: "\r\n")
  end

  # Function for deactivating TCP context
  def deactivateContext
    sendATComm(command: 'AT+QIDEACT=1', desired_response: "\r\n")
  end

  # Function for closing server connection
  def closeConnection
    sendATComm(command: 'AT+QICLOSE=1', desired_response: "\r\n")
  end

  # *** Shield Peripheral Functions ***

  # Function for reading user button
  def readUserButton
    RPi::GPIO.input(USER_BUTTON)
  end
  # Function for turning on user LED

  def turnOnUserLED
    RPi::GPIO.set_high USER_LED
  end

  # Function for turning off user LED
  def turnOffUserLED
    RPi::GPIO.set_low USER_LED
  end
end

