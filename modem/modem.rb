require 'rubyserial'
require 'rpi_gpio'

# global variables
TIMEOUT = 3 # seconds

### Private Methods ###

# Function for printing debug message
def debug_print(message)
  puts(message)
end

# Function for getting time as miliseconds
def now_in_ms
  Time.now.to_i
end

### Cellular IoT App Shield Class ###

class Modem
  board = '' # shield name (Cellular IoT or Cellular IoT App.)
  ip_address = '' # ip address
  domain_name = '' # domain name
  port_number = '' # port number

  response = '' # variable for modem responses
  compose = '' # variable for command composes

  USER_BUTTON = 22
  USER_LED = 27
  BG96_ENABLE = 17
  BG96_POWERKEY = 24
  STATUS = 23

  # Cellular Modes
  AUTO_MODE = 0
  GSM_MODE = 1
  CATM1_MODE = 2
  CATNB1_MODE = 3

  # LTE Bands
  LTE_B1 = '1'.freeze
  LTE_B2 = '2'.freeze
  LTE_B3 = '4'.freeze
  LTE_B4 = '8'.freeze
  LTE_B5 = '10'.freeze
  LTE_B8 = '80'.freeze
  LTE_B12 = '800'.freeze
  LTE_B13 = '1000'.freeze
  LTE_B18 = '20000'.freeze
  LTE_B19 = '40000'.freeze
  LTE_B20 = '80000'.freeze
  LTE_B26 = '2000000'.freeze
  LTE_B28 = '8000000'.freeze
  LTE_B39 = '4000000000'.freeze # catm1 only
  LTE_CATM1_ANY = '400A0E189F'.freeze
  LTE_CATNB1_ANY = 'A0E189F'.freeze
  LTE_NO_CHANGE = '0'.freeze

  # GSM Bands
  GSM_NO_CHANGE = '0'.freeze
  GSM_900 = '1'.freeze
  GSM_1800 = '2'.freeze
  GSM_850 = '4'.freeze
  GSM_1900 = '8'.freeze
  GSM_ANY = 'F'.freeze

  SCRAMBLE_ON = '0'.freeze
  SCRAMBLE_OFF = '1'.freeze

  # Special Characters
  CTRL_Z = '\x1A'.freeze

  # Initializer function
  def initialize
    @modem = Serial.new '/dev/ttyS0', 115_200
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
    RPi::GPIO.cleanup
  end

  # Function for enable BG96 module
  def enable
    RPi::GPIO.set_low BG96_ENABLE
    debug_print('BG96 module enabled!')
  end

  # Function for powering down BG96 module and all peripherals from voltage regulator
  def disable
    RPi::GPIO.set_high BG96_ENABLE
    debug_print('BG96 module disabled!')
  end

  # Function for powering up or down BG96 module
  def powerUp
    RPi::GPIO.set_high BG96_POWERKEY

    debug_print('BG96 module powered up!')
    RPi::GPIO.set_low BG96_POWERKEY
  end

  # Function for getting modem power status
  def getModemStatus
    RPi::GPIO.input(self.STATUS)
  end

  # Function for getting modem response
  def getResponse(desired_response)
    @modem.open if @modem.closed? == true
    response = ''
    loop do
      response += @modem.read(120)
      if response == desired_response
        debug_print(response)
        break
      end
    end
  end

  # Function for sending data to module
  def sendDataCommOnce(command)
    # # @modem.open if (@modem.isOpen == false)
    # compose = ''
    # compose = command
    # @modem.reset_input_buffer
    @modem.write(compose)
    debug_print(compose)
  end

  # Function for sending at comamand to module
  def sendATCommOnce(command)
    # @modem.open if (@modem.isOpen == false)
    compose = ''
    compose = command + "\r"
    # @modem.reset_input_buffer
    @modem.write(compose)
    debug_print(compose)
  end

  # Function for sending data to BG96_AT.
  def sendDataComm(command, desired_response, timeout = nil)
    timeout = @timeout if timeout.nil?

    sendDataCommOnce(command)

    timer = now_in_ms
    loop do
      if now_in_ms - timer > timeout
        sendDataCommOnce(command)
        timer = now_in_ms
      end

      response = ''

      while @modem.inWaiting
        response += @modem.read(@modem.inWaiting).decode('utf-8', errors = 'ignore')
      end

      if response == desired_response
        debug_print(response)
        break
      end
    end
  end

  # Function for sending at command to BG96_AT.
  def sendATComm(command, desired_response, timeout = nil)
    timeout = @timeout if timeout.nil?

    sendATCommOnce(command)
    sleep(0.1)
    timer = now_in_ms
    response = ''

    loop do
      if response.end_with?(desired_response)
        response = response.chomp(desired_response).delete_prefix(command).strip
        debug_print(response)
        break
      end

      if now_in_ms - timer > timeout
        sendDataCommOnce(command)
        timer = now_in_ms
      end

      begin
        response += @modem.read(120)
        sleep(0.1)
        # Debug response
        # puts "'#{response}'"
      rescue StandardError => e
        debug_print(e.message)
        break
      end

      
    end
  end

  # Function for saving conf. and reset BG96_AT module
  def resetModule
    saveConfigurations
    sleep(0.2)
    disable
    sleep(0.2)
    enable
    powerUp
  end

  # Function for save configurations that be done in current session.
  def saveConfigurations
    sendATComm('AT&W', "OK\r\n")
  end

  # Function for getting IMEI number
  def getIMEI
    sendATComm('AT+CGSN', "OK\r\n")
  end

  # Function for getting firmware info
  def getFirmwareInfo
    sendATComm('AT+CGMR', "OK\r\n")
  end

  # Function for getting hardware info
  def getHardwareInfo
    sendATComm('AT+CGMM', "OK\r\n")
  end

  # Function for setting GSM Band
  def setGSMBand(gsm_band)
    compose = 'AT+QCFG="band",'
    compose += str(gsm_band)
    compose += ','
    compose += str(self.LTE_NO_CHANGE)
    compose += ','
    compose += str(self.LTE_NO_CHANGE)

    sendATComm(compose, "OK\r\n")
    clear_compose
  end

  # Function for setting Cat.M1 Band
  def setCATM1Band(catm1_band)
    compose = 'AT+QCFG="band",'
    compose += str(self.GSM_NO_CHANGE)
    compose += ','
    compose += str(catm1_band)
    compose += ','
    compose += str(self.LTE_NO_CHANGE)

    sendATComm(compose, "OK\r\n")
    clear_compose
  end

  # Function for setting NB-IoT Band
  def setNBIoTBand(nbiot_band)
    compose = 'AT+QCFG="band",'
    compose += str(self.GSM_NO_CHANGE)
    compose += ','
    compose += str(self.LTE_NO_CHANGE)
    compose += ','
    compose += str(nbiot_band)

    sendATComm(compose, "OK\r\n")
    clear_compose
  end

  # Function for getting current band settings
  def getBandConfiguration
    sendATComm('AT+QCFG="band"', "OK\r\n")
  end

  # Function for setting scramble feature configuration
  def setScrambleConf(scramble)
    compose = 'AT+QCFG="nbsibscramble",'
    compose += scramble

    sendATComm(compose, "OK\r\n")
    clear_compose
  end

  # Function for setting running mode.
  def setMode(mode)
    if mode == self.AUTO_MODE
      sendATComm('AT+QCFG="nwscanseq",00,1', "OK\r\n")
      sendATComm('AT+QCFG="nwscanmode",0,1', "OK\r\n")
      sendATComm('AT+QCFG="iotopmode",2,1', "OK\r\n")
      debug_print('Modem configuration : AUTO_MODE')
      debug_print('*Priority Table (Cat.M1 -> Cat.NB1 -> GSM)')
    elsif mode == self.GSM_MODE
      sendATComm('AT+QCFG="nwscanseq",01,1', "OK\r\n")
      sendATComm('AT+QCFG="nwscanmode",1,1', "OK\r\n")
      sendATComm('AT+QCFG="iotopmode",2,1', "OK\r\n")
      debug_print('Modem configuration : GSM_MODE')
    elsif mode == self.CATM1_MODE
      sendATComm('AT+QCFG="nwscanseq",02,1', "OK\r\n")
      sendATComm('AT+QCFG="nwscanmode",3,1', "OK\r\n")
      sendATComm('AT+QCFG="iotopmode",0,1', "OK\r\n")
      debug_print('Modem configuration : CATM1_MODE')
    elsif mode == self.CATNB1_MODE
      sendATComm('AT+QCFG="nwscanseq",03,1', "OK\r\n")
      sendATComm('AT+QCFG="nwscanmode",3,1', "OK\r\n")
      sendATComm('AT+QCFG="iotopmode",1,1', "OK\r\n")
      debug_print('Modem configuration : CATNB1_MODE ( NB-IoT )')
    end
  end

  # # Function for getting self.ip_address
  # def getIPAddress
  #   return self.ip_address
  # end
  # # Function for setting self.ip_address
  # def setIPAddress(ip)
  #   self.ip_address = ip
  # end
  # # Function for getting self.domain_name
  # def getDomainName
  #   return self.domain_name
  # end
  # # Function for setting domain name
  # def setDomainName(domain)
  #   self.domain_name = domain
  # end
  # # Function for getting port
  # def getPort
  #   return self.port_number
  # end
  # # Function for setting port
  # def setPort(port)
  #   self.port_number = port
  # end
  # Function for getting timout in ms
  def getTimeout
    timeout
  end

  # Function for setting timeout in ms
  def setTimeout(new_timeout)
    self.timeout = new_timeout
  end

  # *** Network Service Functions ***

  # Fuction for getting signal quality
  def getSignalQuality
    sendATComm('AT+CSQ', "OK\r\n")
  end

  # Function for getting network information
  def getQueryNetworkInfo
    sendATComm('AT+QNWINFO', "OK\r\n")
  end

  # Function for connecting to base station of operator
  def connectToOperator
    debug_print('Trying to connect base station of operator...')
    sendATComm('AT+CGATT?', "+CGATT: 1\r\n")
    getSignalQuality
  end

  # *** SMS Functions ****

  # Function for sending SMS
  def sendSMS(number, text)
    sendATComm('AT+CMGF=1', "OK\r\n") # text mode
    sleep(0.5)

    compose = 'AT+CMGS="'
    compose += str(number)
    compose += '"'

    sendATComm(compose, '>')
    sleep(1)
    clear_compose
    sleep(1)
    sendATCommOnce(text)
    sendATComm(self.CTRL_Z, 'OK', 8) # with 8 seconds timeout
  end

  # *** GNSS Functions ***

  # Function for turning on GNSS
  def turnOnGNSS
    sendATComm('AT+QGPS=1', "OK\r\n")
  end

  # Function for turning of GNSS
  def turnOffGNSS
    sendATComm('AT+QGPSEND', "OK\r\n")
  end

  # Function for getting fixed location
  def getFixedLocation
    sendATComm('AT+QGPSLOC?', '+QGPSLOC:')
  end

  # *** TCP & UDP Protocols Functions ***

  # Function for configurating and activating TCP context
  def activateContext
    sendATComm('AT+QICSGP=1', "OK\r\n")
    sleep(1)
    sendATComm('AT+QIACT=1', "\r\n")
  end

  # Function for deactivating TCP context
  def deactivateContext
    sendATComm('AT+QIDEACT=1', "\r\n")
  end

  # # Function for connecting to server via TCP
  # # just buffer access mode is supported for now.
  # def connectToServerTCP
  #   compose = "AT+QIOPEN=1,1"
  #   compose += ",\"TCP\",\""
  #   compose += str(self.ip_address)
  #   compose += "\","
  #   compose += str(self.port_number)
  #   compose += ",0,0"
  #   self.sendATComm(compose,"OK\r\n")
  #   self.clear_compose
  #   self.sendATComm("AT+QISTATE=0,1","OK\r\n")
  # end

  # # Fuction for sending data via tcp.
  # # just buffer access mode is supported for now.
  # def sendDataTCP(data)
  #   compose = "AT+QISEND=1,"
  #   compose += str(len(data))
  #   self.sendATComm(compose,">")
  #   self.sendATComm(data,"SEND OK")
  #   self.clear_compose
  # end

  # # Function for connecting to server via UDP
  # def startUDPService
  #   port = "3005"
  #   compose = "AT+QIOPEN=1,1,\"UDP SERVICE\",\""
  #   compose += str(self.ip_address)
  #   compose += "\",0,"
  #   compose += str(port)
  #   compose += ",0"
  #   self.sendATComm(compose,"OK\r\n")
  #   self.clear_compose
  #   self.sendATComm("AT+QISTATE=0,1","\r\n")
  # end

  # # Fuction for sending data via udp.
  # def sendDataUDP(data)
  #   compose = "AT+QISEND=1,"
  #   compose += str(len(data))
  #   compose += ",\""
  #   compose += str(self.ip_address)
  #   compose += "\","
  #   compose += str(self.port_number)
  #   self.sendATComm(compose,">")
  #   self.clear_compose
  #   self.sendATComm(data,"SEND OK")
  # end

  # Function for closing server connection
  def closeConnection
    sendATComm('AT+QICLOSE=1', "\r\n")
  end

  # *** Shield Peripheral Functions ***

  # Function for reading user button
  def readUserButton
    RPi::GPIO.input(self.USER_BUTTON)
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

